import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:hive_ce/hive.dart';
import 'package:shoqlist/constants/firestore_keys.dart';
import 'package:shoqlist/models/user.dart';
import 'package:shoqlist/models/loyalty_card.dart';
import 'package:shoqlist/models/shopping_list.dart';
import 'package:shoqlist/models/shopping_list_item.dart';
import 'package:shoqlist/viewmodels/firebase_auth_view_model.dart';
import 'package:shoqlist/viewmodels/friends_service_view_model.dart';
import 'package:shoqlist/viewmodels/loyalty_cards_view_model.dart';
import 'package:shoqlist/viewmodels/shopping_lists_view_model.dart';
import 'package:shoqlist/viewmodels/sync/firestore_migrator.dart';
import 'package:shoqlist/viewmodels/sync/list_writer.dart';
import 'package:shoqlist/viewmodels/sync/pending_writes_tracker.dart';
import 'package:shoqlist/viewmodels/sync/shopping_list_doc.dart';
import 'package:shoqlist/viewmodels/tools.dart';

class FirebaseViewModel extends ChangeNotifier {
  final ShoppingListsViewModel _shoppingListsVM;
  final LoyaltyCardsViewModel _loyaltyCardsVM;
  final Tools _toolsVM;
  final FirebaseAuthViewModel _firebaseAuth;
  final FriendsServiceViewModel _friendsServiceVM;
  final PendingWritesTracker _tracker;
  final ListWriter _writer;
  final FirestoreMigrator _migrator;
  FirebaseViewModel(
    this._shoppingListsVM,
    this._loyaltyCardsVM,
    this._toolsVM,
    this._firebaseAuth,
    this._friendsServiceVM,
    this._tracker,
    this._writer,
    this._migrator,
  );

  PendingWritesTracker get pendingWritesTracker => _tracker;

  CollectionReference users = FirebaseFirestore.instance.collection('users');

  // -- SHOPPING LISTS ---------------------------------------------------------
  //
  // Porzuciliśmy timestamp-based conflict resolution + buffer arrays z v1.
  // Nowy model: parser `ShoppingListDoc.fromSnapshot` czyta v1 lub v2, a
  // `ShoppingListsViewModel.applyMergedSnapshot` robi per-field merge (pod
  // tarczą `PendingWritesTracker`). Zapisy idą przez `ListWriter` (per-pole,
  // dot-notation) po obowiązkowym `migrator.migrateIfNeeded` dla ownera.

  bool _fetchingShoppingLists = false;

  /// Bootstrap fetch — używany przy starcie i przez connectivity/refresh.
  /// Czyta wszystkie własne listy + shared pointery, każdy przez parser
  /// i merge-apply. Streamingu (.snapshots) dorzuci Stage 3 w
  /// `ListSyncService`; tu ta metoda nadal zostaje żeby pull-to-refresh
  /// na home screen ściągnął aktualny stan synchronously.
  Future<void> getShoppingListsFromFirebase(
      bool shouldCompareCloudDataWithLocalOne) async {
    final uid = _firebaseAuth.auth.currentUser?.uid;
    if (uid == null) return;
    if (_fetchingShoppingLists) return;
    _fetchingShoppingLists = true;
    // Defensive: currentUserId steruje filterDisplayedShoppingLists(). Jeśli
    // nie został jeszcze ustawiony (np. brak hydrate-from-cache na starcie),
    // wszystkie listy trafiłyby do `shared` view.
    _shoppingListsVM.currentUserId = uid;
    try {
      // 1) Własne listy
      final ownSnap = await users.doc(uid).collection('lists').get();
      for (final doc in ownSnap.docs) {
        await applyDocToLocal(doc);
      }

      // 2) Shared pointery — dla każdego pobieramy cudzy doc
      final sharedPointersSnap =
          await users.doc(uid).collection('sharedLists').get();
      for (final pointer in sharedPointersSnap.docs) {
        final ownerId = (pointer.get(FirestoreFields.ownerId) as String?) ?? '';
        final documentId =
            (pointer.get(FirestoreFields.documentId) as String?) ?? pointer.id;
        if (ownerId.isEmpty) continue;
        try {
          final ownerDoc = await users
              .doc(ownerId)
              .collection('lists')
              .doc(documentId)
              .get();
          if (!ownerDoc.exists) continue;
          await applyDocToLocal(ownerDoc);
        } catch (error, stackTrace) {
          _toolsVM.printWarning("Failed to fetch shared list $documentId: $error");
          FirebaseCrashlytics.instance.recordError(error, stackTrace);
        }
      }

      if (_toolsVM.refreshStatus == RefreshStatus.duringRefresh) {
        _toolsVM.refreshStatus = RefreshStatus.refreshed;
      }
      _toolsVM.fetchStatus = FetchStatus.fetched;
    } catch (error, stackTrace) {
      _toolsVM.printWarning("Failed getShoppingListsFromFirebase: $error");
      FirebaseCrashlytics.instance.recordError(error, stackTrace);
    } finally {
      _fetchingShoppingLists = false;
    }
  }

  /// Pobiera jedną listę (detail refresh). Używane przez pull-to-refresh w
  /// ekranie listy. Flush + migrate + parse + merge.
  Future<void> fetchOneShoppingList(String documentId, String ownerId) async {
    await _tracker.flushList(documentId);
    final ref = _listDocRef(documentId, ownerId);

    // Migrate jeśli to moja lista (shared userzy nie mają write perms).
    final myUid = _firebaseAuth.auth.currentUser?.uid;
    if (myUid != null && myUid == ownerId) {
      await _migrator.migrateIfNeeded(ref);
    }

    try {
      final snap = await ref.get();
      if (!snap.exists) return;
      await applyDocToLocal(snap);
    } catch (error, stackTrace) {
      _toolsVM.printWarning("Failed to fetch list $documentId: $error");
      FirebaseCrashlytics.instance.recordError(error, stackTrace);
    }
  }

  /// Publiczny helper — parse snapshot + rehydrate user metadata + merge.
  /// Używany zarówno przez pull fetch'e jak i przez realtime listeners
  /// (`ListSyncService`). Idempotentny: wielokrotne wywołania z tym samym
  /// snapshotem są bez efektu (per-field timestampy monotonicznie rosną).
  Future<void> applyDocToLocal(DocumentSnapshot doc) async {
    final myUid = _firebaseAuth.auth.currentUser?.uid;
    final parsed = ShoppingListDoc.fromSnapshot(doc, _toolsVM);
    final ownerName = await _safeGetUserName(parsed.ownerId);
    // usersWithAccess full hydration tylko dla własnych list (potrzebne
    // w manage-access dialog). Dla cudzych shared list by default puste
    // — nie tłukniemy N getUserById per każdy snapshot.
    final fetchUsers = parsed.ownerId == myUid;
    final accessUsers = <User>[];
    if (fetchUsers) {
      for (final uid in parsed.usersWithAccessIds) {
        accessUsers.add(await getUserById(uid));
      }
    }
    _shoppingListsVM.applyMergedSnapshot(
      parsed,
      ownerName: ownerName,
      usersWithAccess: accessUsers,
      tracker: _tracker,
    );
  }

  // -- CREATE / UPDATE / DELETE list-level ------------------------------------

  Future<void> putShoppingListToFirebase(
      String name, Importance importance, String documentId) async {
    final uid = _firebaseAuth.auth.currentUser?.uid;
    if (uid == null) return;
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final payload = <String, dynamic>{
      FirestoreFields.schemaVersion: FirestoreFields.currentSchemaVersion,
      FirestoreFields.name: name,
      FirestoreFields.nameUpdatedAt: nowMs,
      FirestoreFields.importance: _toolsVM.getImportanceLabel(importance),
      FirestoreFields.importanceUpdatedAt: nowMs,
      FirestoreFields.id: documentId,
      FirestoreFields.ownerId: uid,
      FirestoreFields.items: <String, dynamic>{},
      FirestoreFields.usersWithAccess: <String, dynamic>{},
      FirestoreFields.usersWithAccessUpdatedAt: nowMs,
      FirestoreFields.createdAt: nowMs,
      FirestoreFields.updatedAt: nowMs,
      // Shadow mirrors dla starych wersji apki shared userów (plan: drop
      // po kolejnym release gdy wszyscy zaktualizują).
      if (_writer.shadowWriteV1Mirrors) ...{
        FirestoreFields.listContent: <String>[],
        FirestoreFields.listState: <bool>[],
        FirestoreFields.listFavorite: <bool>[],
      },
    };
    try {
      await users.doc(uid).collection('lists').doc(documentId).set(payload);
    } catch (error, stackTrace) {
      _toolsVM.printWarning("Failed to create list: $error");
      FirebaseCrashlytics.instance.recordError(error, stackTrace);
    }
  }

  Future<void> updateShoppingListToFirebase(
      String name, Importance importance, String documentId) async {
    final uid = _firebaseAuth.auth.currentUser?.uid;
    if (uid == null) return;
    final ref = _listDocRef(documentId, uid);
    await _migrator.migrateIfNeeded(ref);
    try {
      await _writer.setListName(ref: ref, newName: name);
      await _writer.setListImportance(
          ref: ref,
          newImportanceLabel: _toolsVM.getImportanceLabel(importance));
    } catch (error, stackTrace) {
      _toolsVM.printWarning("Failed to update list meta: $error");
      FirebaseCrashlytics.instance.recordError(error, stackTrace);
    }
  }

  Future<void> deleteShoppingListOnFirebase(String documentId) async {
    final uid = _firebaseAuth.auth.currentUser?.uid;
    if (uid == null) return;
    DocumentSnapshot document;
    try {
      document =
          await getDocumentSnapshotFromFirebaseWithId(documentId, 'lists');
    } catch (error, stackTrace) {
      _toolsVM.printWarning(
          "Could not fetch list before delete: $error");
      FirebaseCrashlytics.instance.recordError(error, stackTrace);
      return;
    }
    if (!document.exists) return;
    // Zbierz aktywne uids z usersWithAccess (może być mapą v2 albo listą v1).
    final accessRaw = document.data() is Map
        ? (document.data() as Map)[FirestoreFields.usersWithAccess]
        : null;
    final activeUids = <String>[];
    if (accessRaw is Map) {
      accessRaw.forEach((k, v) {
        if (v is Map) {
          final granted = v[FirestoreFields.grantedAt] as int?;
          final revoked = v[FirestoreFields.revokedAt] as int?;
          if (granted != null && (revoked == null || revoked < granted)) {
            activeUids.add(k as String);
          }
        }
      });
    } else if (accessRaw is List) {
      activeUids.addAll(accessRaw.cast<String>());
    }
    // Usuń pointery u wszystkich shared userów.
    for (final user in activeUids) {
      try {
        await users
            .doc(user)
            .collection('sharedLists')
            .doc(documentId)
            .delete();
      } catch (_) {
        // best-effort; kontynuuj z resztą
      }
    }
    try {
      await users.doc(uid).collection('lists').doc(documentId).delete();
    } catch (error, stackTrace) {
      _toolsVM.printWarning("Failed to delete list: $error");
      FirebaseCrashlytics.instance.recordError(error, stackTrace);
    }
  }

  Future<DocumentSnapshot> getDocumentSnapshotFromFirebaseWithId(
    String documentId,
    String collectionName, [
    String? ownerId,
  ]) async {
    final targetOwnerId = ownerId ?? _firebaseAuth.auth.currentUser?.uid;
    return await users
        .doc(targetOwnerId)
        .collection(collectionName)
        .doc(documentId)
        .get()
        .catchError((error, stackTrace) {
      _toolsVM.printWarning("Failed to get document snapshot: $error");
      FirebaseCrashlytics.instance.recordError(error, stackTrace);
      return error;
    });
  }

  DocumentReference<Map<String, dynamic>> _listDocRef(
      String documentId, String? ownerId) {
    final targetOwnerId = ownerId ?? _firebaseAuth.auth.currentUser?.uid;
    return users
        .doc(targetOwnerId)
        .collection('lists')
        .doc(documentId)
        .withConverter<Map<String, dynamic>>(
          fromFirestore: (snap, _) => snap.data() ?? <String, dynamic>{},
          toFirestore: (data, _) => data,
        );
  }

  // -- ITEM MUTATIONS (v2, id-keyed, wrapped w tracker) -----------------------

  Future<void> updateShoppingListItemNameOnFirebase({
    required String itemId,
    required String newName,
    required String documentId,
    String? ownerId,
  }) {
    final ref = _listDocRef(documentId, ownerId);
    return _tracker.track(
      listId: documentId,
      itemId: itemId,
      op: () async {
        try {
          await _migrator.migrateIfNeeded(ref);
          await _writer.setItemName(
              ref: ref, itemId: itemId, newName: newName);
        } catch (error, stackTrace) {
          _toolsVM.printWarning("Failed to update item name: $error");
          FirebaseCrashlytics.instance.recordError(error, stackTrace);
          rethrow;
        }
      },
    );
  }

  Future<void> addNewItemToShoppingListOnFirebase({
    required ShoppingListItem item,
    required String documentId,
    String? ownerId,
  }) {
    final ref = _listDocRef(documentId, ownerId);
    final itemId = item.id;
    return _tracker.track(
      listId: documentId,
      itemId: itemId,
      op: () async {
        if (itemId == null) throw StateError('Item missing id');
        try {
          await _migrator.migrateIfNeeded(ref);
          await _writer.createItem(
              ref: ref,
              itemId: itemId,
              itemFields: ShoppingListDoc.itemToFirestoreMap(item));
        } catch (error, stackTrace) {
          _toolsVM.printWarning("Failed to add new item: $error");
          FirebaseCrashlytics.instance.recordError(error, stackTrace);
          rethrow;
        }
      },
    );
  }

  Future<void> deleteShoppingListItemOnFirebase({
    required String itemId,
    required String documentId,
    String? ownerId,
  }) {
    final ref = _listDocRef(documentId, ownerId);
    return _tracker.track(
      listId: documentId,
      itemId: itemId,
      op: () async {
        try {
          await _migrator.migrateIfNeeded(ref);
          await _writer.softDeleteItem(ref: ref, itemId: itemId);
        } catch (error, stackTrace) {
          _toolsVM.printWarning("Failed to delete item: $error");
          FirebaseCrashlytics.instance.recordError(error, stackTrace);
          rethrow;
        }
      },
    );
  }

  Future<void> toggleStateOfShoppingListItemOnFirebase({
    required String itemId,
    required bool newState,
    required String documentId,
    String? ownerId,
  }) {
    final ref = _listDocRef(documentId, ownerId);
    return _tracker.track(
      listId: documentId,
      itemId: itemId,
      op: () async {
        try {
          await _migrator.migrateIfNeeded(ref);
          await _writer.setItemState(
              ref: ref, itemId: itemId, newState: newState);
        } catch (error, stackTrace) {
          _toolsVM.printWarning("Failed to toggle item's state: $error");
          FirebaseCrashlytics.instance.recordError(error, stackTrace);
          rethrow;
        }
      },
    );
  }

  Future<void> toggleFavoriteOfShoppingListItemOnFirebase({
    required String itemId,
    required bool newFavorite,
    required String documentId,
    String? ownerId,
  }) {
    final ref = _listDocRef(documentId, ownerId);
    return _tracker.track(
      listId: documentId,
      itemId: itemId,
      op: () async {
        try {
          await _migrator.migrateIfNeeded(ref);
          await _writer.setItemFavorite(
              ref: ref, itemId: itemId, newFavorite: newFavorite);
        } catch (error, stackTrace) {
          _toolsVM.printWarning("Failed to toggle item's favorite: $error");
          FirebaseCrashlytics.instance.recordError(error, stackTrace);
          rethrow;
        }
      },
    );
  }

  // -- USERS helpers (used by friends + access) -------------------------------

  Future<String> _safeGetUserName(String userId) async {
    try {
      final doc = await users.doc(userId).get();
      if (!doc.exists) return '';
      return (doc.get(FirestoreFields.nickname) as String?) ?? '';
    } catch (_) {
      return '';
    }
  }

  Future<String> getUserName(String userId) async {
    return await users
        .doc(userId)
        .get()
        .then((doc) => doc.get(FirestoreFields.nickname));
  }

  Future<User> getUserById(String userId) async {
    final doc = await users.doc(userId).get();
    if (!doc.exists) return User('', '', userId);
    return User(
      (doc.get(FirestoreFields.nickname) as String?) ?? '',
      (doc.get(FirestoreFields.email) as String?) ?? '',
      userId,
    );
  }

  // -- LOYALTY CARDS ----------------------------------------------------------
  final List<QueryDocumentSnapshot> _loyaltyCardsFetchedFromFirebase = [];
  Future<void> getLoyaltyCardsFromFirebase(bool shouldUpdateLocalData) async {
    final uid = _firebaseAuth.auth.currentUser?.uid;
    if (uid == null) return;
    _loyaltyCardsFetchedFromFirebase.clear();
    await users
        .doc(uid)
        .collection('loyaltyCards')
        .get()
        .then((QuerySnapshot querySnapshot) {
      if (querySnapshot.size > 0) {
        for (final doc in querySnapshot.docs) {
          _loyaltyCardsFetchedFromFirebase.add(doc);
        }
      }
    }).catchError((error, stackTrace) {
      _toolsVM.printWarning("Failed to fetch loyalty cards data: $error");
      FirebaseCrashlytics.instance.recordError(error, stackTrace);
      return error;
    });
    if (shouldUpdateLocalData) addFetchedLoyaltyCardsDataToLocalList();
  }

  void addFetchedLoyaltyCardsDataToLocalList() {
    List<LoyaltyCard> temp = [];
    for (int i = 0; i < _loyaltyCardsFetchedFromFirebase.length; i++) {
      temp.add(LoyaltyCard(
        _loyaltyCardsFetchedFromFirebase[i].get('name'),
        _loyaltyCardsFetchedFromFirebase[i].get('barCode'),
        _loyaltyCardsFetchedFromFirebase[i].get('isFavorite'),
        _loyaltyCardsFetchedFromFirebase[i].get('id'),
        Color(_loyaltyCardsFetchedFromFirebase[i].get('color')),
      ));
    }
    _loyaltyCardsVM.overrideLoyaltyCardsListLocally(temp);
  }

  Future<void> addNewLoyaltyCardToFirebase(
      String name, String barCode, String documentId, int colorValue) async {
    final uid = _firebaseAuth.auth.currentUser?.uid;
    if (uid == null) return;
    users
        .doc(uid)
        .collection('loyaltyCards')
        .doc(documentId)
        .set({
          'name': name,
          'barCode': barCode,
          'isFavorite': false,
          'id': documentId,
          'color': colorValue
        })
        .then((value) => debugPrint("Created new Loyalty card"))
        .catchError((error, stackTrace) {
          _toolsVM.printWarning("Failed to create Loyalty card: $error");
          FirebaseCrashlytics.instance.recordError(error, stackTrace);
        });
  }

  Future<void> updateLoyaltyCard(
      String name, String barCode, String documentId, int colorValue) async {
    final uid = _firebaseAuth.auth.currentUser?.uid;
    if (uid == null) return;
    users
        .doc(uid)
        .collection('loyaltyCards')
        .doc(documentId)
        .update({'name': name, 'barCode': barCode, 'color': colorValue})
        .then((value) => debugPrint("Updated Loyalty card"))
        .catchError((error, stackTrace) {
          _toolsVM.printWarning("Failed to update Loyalty card: $error");
          FirebaseCrashlytics.instance.recordError(error, stackTrace);
        });
  }

  Future<void> deleteLoyaltyCardOnFirebase(String documentId) async {
    final uid = _firebaseAuth.auth.currentUser?.uid;
    if (uid == null) return;
    await users
        .doc(uid)
        .collection('loyaltyCards')
        .doc(documentId)
        .delete()
        .then((value) => debugPrint("Loyalty card Deleted"))
        .catchError((error, stackTrace) {
      _toolsVM.printWarning("Failed to delete Loyalty card: $error");
      FirebaseCrashlytics.instance.recordError(error, stackTrace);
    });
  }

  Future<void> toggleFavoriteOfLoyaltyCardOnFirebase(String documentId) async {
    final uid = _firebaseAuth.auth.currentUser?.uid;
    if (uid == null) return;
    DocumentSnapshot document;
    try {
      document = await getDocumentSnapshotFromFirebaseWithId(
          documentId, 'loyaltyCards');
    } catch (error, stackTrace) {
      _toolsVM.printWarning(
          "Could not get loyalty card snapshot: $error");
      FirebaseCrashlytics.instance.recordError(error, stackTrace);
      return;
    }
    bool isFavorite = document.get('isFavorite');
    isFavorite = !isFavorite;
    await users
        .doc(uid)
        .collection('loyaltyCards')
        .doc(documentId)
        .update({'isFavorite': isFavorite})
        .then((value) => debugPrint("Changed favorite of loyalty card"))
        .catchError((error, stackTrace) {
          _toolsVM.printWarning("Failed to toggle loyalty card favorite: $error");
          FirebaseCrashlytics.instance.recordError(error, stackTrace);
        });
  }

  // -- FRIENDS ----------------------------------------------------------------

  Future<void> searchForUser(String input) async {
    final uid = _firebaseAuth.auth.currentUser?.uid;
    if (uid == null) return;
    _toolsVM.friendsFetchStatus = FetchStatus.duringFetching;
    List<User> usersGet = [];
    input = _toolsVM.deleteAllWhitespacesFromString(input);
    await users.where("email", isEqualTo: input).get().then((querySnapshot) {
      for (var document in querySnapshot.docs) {
        if (document.get('userId') != uid &&
            !_friendsServiceVM.friendsList.any((element) {
              return element.email == input;
            }) &&
            !_friendsServiceVM.friendRequestsList
                .any((element) => element.email == input)) {
          User user = User(document.get('nickname'), document.get('email'),
              document.get('userId'));
          usersGet.add(user);
        }
      }
    });
    _toolsVM.friendsFetchStatus = FetchStatus.fetched;
    _friendsServiceVM.putUsersList(usersGet);
  }

  Future<void> fetchFriendsList() async {
    List<QueryDocumentSnapshot> friendsFetchedFromFirebase = [];
    final uid = _firebaseAuth.auth.currentUser?.uid;
    if (uid == null) return;
    await users.doc(uid).collection('friends').get().then(
        (QuerySnapshot querySnapshot) {
      for (var doc in querySnapshot.docs) {
        friendsFetchedFromFirebase.add(doc);
      }
    }).catchError((error, stackTrace) {
      _toolsVM.printWarning("Failed to fetch friends: $error");
      FirebaseCrashlytics.instance.recordError(error, stackTrace);
    });
    addFetchedFriendsDataToLocalList(friendsFetchedFromFirebase);
  }

  Future<void> addFetchedFriendsDataToLocalList(
      List<QueryDocumentSnapshot> friendsFetchedFromFirebase) async {
    List<User> newList = [];
    for (int i = 0; i < friendsFetchedFromFirebase.length; i++) {
      DocumentSnapshot doc =
          await users.doc(friendsFetchedFromFirebase[i].get('userId')).get();
      newList.add(User(
          doc.get('nickname') ?? 'No nickname',
          friendsFetchedFromFirebase[i].get('email'),
          friendsFetchedFromFirebase[i].get('userId')));
    }
    _friendsServiceVM.putFriendsList(newList);
  }

  Future<void> fetchFriendRequestsList() async {
    List<QueryDocumentSnapshot> friendRequestsFetchedFromFirebase = [];
    final uid = _firebaseAuth.auth.currentUser?.uid;
    if (uid == null) return;
    await users.doc(uid).collection('friendRequests').get().then(
        (QuerySnapshot querySnapshot) {
      for (var doc in querySnapshot.docs) {
        friendRequestsFetchedFromFirebase.add(doc);
      }
    }).catchError((error, stackTrace) {
      _toolsVM.printWarning("Failed to fetch friend requests: $error");
      FirebaseCrashlytics.instance.recordError(error, stackTrace);
    });
    addFetchedFriendRequestsDataToLocalList(friendRequestsFetchedFromFirebase);
  }

  Future<void> addFetchedFriendRequestsDataToLocalList(
      List<QueryDocumentSnapshot> friendRequestsFetchedFromFirebase) async {
    List<User> newList = [];
    for (int i = 0; i < friendRequestsFetchedFromFirebase.length; i++) {
      DocumentSnapshot doc = await users
          .doc(friendRequestsFetchedFromFirebase[i].get('userId'))
          .get();
      newList.add(User(
          doc.get('nickname') ?? 'No nickname',
          friendRequestsFetchedFromFirebase[i].get('email'),
          friendRequestsFetchedFromFirebase[i].get('userId')));
    }
    _friendsServiceVM.putFriendRequestsList(newList);
  }

  Future<void> sendFriendRequest(User friendRequestReceiver) async {
    final uid = _firebaseAuth.auth.currentUser?.uid;
    if (uid == null) return;
    await users
        .doc(friendRequestReceiver.userId)
        .collection('friendRequests')
        .doc(uid)
        .set({
      'userId': uid,
      'email': _firebaseAuth.auth.currentUser!.email
    });
    _friendsServiceVM.removeUserFromUsersList(friendRequestReceiver);
  }

  Future<void> acceptFriendRequest(User friendRequestSender) async {
    final uid = _firebaseAuth.auth.currentUser?.uid;
    if (uid == null) return;
    await users
        .doc(uid)
        .collection('friendRequests')
        .doc(friendRequestSender.userId)
        .delete();
    await users
        .doc(uid)
        .collection('friends')
        .doc(friendRequestSender.userId)
        .set({
      'userId': friendRequestSender.userId,
      'email': friendRequestSender.email
    });
    await users
        .doc(friendRequestSender.userId)
        .collection('friends')
        .doc(uid)
        .set({
      'userId': uid,
      'email': _firebaseAuth.auth.currentUser!.email
    });
    _friendsServiceVM.addUserToFriendsList(friendRequestSender);
    _friendsServiceVM.removeUserFromFriendRequestsList(friendRequestSender);
  }

  Future<void> declineFriendRequest(User friendRequestSender) async {
    final uid = _firebaseAuth.auth.currentUser?.uid;
    if (uid == null) return;
    await users
        .doc(uid)
        .collection('friendRequests')
        .doc(friendRequestSender.userId)
        .delete();
    _friendsServiceVM.removeUserFromFriendRequestsList(friendRequestSender);
  }

  Future<void> removeFriendFromFriendsList(User friendToRemove) async {
    final uid = _firebaseAuth.auth.currentUser?.uid;
    if (uid == null) return;
    await users
        .doc(uid)
        .collection('friends')
        .doc(friendToRemove.userId)
        .delete();
    await users
        .doc(friendToRemove.userId)
        .collection('friends')
        .doc(uid)
        .delete();
    _friendsServiceVM.removeUserFromFriendsList(friendToRemove);
  }

  // -- LIST ACCESS (share/unshare, v2 per-uid map) ----------------------------

  /// Self-initiated "unshare from me" — user rezygnuje z cudzej udostępnionej
  /// listy. Kasuje mój pointer i ustawia revokedAt na ownera `usersWithAccess.<myUid>`.
  Future<void> unshareListFromMe(ShoppingList list) async {
    final uid = _firebaseAuth.auth.currentUser?.uid;
    if (uid == null || list.ownerId == uid) return;
    try {
      await users
          .doc(uid)
          .collection('sharedLists')
          .doc(list.documentId)
          .delete();
    } catch (error, stackTrace) {
      _toolsVM.printWarning("Failed to delete sharedLists pointer: $error");
      FirebaseCrashlytics.instance.recordError(error, stackTrace);
    }
    final ref = _listDocRef(list.documentId, list.ownerId);
    try {
      await _writer.revokeAccess(ref: ref, uid: uid);
    } catch (error, stackTrace) {
      _toolsVM.printWarning("Failed to revoke my access on owner doc: $error");
      FirebaseCrashlytics.instance.recordError(error, stackTrace);
    }
  }

  Future<void> giveFriendAccessToYourShoppingList(
      User friend, String documentId) async {
    final uid = _firebaseAuth.auth.currentUser?.uid;
    if (uid == null || friend.userId == uid) return;
    // 1) Pointer na friendzie
    await users
        .doc(friend.userId)
        .collection('sharedLists')
        .doc(documentId)
        .set({
      FirestoreFields.documentId: documentId,
      FirestoreFields.ownerId: uid,
    });
    // 2) grantAccess na moim liście (per-uid map write)
    final ref = _listDocRef(documentId, uid);
    await _migrator.migrateIfNeeded(ref);
    try {
      await _writer.grantAccess(ref: ref, uid: friend.userId);
    } catch (error, stackTrace) {
      _toolsVM.printWarning("Failed to grant access: $error");
      FirebaseCrashlytics.instance.recordError(error, stackTrace);
    }
  }

  Future<void> denyFriendAccessToYourShoppingList(
      User friend, String documentId, List<User> usersWithAccess) async {
    final uid = _firebaseAuth.auth.currentUser?.uid;
    if (uid == null || friend.userId == uid) return;
    await users
        .doc(friend.userId)
        .collection('sharedLists')
        .doc(documentId)
        .delete();
    final ref = _listDocRef(documentId, uid);
    await _migrator.migrateIfNeeded(ref);
    try {
      await _writer.revokeAccess(ref: ref, uid: friend.userId);
    } catch (error, stackTrace) {
      _toolsVM.printWarning("Failed to revoke friend access: $error");
      FirebaseCrashlytics.instance.recordError(error, stackTrace);
    }
  }

  // -- SETTINGS ---------------------------------------------------------------

  Future<void> deleteEveryDataRelatedToCurrentUser() async {
    final uid = _firebaseAuth.auth.currentUser?.uid;
    if (uid == null) return;
    // Revoke swój dostęp na każdej cudzej udostępnionej nam liście.
    QuerySnapshot lists = await users
        .doc(uid)
        .collection('sharedLists')
        .get()
        .catchError((onError, stackTrace) {
      _toolsVM.printWarning("Failed to fetch sharedLists: $onError");
      FirebaseCrashlytics.instance.recordError(onError, stackTrace);
      return onError;
    });
    for (final list in lists.docs) {
      try {
        final ownerId = list.get(FirestoreFields.ownerId) as String;
        final documentId = list.get(FirestoreFields.documentId) as String;
        final ref = _listDocRef(documentId, ownerId);
        await _writer.revokeAccess(ref: ref, uid: uid);
      } catch (error, stackTrace) {
        _toolsVM.printWarning("Failed to revoke my access: $error");
        FirebaseCrashlytics.instance.recordError(error, stackTrace);
      }
    }
    // Usuń pointery na każdym friendzie którego ja udostępniam.
    _shoppingListsVM.currentlyDisplayedListType =
        ShoppingListType.ownShoppingLists;
    for (final list in _shoppingListsVM.shoppingLists) {
      for (final user in list.usersWithAccess) {
        await users
            .doc(user.userId)
            .collection('sharedLists')
            .doc(list.documentId)
            .delete();
      }
    }
    // Usuń znajomych
    for (final friend in _friendsServiceVM.friendsList) {
      removeFriendFromFriendsList(friend);
    }
    _toolsVM.clearAuthenticationTextEditingControllers();
    // Usuń dane lokalne + konto.
    await Hive.box<ShoppingList>('shopping_lists').clear();
    await Hive.box<int>('data_variables').clear();
    await users.doc(uid).delete();
    await _firebaseAuth.deleteAccount();
  }
}
