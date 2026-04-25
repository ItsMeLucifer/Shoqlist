import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shoqlist/constants/firestore_keys.dart';

/// Encapsulates v2 writes using per-field nested paths
/// (`items.<itemId>.state`) so two devices mutating different items or
/// different fields of the same item don't conflict at Firestore level.
///
/// Shadow-write mode: aktualizuje dodatkowo `listContent`/`listState`/
/// `listFavorite` v1 arrays w TEJ samej transakcji, żeby stare wersje apki
/// shared userów jeszcze działały. Cena: każda mutacja rebuild'uje arrays
/// z aktualnej mapy `items`. Włącz gdy udostępniasz komuś na starej wersji
/// apki; wyłącz po upgradzie wszystkich klientów.
class ListWriter {
  ListWriter({this.shadowWriteV1Mirrors = true});

  final bool shadowWriteV1Mirrors;

  int _nowMs() => DateTime.now().millisecondsSinceEpoch;

  /// Ustaw pole `name` item'a.
  Future<void> setItemName({
    required DocumentReference<Map<String, dynamic>> ref,
    required String itemId,
    required String newName,
  }) async {
    await FirebaseFirestore.instance.runTransaction((txn) async {
      final snap = await txn.get(ref);
      if (!snap.exists) throw StateError('List document does not exist');
      final data = snap.data()!;
      _ensureV2OrThrow(data);
      final nowMs = _nowMs();

      final updates = <String, dynamic>{
        '${FirestoreFields.items}.$itemId.${FirestoreFields.name}': newName,
        '${FirestoreFields.items}.$itemId.${FirestoreFields.nameUpdatedAt}':
            nowMs,
        FirestoreFields.updatedAt: nowMs,
      };
      if (shadowWriteV1Mirrors) {
        _attachV1Mirrors(updates, data,
            mutate: (itemsMap) => itemsMap[itemId]?[FirestoreFields.name] =
                newName);
      }
      txn.update(ref, updates);
    });
  }

  /// Toggle `state` (gotItem).
  Future<void> setItemState({
    required DocumentReference<Map<String, dynamic>> ref,
    required String itemId,
    required bool newState,
  }) async {
    await FirebaseFirestore.instance.runTransaction((txn) async {
      final snap = await txn.get(ref);
      if (!snap.exists) throw StateError('List document does not exist');
      final data = snap.data()!;
      _ensureV2OrThrow(data);
      final nowMs = _nowMs();

      final updates = <String, dynamic>{
        '${FirestoreFields.items}.$itemId.${FirestoreFields.itemState}':
            newState,
        '${FirestoreFields.items}.$itemId.${FirestoreFields.itemStateUpdatedAt}':
            nowMs,
        FirestoreFields.updatedAt: nowMs,
      };
      if (shadowWriteV1Mirrors) {
        _attachV1Mirrors(updates, data,
            mutate: (itemsMap) =>
                itemsMap[itemId]?[FirestoreFields.itemState] = newState);
      }
      txn.update(ref, updates);
    });
  }

  /// Toggle `favorite`.
  Future<void> setItemFavorite({
    required DocumentReference<Map<String, dynamic>> ref,
    required String itemId,
    required bool newFavorite,
  }) async {
    await FirebaseFirestore.instance.runTransaction((txn) async {
      final snap = await txn.get(ref);
      if (!snap.exists) throw StateError('List document does not exist');
      final data = snap.data()!;
      _ensureV2OrThrow(data);
      final nowMs = _nowMs();

      final updates = <String, dynamic>{
        '${FirestoreFields.items}.$itemId.${FirestoreFields.itemFavorite}':
            newFavorite,
        '${FirestoreFields.items}.$itemId.${FirestoreFields.itemFavoriteUpdatedAt}':
            nowMs,
        FirestoreFields.updatedAt: nowMs,
      };
      if (shadowWriteV1Mirrors) {
        _attachV1Mirrors(updates, data,
            mutate: (itemsMap) =>
                itemsMap[itemId]?[FirestoreFields.itemFavorite] = newFavorite);
      }
      txn.update(ref, updates);
    });
  }

  /// Add nowy item (map entry). `item` zawiera wszystkie pola + timestampy.
  Future<void> createItem({
    required DocumentReference<Map<String, dynamic>> ref,
    required String itemId,
    required Map<String, dynamic> itemFields,
  }) async {
    await FirebaseFirestore.instance.runTransaction((txn) async {
      final snap = await txn.get(ref);
      if (!snap.exists) throw StateError('List document does not exist');
      final data = snap.data()!;
      _ensureV2OrThrow(data);
      final nowMs = _nowMs();

      final updates = <String, dynamic>{
        '${FirestoreFields.items}.$itemId': itemFields,
        FirestoreFields.updatedAt: nowMs,
      };
      if (shadowWriteV1Mirrors) {
        _attachV1Mirrors(updates, data, mutate: (itemsMap) {
          itemsMap[itemId] = Map<String, dynamic>.from(itemFields);
        });
      }
      txn.update(ref, updates);
    });
  }

  /// Soft-delete = ustaw `deletedAt`. Item zostaje w dokumencie jako tombstone
  /// — późny snapshot nie reanimuje go. GC dzieje się przy okazji innych
  /// zapisów (tombstone starszy niż 30 dni dropowany).
  Future<void> softDeleteItem({
    required DocumentReference<Map<String, dynamic>> ref,
    required String itemId,
  }) async {
    await FirebaseFirestore.instance.runTransaction((txn) async {
      final snap = await txn.get(ref);
      if (!snap.exists) throw StateError('List document does not exist');
      final data = snap.data()!;
      _ensureV2OrThrow(data);
      final nowMs = _nowMs();

      final updates = <String, dynamic>{
        '${FirestoreFields.items}.$itemId.${FirestoreFields.deletedAt}': nowMs,
        FirestoreFields.updatedAt: nowMs,
      };
      if (shadowWriteV1Mirrors) {
        _attachV1Mirrors(updates, data,
            mutate: (itemsMap) => itemsMap.remove(itemId));
      }
      txn.update(ref, updates);
    });
  }

  /// List-level name / importance updates.
  Future<void> setListName({
    required DocumentReference<Map<String, dynamic>> ref,
    required String newName,
  }) async {
    final nowMs = _nowMs();
    await ref.update({
      FirestoreFields.name: newName,
      FirestoreFields.nameUpdatedAt: nowMs,
      FirestoreFields.updatedAt: nowMs,
    });
  }

  Future<void> setListImportance({
    required DocumentReference<Map<String, dynamic>> ref,
    required String newImportanceLabel,
  }) async {
    final nowMs = _nowMs();
    await ref.update({
      FirestoreFields.importance: newImportanceLabel,
      FirestoreFields.importanceUpdatedAt: nowMs,
      FirestoreFields.updatedAt: nowMs,
    });
  }

  /// Grant or revoke access per-uid. Oba są per-pole na `usersWithAccess.<uid>`.
  Future<void> grantAccess({
    required DocumentReference<Map<String, dynamic>> ref,
    required String uid,
  }) async {
    final nowMs = _nowMs();
    await ref.update({
      '${FirestoreFields.usersWithAccess}.$uid': {
        FirestoreFields.grantedAt: nowMs,
      },
      FirestoreFields.usersWithAccessUpdatedAt: nowMs,
      FirestoreFields.updatedAt: nowMs,
    });
  }

  Future<void> revokeAccess({
    required DocumentReference<Map<String, dynamic>> ref,
    required String uid,
  }) async {
    final nowMs = _nowMs();
    // Tombstone entry — zostaje w mapie, żeby spóźniony snapshot nie
    // reanimował grantu. GC czyści po 30 dniach.
    await ref.update({
      '${FirestoreFields.usersWithAccess}.$uid': {
        FirestoreFields.revokedAt: nowMs,
      },
      FirestoreFields.usersWithAccessUpdatedAt: nowMs,
      FirestoreFields.updatedAt: nowMs,
    });
  }

  // -- Helpers ----------------------------------------------------------------

  void _ensureV2OrThrow(Map<String, dynamic> data) {
    if (data[FirestoreFields.items] is! Map) {
      throw StateError(
          'List document not yet migrated to v2 — call FirestoreMigrator.migrateIfNeeded first');
    }
  }

  /// Buduje v1 arrays z aktualnego `items` + symulowana mutacja (callback),
  /// w taki sposób żeby stare wersje apki widziały aktualny stan.
  void _attachV1Mirrors(
    Map<String, dynamic> updates,
    Map<String, dynamic> currentData, {
    required void Function(Map<String, Map<String, dynamic>> itemsMap) mutate,
  }) {
    final rawItems = currentData[FirestoreFields.items] as Map? ?? const {};
    final itemsMap = <String, Map<String, dynamic>>{};
    rawItems.forEach((k, v) {
      if (v is Map) itemsMap[k as String] = Map<String, dynamic>.from(v);
    });
    mutate(itemsMap);

    // Sortujemy po createdAt żeby kolejność w arrays była deterministyczna
    // (v1 klienci polegali na pozycji w array jako "index itemu").
    final sorted = itemsMap.entries
        .where((e) => e.value[FirestoreFields.deletedAt] == null)
        .toList()
      ..sort((a, b) {
        final ac = (a.value[FirestoreFields.createdAt] as int?) ?? 0;
        final bc = (b.value[FirestoreFields.createdAt] as int?) ?? 0;
        return ac.compareTo(bc);
      });

    updates[FirestoreFields.listContent] =
        sorted.map((e) => e.value[FirestoreFields.name] ?? '').toList();
    updates[FirestoreFields.listState] = sorted
        .map((e) => e.value[FirestoreFields.itemState] as bool? ?? false)
        .toList();
    updates[FirestoreFields.listFavorite] = sorted
        .map((e) => e.value[FirestoreFields.itemFavorite] as bool? ?? false)
        .toList();
  }
}
