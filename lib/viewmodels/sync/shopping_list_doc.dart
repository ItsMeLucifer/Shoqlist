import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shoqlist/constants/firestore_keys.dart';
import 'package:shoqlist/models/shopping_list.dart';
import 'package:shoqlist/models/shopping_list_item.dart';
import 'package:shoqlist/models/user.dart';
import 'package:shoqlist/viewmodels/tools.dart';

/// Intermediate between raw Firestore data and the Hive `ShoppingList`.
/// Wrapper around a parsed list, dispatching v1 (legacy arrays) vs v2
/// (id-keyed map + per-field timestamps).
///
/// Shared user lacks write perms to owner's doc → nie może migrować; parser
/// MUSI umieć czytać oba formaty read-only bez side-effectów.
class ShoppingListDoc {
  ShoppingListDoc({
    required this.documentId,
    required this.ownerId,
    required this.name,
    required this.importance,
    required this.items,
    required this.usersWithAccessIds,
    required this.nameUpdatedAt,
    required this.importanceUpdatedAt,
    required this.usersWithAccessUpdatedAt,
    required this.createdAt,
    required this.updatedAt,
    required this.schemaVersion,
  });

  final String documentId;
  final String ownerId;
  final String name;
  final Importance importance;
  final List<ShoppingListItem> items; // z tombstone'ami (deletedAt != null)
  final List<String> usersWithAccessIds; // active entries only
  final int nameUpdatedAt;
  final int importanceUpdatedAt;
  final int usersWithAccessUpdatedAt;
  final int createdAt;
  final int updatedAt;
  final int schemaVersion;

  bool get isV1 => schemaVersion < FirestoreFields.currentSchemaVersion;

  /// Materialize into a Hive-backed `ShoppingList`. Filters out tombstoned
  /// items — local model doesn't need them; tombstones are a Firestore
  /// concept for ordering remote deletions correctly under realtime.
  ShoppingList toShoppingList(String ownerName, List<User> usersWithAccess) {
    final liveItems = items.where((i) => i.deletedAt == null).toList();
    return ShoppingList(
      name,
      liveItems,
      importance,
      documentId,
      ownerId,
      ownerName,
      usersWithAccess,
      nameUpdatedAt,
      importanceUpdatedAt,
      usersWithAccessUpdatedAt,
      createdAt,
      updatedAt,
      schemaVersion,
    );
  }

  static ShoppingListDoc fromSnapshot(
      DocumentSnapshot snap, Tools importanceResolver) {
    final data = snap.data() as Map<String, dynamic>? ?? const {};
    final schemaVersion = (data[FirestoreFields.schemaVersion] as int?) ?? 1;
    final itemsField = data[FirestoreFields.items];
    final isV2 = schemaVersion >= FirestoreFields.currentSchemaVersion &&
        itemsField is Map;

    if (isV2) {
      return _parseV2(snap, data, itemsField, importanceResolver);
    }
    return _parseV1Compat(snap, data, importanceResolver);
  }

  static ShoppingListDoc _parseV2(
    DocumentSnapshot snap,
    Map<String, dynamic> data,
    Map itemsMap,
    Tools importanceResolver,
  ) {
    final items = <ShoppingListItem>[];
    itemsMap.forEach((rawId, rawValue) {
      if (rawValue is! Map) return;
      final m = Map<String, dynamic>.from(rawValue);
      final id = (m[FirestoreFields.id] as String?) ?? rawId as String;
      final name = (m[FirestoreFields.name] as String?) ?? '';
      final state = (m[FirestoreFields.itemState] as bool?) ?? false;
      final favorite = (m[FirestoreFields.itemFavorite] as bool?) ?? false;
      final createdAt = _asInt(m[FirestoreFields.createdAt]);
      items.add(
        ShoppingListItem(
          name,
          state,
          favorite,
          id: id,
          createdAt: createdAt,
          nameUpdatedAt:
              _asInt(m[FirestoreFields.nameUpdatedAt]) ?? createdAt ?? 0,
          stateUpdatedAt:
              _asInt(m[FirestoreFields.itemStateUpdatedAt]) ?? createdAt ?? 0,
          favoriteUpdatedAt:
              _asInt(m[FirestoreFields.itemFavoriteUpdatedAt]) ??
                  createdAt ??
                  0,
          deletedAt: _asInt(m[FirestoreFields.deletedAt]),
        ),
      );
    });

    final accessField = data[FirestoreFields.usersWithAccess];
    final accessIds = <String>[];
    if (accessField is Map) {
      accessField.forEach((rawUid, rawValue) {
        if (rawValue is! Map) return;
        final entry = Map<String, dynamic>.from(rawValue);
        final revokedAt = _asInt(entry[FirestoreFields.revokedAt]);
        final grantedAt = _asInt(entry[FirestoreFields.grantedAt]);
        // Active access = grantedAt present and either no revokedAt or
        // grantedAt is newer than revokedAt (user was re-granted).
        if (grantedAt == null) return;
        if (revokedAt != null && revokedAt >= grantedAt) return;
        accessIds.add(rawUid as String);
      });
    } else if (accessField is List) {
      // Defensive: v2 doc that still has array-shaped access (shouldn't happen
      // post-migration but don't crash).
      accessIds.addAll(accessField.cast<String>());
    }

    return ShoppingListDoc(
      documentId: snap.id,
      ownerId: (data[FirestoreFields.ownerId] as String?) ?? '',
      name: (data[FirestoreFields.name] as String?) ?? '',
      importance: importanceResolver.getImportanceValueFromLabel(
          (data[FirestoreFields.importance] as String?) ?? 'Normal'),
      items: items,
      usersWithAccessIds: accessIds,
      nameUpdatedAt: _asInt(data[FirestoreFields.nameUpdatedAt]) ?? 0,
      importanceUpdatedAt:
          _asInt(data[FirestoreFields.importanceUpdatedAt]) ?? 0,
      usersWithAccessUpdatedAt:
          _asInt(data[FirestoreFields.usersWithAccessUpdatedAt]) ?? 0,
      createdAt: _asInt(data[FirestoreFields.createdAt]) ?? 0,
      updatedAt: _asInt(data[FirestoreFields.updatedAt]) ?? 0,
      schemaVersion: FirestoreFields.currentSchemaVersion,
    );
  }

  /// Read v1 arrays into synthesized items with timestamp = 0 ("older than
  /// anything"). Local optimistic state always wins over v1 parse; once owner
  /// migrates, all timestamps populate correctly.
  static ShoppingListDoc _parseV1Compat(
    DocumentSnapshot snap,
    Map<String, dynamic> data,
    Tools importanceResolver,
  ) {
    final listContent =
        (data[FirestoreFields.listContent] as List?)?.cast<dynamic>() ??
            const [];
    final listState =
        (data[FirestoreFields.listState] as List?)?.cast<dynamic>() ??
            const [];
    final listFavorite =
        (data[FirestoreFields.listFavorite] as List?)?.cast<dynamic>() ??
            const [];
    final items = <ShoppingListItem>[];
    for (var j = 0; j < listContent.length; j++) {
      items.add(
        ShoppingListItem(
          (listContent[j] as String?) ?? '',
          j < listState.length ? (listState[j] as bool? ?? false) : false,
          j < listFavorite.length
              ? (listFavorite[j] as bool? ?? false)
              : false,
          // Deterministyczne ID dla v1 items — parser i migrator MUSZĄ
          // generować identyczne ID dla tego samego array slot'u, inaczej
          // pierwsza mutacja po migracji tworzy duplikat (lokal ma `nanoid-A`,
          // serwer po migracji ma `nanoid-B`, dot-path `items.nanoid-A.state`
          // creates new entry → 2 itemy zamiast 1).
          id: legacyV1Id(j),
          createdAt: 0,
          nameUpdatedAt: 0,
          stateUpdatedAt: 0,
          favoriteUpdatedAt: 0,
        ),
      );
    }
    final accessField = data[FirestoreFields.usersWithAccess];
    final accessIds = <String>[];
    if (accessField is List) {
      accessIds.addAll(accessField.cast<String>());
    } else if (accessField is Map) {
      accessField.forEach((k, v) => accessIds.add(k as String));
    }
    return ShoppingListDoc(
      documentId: snap.id,
      ownerId: (data[FirestoreFields.ownerId] as String?) ?? '',
      name: (data[FirestoreFields.name] as String?) ?? '',
      importance: importanceResolver.getImportanceValueFromLabel(
          (data[FirestoreFields.importance] as String?) ?? 'Normal'),
      items: items,
      usersWithAccessIds: accessIds,
      nameUpdatedAt: 0,
      importanceUpdatedAt: 0,
      usersWithAccessUpdatedAt: 0,
      createdAt: 0,
      updatedAt: 0,
      schemaVersion: 1,
    );
  }

  /// Deterministic ID dla itemu z v1 array (index-based). Używane przez
  /// PARSER i MIGRATOR żeby produkować spójne ID. Format unikalny w obrębie
  /// jednej listy — kolizja z `nanoid()` praktycznie niemożliwa.
  static String legacyV1Id(int index) => 'v1-$index';

  static int? _asInt(Object? v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v);
    return null;
  }

  /// Serializuj item do Firestore map (używany przy createItem przez ListWriter).
  static Map<String, dynamic> itemToFirestoreMap(ShoppingListItem item) => {
        FirestoreFields.id: item.id,
        FirestoreFields.name: item.itemName,
        FirestoreFields.itemState: item.gotItem,
        FirestoreFields.itemFavorite: item.isFavorite,
        FirestoreFields.createdAt:
            item.createdAt ?? DateTime.now().millisecondsSinceEpoch,
        FirestoreFields.nameUpdatedAt:
            item.nameUpdatedAt ?? item.createdAt ?? 0,
        FirestoreFields.itemStateUpdatedAt:
            item.stateUpdatedAt ?? item.createdAt ?? 0,
        FirestoreFields.itemFavoriteUpdatedAt:
            item.favoriteUpdatedAt ?? item.createdAt ?? 0,
        FirestoreFields.deletedAt: item.deletedAt,
      };
}
