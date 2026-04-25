import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:shoqlist/constants/firestore_keys.dart';
import 'package:shoqlist/viewmodels/firebase_auth_view_model.dart';
import 'package:shoqlist/viewmodels/firebase_view_model.dart';
import 'package:shoqlist/viewmodels/shopping_lists_view_model.dart';

/// Realtime sync via Firestore `.snapshots()`.
///
/// Bez serwer-pushy — Firestore utrzymuje własny persistent channel, SDK
/// dostarcza push'e do każdego zarejestrowanego listenera.
///
/// Dwa tryby:
///  - `startHome` → home screen: listener na własnej kolekcji `lists` +
///    listener na `sharedLists` pointery + per-pointer listener na cudzym
///    doku (żeby móc łączyć zmiany z cudzej listy z lokalnym stanem).
///  - `startDetail(ownerId, listId)` → detail screen: pojedynczy doc.
///    Home listener już pokrywa ten doc, ale osobny detail sub upraszcza
///    lifecycle (start/stop tied to screen initState/dispose).
class ListSyncService {
  ListSyncService(this._firebaseVM, this._auth, this._shoppingListsVM);

  final FirebaseViewModel _firebaseVM;
  final FirebaseAuthViewModel _auth;
  final ShoppingListsViewModel _shoppingListsVM;

  final CollectionReference _users =
      FirebaseFirestore.instance.collection(FirestoreCollections.users);

  // Home
  StreamSubscription? _ownListsSub;
  StreamSubscription? _sharedPointersSub;
  final Map<String, StreamSubscription> _sharedListSubs = {}; // key = docId
  final Map<String, String> _sharedListOwners = {}; // docId → ownerId

  // Detail
  StreamSubscription? _detailSub;
  String? _detailKey; // "$ownerId:$listId"

  bool _homeActive = false;

  Future<void> startHome() async {
    if (_homeActive) return;
    final uid = _auth.auth.currentUser?.uid;
    if (uid == null) return;
    _homeActive = true;

    _ownListsSub = _users
        .doc(uid)
        .collection(FirestoreCollections.lists)
        .snapshots()
        .listen(_onOwnCollectionSnapshot, onError: _onListenerError);

    _sharedPointersSub = _users
        .doc(uid)
        .collection(FirestoreCollections.sharedLists)
        .snapshots()
        .listen(_onSharedPointersSnapshot, onError: _onListenerError);
  }

  Future<void> stopHome() async {
    _homeActive = false;
    await _ownListsSub?.cancel();
    _ownListsSub = null;
    await _sharedPointersSub?.cancel();
    _sharedPointersSub = null;
    for (final sub in _sharedListSubs.values) {
      await sub.cancel();
    }
    _sharedListSubs.clear();
    _sharedListOwners.clear();
  }

  Future<void> startDetail(String ownerId, String listId) async {
    final key = '$ownerId:$listId';
    if (_detailKey == key) return;
    await stopDetail();
    _detailKey = key;
    _detailSub = _users
        .doc(ownerId)
        .collection(FirestoreCollections.lists)
        .doc(listId)
        .snapshots()
        .listen(_onDetailDocSnapshot, onError: _onListenerError);
  }

  Future<void> stopDetail() async {
    await _detailSub?.cancel();
    _detailSub = null;
    _detailKey = null;
  }

  // -- Snapshot handlers ------------------------------------------------------

  void _onOwnCollectionSnapshot(QuerySnapshot snap) {
    for (final change in snap.docChanges) {
      switch (change.type) {
        case DocumentChangeType.added:
        case DocumentChangeType.modified:
          // applyDocToLocal jest async — fire-and-forget, merge idempotentny.
          _firebaseVM.applyDocToLocal(change.doc).catchError((e, st) {
            FirebaseCrashlytics.instance.recordError(e, st);
          });
          break;
        case DocumentChangeType.removed:
          // Własny list usunięty (np. przez drugi device tego samego ownera).
          _shoppingListsVM.removeSharedListLocally(change.doc.id);
          break;
      }
    }
  }

  Future<void> _onSharedPointersSnapshot(QuerySnapshot snap) async {
    for (final change in snap.docChanges) {
      final docId = change.doc.id;
      switch (change.type) {
        case DocumentChangeType.added:
        case DocumentChangeType.modified:
          final ownerId =
              (change.doc.get(FirestoreFields.ownerId) as String?) ?? '';
          if (ownerId.isEmpty) continue;
          await _subscribeToSharedList(ownerId, docId);
          break;
        case DocumentChangeType.removed:
          await _unsubscribeSharedList(docId);
          // Pointer zniknął = owner unshared mi listę → zdejmij lokalnie.
          _shoppingListsVM.removeSharedListLocally(docId);
          break;
      }
    }
  }

  Future<void> _subscribeToSharedList(String ownerId, String docId) async {
    // Idempotent — jeśli już subskrybujemy i owner się nie zmienił, no-op.
    if (_sharedListSubs.containsKey(docId) &&
        _sharedListOwners[docId] == ownerId) {
      return;
    }
    await _unsubscribeSharedList(docId);
    _sharedListOwners[docId] = ownerId;
    _sharedListSubs[docId] = _users
        .doc(ownerId)
        .collection(FirestoreCollections.lists)
        .doc(docId)
        .snapshots()
        .listen((snap) {
      if (!snap.exists) return;
      _firebaseVM.applyDocToLocal(snap).catchError((e, st) {
        FirebaseCrashlytics.instance.recordError(e, st);
      });
    }, onError: _onListenerError);
  }

  Future<void> _unsubscribeSharedList(String docId) async {
    final sub = _sharedListSubs.remove(docId);
    _sharedListOwners.remove(docId);
    await sub?.cancel();
  }

  void _onDetailDocSnapshot(DocumentSnapshot snap) {
    if (!snap.exists) return;
    _firebaseVM.applyDocToLocal(snap).catchError((e, st) {
      FirebaseCrashlytics.instance.recordError(e, st);
    });
  }

  void _onListenerError(Object error, StackTrace stackTrace) {
    FirebaseCrashlytics.instance.recordError(
        'Firestore snapshot listener error: $error', stackTrace);
  }

  /// Total reset — wywołaj przed sign-out (razem z PendingWritesTracker.reset).
  Future<void> shutdown() async {
    await stopDetail();
    await stopHome();
  }
}
