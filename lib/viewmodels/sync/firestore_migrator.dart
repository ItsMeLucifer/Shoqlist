import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:shoqlist/constants/firestore_keys.dart';
import 'package:shoqlist/viewmodels/sync/shopping_list_doc.dart';

/// Lazy, idempotent, transactional migration v1 → v2.
///
/// - Uruchamiany per-list, przez ownera, przed jakimkolwiek zapisem.
/// - Transakcja w read phase sprawdza `schemaVersion == 2 || items is Map` →
///   no-op jeśli już zmigrowane. Dzięki temu dwa urządzenia tego samego usera
///   nie konfliktują.
/// - Shared user NIE wywołuje migracji (brak uprawnień do write cudzego doca).
///   Parser (shopping_list_doc.dart) czyta v1 kompatybilnie bez side-effectów.
class FirestoreMigrator {
  FirestoreMigrator({this.shadowWriteV1Mirrors = true});

  /// Przez jedno okno release'owe utrzymujemy v1 arrays jako mirror, żeby
  /// stare wersje apki udostępnionych userów nie wybuchły przy `doc.get('listContent')`.
  /// Kolejny release flipnie na false i dropnie stare pola.
  final bool shadowWriteV1Mirrors;

  Future<void> migrateIfNeeded(DocumentReference<Map<String, dynamic>> ref) async {
    try {
      await FirebaseFirestore.instance.runTransaction((txn) async {
        final snap = await txn.get(ref);
        if (!snap.exists) return;
        final data = snap.data();
        if (data == null) return;
        final alreadyV2 =
            (data[FirestoreFields.schemaVersion] as int?) ==
                    FirestoreFields.currentSchemaVersion ||
                data[FirestoreFields.items] is Map;
        if (alreadyV2) return;

        final nowMs = DateTime.now().millisecondsSinceEpoch;
        final listContent =
            (data[FirestoreFields.listContent] as List?) ?? const [];
        final listState =
            (data[FirestoreFields.listState] as List?) ?? const [];
        final listFavorite =
            (data[FirestoreFields.listFavorite] as List?) ?? const [];

        final itemsMap = <String, dynamic>{};
        for (var i = 0; i < listContent.length; i++) {
          // MUSI matchować `ShoppingListDoc.legacyV1Id(i)` używane przez parser
          // — inaczej lokalne ID (z parsera) ≠ ID na serwerze po migracji,
          // i pierwsza item-mutation tworzy duplikat na docelowym docu.
          final id = ShoppingListDoc.legacyV1Id(i);
          itemsMap[id] = {
            FirestoreFields.id: id,
            FirestoreFields.name: listContent[i] ?? '',
            FirestoreFields.nameUpdatedAt: nowMs,
            FirestoreFields.itemState:
                i < listState.length ? (listState[i] as bool? ?? false) : false,
            FirestoreFields.itemStateUpdatedAt: nowMs,
            FirestoreFields.itemFavorite: i < listFavorite.length
                ? (listFavorite[i] as bool? ?? false)
                : false,
            FirestoreFields.itemFavoriteUpdatedAt: nowMs,
            FirestoreFields.createdAt: nowMs,
            FirestoreFields.deletedAt: null,
          };
        }

        final accessRaw = data[FirestoreFields.usersWithAccess];
        final accessMap = <String, dynamic>{};
        if (accessRaw is List) {
          for (final uid in accessRaw) {
            if (uid is String) {
              accessMap[uid] = {FirestoreFields.grantedAt: nowMs};
            }
          }
        } else if (accessRaw is Map) {
          accessRaw.forEach((k, v) {
            accessMap[k as String] = v;
          });
        }

        final payload = <String, dynamic>{
          FirestoreFields.schemaVersion: FirestoreFields.currentSchemaVersion,
          FirestoreFields.items: itemsMap,
          FirestoreFields.usersWithAccess: accessMap,
          FirestoreFields.usersWithAccessUpdatedAt: nowMs,
          FirestoreFields.nameUpdatedAt: nowMs,
          FirestoreFields.importanceUpdatedAt: nowMs,
          FirestoreFields.createdAt: nowMs,
          FirestoreFields.updatedAt: nowMs,
        };
        if (!shadowWriteV1Mirrors) {
          payload[FirestoreFields.listContent] = FieldValue.delete();
          payload[FirestoreFields.listState] = FieldValue.delete();
          payload[FirestoreFields.listFavorite] = FieldValue.delete();
        }
        txn.update(ref, payload);
      });
    } catch (error, stackTrace) {
      // Migracja może odpaść jeśli user nie ma write perms (shared user).
      // W takim wypadku czytamy v1 compat'em i idziemy dalej.
      FirebaseCrashlytics.instance.recordError(
        'Firestore v2 migration skipped/failed for ${ref.path}: $error',
        stackTrace,
      );
    }
  }
}
