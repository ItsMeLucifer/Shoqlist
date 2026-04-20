import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:hive_ce/hive.dart';
import 'package:shoqlist/models/user.dart';
import 'package:shoqlist/models/loyalty_card.dart';
import 'package:shoqlist/models/shopping_list.dart';
import 'package:shoqlist/models/shopping_list_item.dart';
import 'package:shoqlist/viewmodels/firebase_auth_view_model.dart';
import 'package:shoqlist/viewmodels/friends_service_view_model.dart';
import 'package:shoqlist/viewmodels/loyalty_cards_view_model.dart';
import 'package:shoqlist/viewmodels/shopping_lists_view_model.dart';
import 'package:shoqlist/viewmodels/tools.dart';

class FirebaseViewModel extends ChangeNotifier {
  final ShoppingListsViewModel _shoppingListsVM;
  final LoyaltyCardsViewModel _loyaltyCardsVM;
  final Tools _toolsVM;
  final FirebaseAuthViewModel _firebaseAuth;
  final FriendsServiceViewModel _friendsServiceVM;
  FirebaseViewModel(this._shoppingListsVM, this._loyaltyCardsVM, this._toolsVM,
      this._firebaseAuth, this._friendsServiceVM);

  CollectionReference users = FirebaseFirestore.instance.collection('users');

  //SYNCHRONIZATION
  int _cloudTimestamp = 0;

  Future<void> compareDiscrepanciesBetweenCloudAndLocalData() async {
    int? localTimestamp = _shoppingListsVM.getLocalTimestamp();
    if (localTimestamp == null || _cloudTimestamp >= localTimestamp) {
      await addFetchedShoppingListsDataToLocalList();
      return;
    }
    _toolsVM.fetchStatus = FetchStatus.fetched;
    putLocalShoppingListsDataToFirebase();
  }

  // -- SHOPPING LISTS
  final List<QueryDocumentSnapshot> _shoppingListsFetchedFromFirebase = [];
  final List<DocumentSnapshot> _sharedShoppingListsFetchedFromFirebase = [];
  // Re-entrancy guard. fetchData() z MainScaffold + connectivity listener +
  // pull-to-refresh mogą wywoływać `getShoppingListsFromFirebase` równolegle.
  // Każdy call modyfikuje te same buffer listy — bez guarda duplikujemy.
  bool _fetchingShoppingLists = false;

  Future<void> getShoppingListsFromFirebase(
      bool shouldCompareCloudDataWithLocalOne) async {
    final uid = _firebaseAuth.auth.currentUser?.uid;
    if (uid == null) return;
    if (_fetchingShoppingLists) return;
    _fetchingShoppingLists = true;
    try {
      // Clear OBYDWU bufferów ZAWSZE (poprzednio clear list był za if size>0,
      // więc pusta odpowiedź zostawiała stare dane).
      _shoppingListsFetchedFromFirebase.clear();
      _sharedShoppingListsFetchedFromFirebase.clear();
      await users.doc(uid).get().then((DocumentSnapshot snapshot) => {
            if (snapshot.exists) {_cloudTimestamp = snapshot.get('timestamp')}
          });
      await users.doc(uid).collection('lists').get().then(
          (QuerySnapshot? querySnapshot) {
        if (querySnapshot != null && querySnapshot.size > 0) {
          for (var doc in querySnapshot.docs) {
            _shoppingListsFetchedFromFirebase.add(doc);
          }
        }
      }).catchError((error, stackTrace) {
        final warning =
            "Failed to fetch shopping lists data from Firebase: $error";
        _toolsVM.printWarning(warning);
        _shoppingListsVM.clearDisplayedData();
        FirebaseCrashlytics.instance.recordError(warning, stackTrace);
        _firebaseAuth.signOut();
        return;
      });
      List<DocumentSnapshot> sharedListsReferences = [];
      await users.doc(uid).collection('sharedLists').get().then(
          (QuerySnapshot? querySnapshot) {
        if (querySnapshot != null && querySnapshot.size > 0) {
          for (var doc in querySnapshot.docs) {
            sharedListsReferences.add(doc);
          }
        }
      }).catchError((error, stackTrace) {
        final warning =
            "Failed to fetch informations about shared shopping lists from Firebase: $error";
        _toolsVM.printWarning(warning);
        FirebaseCrashlytics.instance.recordError(warning, stackTrace);
      });
      await getDocumentsFromReferences(sharedListsReferences);
      if (shouldCompareCloudDataWithLocalOne) {
        await compareDiscrepanciesBetweenCloudAndLocalData();
      } else {
        await addFetchedShoppingListsDataToLocalList();
      }

      if (_toolsVM.refreshStatus == RefreshStatus.duringRefresh) {
        _toolsVM.refreshStatus = RefreshStatus.refreshed;
      }
    } finally {
      _fetchingShoppingLists = false;
    }
  }

  Future<void> getDocumentsFromReferences(List<DocumentSnapshot> list) async {
    _sharedShoppingListsFetchedFromFirebase.clear();
    for (DocumentSnapshot doc in list) {
      String ownerId = doc.get('ownerId');
      String documentId = doc.get('documentId');
      await users
          .doc(ownerId)
          .collection('lists')
          .doc(documentId)
          .get()
          .then((DocumentSnapshot document) => {
                if (document.exists)
                  {_sharedShoppingListsFetchedFromFirebase.add(document)}
              })
          .catchError((error, stackTrace) {
        final warning =
            "Failed to fetch shared shopping lists data from Firebase: $error";
        _toolsVM.printWarning(warning);
        FirebaseCrashlytics.instance.recordError(warning, stackTrace);
        return error;
      });
    }
  }

  Future<void> fetchOneShoppingList(String documentId, String ownerId) async {
    List<String> usersIdsWithAccess = [];
    List<User> usersWithAccess = [];
    ShoppingList? currentShoppingList;
    String ownerName = '';
    DocumentSnapshot? doc = await users
        .doc(ownerId)
        .collection('lists')
        .doc(documentId)
        .get()
        .catchError((error, stackTrace) {
      final warning =
          "Failed to fetch shopping list [$documentId] data from Firebase: $error";
      _toolsVM.printWarning(warning);
      FirebaseCrashlytics.instance.recordError(warning, stackTrace);
      return error;
    });
    if (doc.exists) {
      final ids = (doc.get('usersWithAccess') as List?)?.cast<String>() ?? const [];
      usersIdsWithAccess.addAll(ids);
      usersWithAccess
          .addAll(await Future.wait(ids.map((id) => getUserById(id))));
      List<ShoppingListItem> items = [];
      for (int j = 0; j < doc.get('listContent').length; j++) {
        items.add(
          ShoppingListItem(doc.get('listContent')[j], doc.get('listState')[j],
              doc.get('listFavorite')[j]),
        );
      }

      ownerName = await getUserName(doc.get('ownerId'));
      currentShoppingList = ShoppingList(
          doc.get('name'),
          items,
          _toolsVM.getImportanceValueFromLabel(doc.get('importance')),
          doc.get('id'),
          doc.get('ownerId'),
          ownerName,
          usersWithAccess);
    }
    if (currentShoppingList != null) {
      _shoppingListsVM.updateCurrentShoppingList(currentShoppingList);
    }
  }

  void putLocalShoppingListsDataToFirebase() {
    final uid = _firebaseAuth.auth.currentUser?.uid;

    if (uid == null) return;
    List<ShoppingList> localLists = _shoppingListsVM.getLocalShoppingList();
    List<String> listContent = [];
    List<bool> listFavorite = [];
    List<bool> listState = [];
    List<String> usersWithAccess = [];
    for (ShoppingList localList in localLists) {
      listContent.clear();
      listFavorite.clear();
      listState.clear();
      if (localList.list.isNotEmpty && localList.usersWithAccess.isNotEmpty) {
        for (var element in localList.list) {
            listContent.add(element.itemName);
            listFavorite.add(element.isFavorite);
            listState.add(element.gotItem);
          }
        usersWithAccess.clear();
        for (var user in localList.usersWithAccess) {
            usersWithAccess.add(user.userId);
          }
        users
            .doc(localList.ownerId)
            .collection('lists')
            .doc(localList.documentId)
            .set({
              'name': localList.name,
              'importance': _toolsVM.getImportanceLabel(localList.importance),
              'listContent': listContent,
              'listState': listState,
              'listFavorite': listFavorite,
              'id': localList.documentId,
              'ownerId': localList.ownerId,
              'usersWithAccess': usersWithAccess
            })
            .then(
              (value) => debugPrint(
                "Updated list on Firebase",
              ),
            )
            .catchError((error, stackTrace) {
              final warning = "Failed to update list on Firebase: $error";
              _toolsVM.printWarning(warning);
              FirebaseCrashlytics.instance.recordError(warning, stackTrace);
            });
      }
    }
    users
        .doc(uid)
        .update({'timestamp': _shoppingListsVM.getLocalTimestamp()});
    _shoppingListsVM
        .displayLocalShoppingLists(uid);
  }

  Future<void> addFetchedShoppingListsDataToLocalList() async {
    final uid = _firebaseAuth.auth.currentUser?.uid;
    if (uid == null) return;
    List<ShoppingList> result = [];
    List<String> usersIdsWithAccess = [];
    List<User> usersWithAccess = [];
    List<ShoppingList> shoppingLists = [];
    String ownerName = "";
    //Fetched Shopping lists to List<ShoppingList>
    for (int i = 0; i < _shoppingListsFetchedFromFirebase.length; i++) {
      usersIdsWithAccess.clear();
      usersWithAccess.clear();
      final ids = (_shoppingListsFetchedFromFirebase[i].get('usersWithAccess')
                  as List?)
              ?.cast<String>() ??
          const [];
      usersIdsWithAccess.addAll(ids);
      usersWithAccess
          .addAll(await Future.wait(ids.map((id) => getUserById(id))));
      List<ShoppingListItem> items = [];
      for (int j = 0;
          j < _shoppingListsFetchedFromFirebase[i].get('listContent').length;
          j++) {
        items.add(
          ShoppingListItem(
              _shoppingListsFetchedFromFirebase[i].get('listContent')[j],
              _shoppingListsFetchedFromFirebase[i].get('listState')[j],
              _shoppingListsFetchedFromFirebase[i].get('listFavorite')[j]),
        );
      }
      ownerName = await getUserName(
          _shoppingListsFetchedFromFirebase[i].get('ownerId'));
      shoppingLists.add(ShoppingList(
          _shoppingListsFetchedFromFirebase[i].get('name'),
          items,
          _toolsVM.getImportanceValueFromLabel(
              _shoppingListsFetchedFromFirebase[i].get('importance')),
          _shoppingListsFetchedFromFirebase[i].get('id'),
          _shoppingListsFetchedFromFirebase[i].get('ownerId'),
          ownerName,
          usersWithAccess));
    }
    //Fetched Shared Shopping lists to List<ShoppingList>
    List<ShoppingList> sharedLists = [];
    for (int i = 0; i < _sharedShoppingListsFetchedFromFirebase.length; i++) {
      List<ShoppingListItem> sharedItems = [];
      for (int j = 0;
          j <
              _sharedShoppingListsFetchedFromFirebase[i]
                  .get('listContent')
                  .length;
          j++) {
        sharedItems.add(
          ShoppingListItem(
              _sharedShoppingListsFetchedFromFirebase[i].get('listContent')[j],
              _sharedShoppingListsFetchedFromFirebase[i].get('listState')[j],
              _sharedShoppingListsFetchedFromFirebase[i]
                  .get('listFavorite')[j]),
        );
      }
      ownerName = await getUserName(
          _sharedShoppingListsFetchedFromFirebase[i].get('ownerId'));

      // usersWithAccess is intentionally not populated for shared lists — only
      // the owner needs that metadata.
      sharedLists.add(ShoppingList(
          _sharedShoppingListsFetchedFromFirebase[i].get('name'),
          sharedItems,
          _toolsVM.getImportanceValueFromLabel(
              _sharedShoppingListsFetchedFromFirebase[i].get('importance')),
          _sharedShoppingListsFetchedFromFirebase[i].get('id'),
          _sharedShoppingListsFetchedFromFirebase[i].get('ownerId'),
          ownerName));
    }
    // Defense-in-depth: dedup po documentId. Firestore odpowiedzi powinny
    // mieć unikalne ids, ale jakiekolwiek race między concurrent fetches
    // nie zostawi duplikatów w final state.
    final merged = [...shoppingLists, ...sharedLists];
    final seen = <String>{};
    result = [
      for (final list in merged)
        if (seen.add(list.documentId)) list
    ];
    _shoppingListsVM.overrideShoppingListsLocally(
        result, _cloudTimestamp, uid);
    _toolsVM.fetchStatus = FetchStatus.fetched;
  }

  Future<void> putShoppingListToFirebase(
      String name, Importance importance, String documentId) async {
    final uid = _firebaseAuth.auth.currentUser?.uid;

    if (uid == null) return;
    users
        .doc(uid)
        .collection('lists')
        .doc(documentId)
        .set({
          'name': name,
          'importance': _toolsVM.getImportanceLabel(importance),
          'listContent': [],
          'listState': [],
          'listFavorite': [],
          'id': documentId,
          'ownerId': uid,
          'usersWithAccess': []
        })
        .then((value) => debugPrint("Created new List"))
        .catchError((error, stackTrace) {
          final warning = "Failed to create list: $error";
          _toolsVM.printWarning(warning);
          FirebaseCrashlytics.instance.recordError(warning, stackTrace);
        });
  }

  Future<void> updateShoppingListToFirebase(
      String name, Importance importance, String documentId) async {
    //ONLY FOR YOUR OWN LISTS, NOT SHARED ONE
    final uid = _firebaseAuth.auth.currentUser?.uid;

    if (uid == null) return;
    users
        .doc(uid)
        .collection('lists')
        .doc(documentId)
        .update({
          'name': name,
          'importance': _toolsVM.getImportanceLabel(importance),
        })
        .then((value) => debugPrint("Updated list"))
        .catchError((error, stackTrace) {
          final warning = "Failed to update list: $error";
          _toolsVM.printWarning(warning);
          FirebaseCrashlytics.instance.recordError(warning, stackTrace);
        });
  }

  Future<void> deleteShoppingListOnFirebase(String documentId) async {
    final uid = _firebaseAuth.auth.currentUser?.uid;
    if (uid == null) return;
    //If this list was shared to someone, delete his reference to this list
    DocumentSnapshot document;
    try {
      document =
          await getDocumentSnapshotFromFirebaseWithId(documentId, 'lists');
    } catch (error, stackTrace) {
      final warning =
          "Could not get document from Firebase during deleting a shopping list, error: $error";
      FirebaseCrashlytics.instance.recordError(warning, stackTrace);
      return _toolsVM.printWarning(warning);
    }
    if (document.exists && document.get('usersWithAccess').isNotEmpty) {
      document.get('usersWithAccess').forEach((user) async {
        await users
            .doc(user)
            .collection('sharedLists')
            .doc(documentId)
            .delete();
      });
    }
    //Delete shopping list
    await users
        .doc(uid)
        .collection('lists')
        .doc(documentId)
        .delete()
        .then((value) => debugPrint("List Deleted"))
        .catchError((error, stackTrace) {
      final warning = "Failed to delete list: $error";
      _toolsVM.printWarning(warning);
      FirebaseCrashlytics.instance.recordError(warning, stackTrace);
    });
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
      final warning = "Failed to get document snapshot: $error";
      _toolsVM.printWarning(warning);
      FirebaseCrashlytics.instance.recordError(warning, stackTrace);
      return error;
    });
  }

  Future<void> updateShoppingListItemNameOnFirebase(
    String newName,
    int itemIndex,
    String documentId, [
    String? ownerId,
  ]) async {
    DocumentSnapshot document;
    try {
      document = await getDocumentSnapshotFromFirebaseWithId(
          documentId, 'lists', ownerId);
    } catch (e) {
      return _toolsVM.printWarning(
        "Could not get document from Firebase during updating item name, error: $e",
      );
    }
    final listContent = List<dynamic>.from(document.get('listContent'));
    if (itemIndex < 0 || itemIndex >= listContent.length) return;
    listContent[itemIndex] = newName;
    await users
        .doc(ownerId ?? _firebaseAuth.auth.currentUser?.uid)
        .collection('lists')
        .doc(documentId)
        .update({'listContent': listContent}).catchError((error, stackTrace) {
      final warning = "Failed to update item name: $error";
      _toolsVM.printWarning(warning);
      FirebaseCrashlytics.instance.recordError(warning, stackTrace);
    });
  }

  Future<void> addNewItemToShoppingListOnFirebase(
    String itemName,
    String documentId, [
    String? ownerId,
  ]) async {
    DocumentSnapshot document;
    try {
      document = await getDocumentSnapshotFromFirebaseWithId(
          documentId, 'lists', ownerId);
    } catch (e) {
      return _toolsVM.printWarning(
        "Could not get document from Firebase during adding new item to shopping list, error: $e",
      );
    }
    List<dynamic> listContent = document.get('listContent');
    listContent.add(itemName);
    List<dynamic> listState = document.get('listState');
    listState.add(false);
    List<dynamic> listFavorite = document.get('listFavorite');
    listFavorite.add(false);
    await users
        .doc(ownerId)
        .collection('lists')
        .doc(documentId)
        .update({
          'listContent': listContent,
          'listState': listState,
          'listFavorite': listFavorite
        })
        .then((value) => debugPrint("New item added"))
        .catchError((error, stackTrace) {
          final warning = "Failed to add new item: $error";
          _toolsVM.printWarning(warning);
          FirebaseCrashlytics.instance.recordError(warning, stackTrace);
        });
  }

  Future<void> deleteShoppingListItemOnFirebase(
    int itemIndex,
    String documentId, [
    String? ownerId,
  ]) async {
    DocumentSnapshot document;
    try {
      document = await getDocumentSnapshotFromFirebaseWithId(
          documentId, 'lists', ownerId);
    } catch (error, stackTrace) {
      final warning =
          "Could not get document from Firebase during deleting shopping list's item, error: $error";
      FirebaseCrashlytics.instance.recordError(warning, stackTrace);
      return _toolsVM.printWarning(warning);
    }
    List<dynamic> listContent = document.get('listContent');
    List<dynamic> listState = document.get('listState');
    List<dynamic> listFavorite = document.get('listFavorite');
    listContent.removeAt(itemIndex);
    listState.removeAt(itemIndex);
    listFavorite.removeAt(itemIndex);
    await users
        .doc(ownerId)
        .collection('lists')
        .doc(documentId)
        .update({
          'listContent': listContent,
          'listState': listState,
          'listFavorite': listFavorite
        })
        .then((value) => debugPrint("List item deleted"))
        .catchError((error, stackTrace) {
          final warning = "Failed to delete item: $error";
          _toolsVM.printWarning(warning);
          FirebaseCrashlytics.instance.recordError(warning, stackTrace);
        });
  }

  Future<void> toggleStateOfShoppingListItemOnFirebase(
    String documentId,
    int itemIndex, [
    String? ownerId,
  ]) async {
    DocumentSnapshot document;
    try {
      document = await getDocumentSnapshotFromFirebaseWithId(
          documentId, 'lists', ownerId);
    } catch (error, stackTrace) {
      final warning =
          "Could not get document from Firebase during toogling state of shopping list, error: $error";
      FirebaseCrashlytics.instance.recordError(warning, stackTrace);
      return _toolsVM.printWarning(warning);
    }
    List<dynamic> listState = document.get('listState');
    listState[itemIndex] = !listState[itemIndex];
    await users
        .doc(ownerId)
        .collection('lists')
        .doc(documentId)
        .update({
          'listState': listState,
        })
        .then((value) => debugPrint("Changed state of item"))
        .catchError((error, stackTrace) {
          final warning = "Failed to toggle item's state: $error";
          _toolsVM.printWarning(warning);
          FirebaseCrashlytics.instance.recordError(warning, stackTrace);
        });
  }

  Future<void> toggleFavoriteOfShoppingListItemOnFirebase(
    String documentId,
    int itemIndex,
    String ownerId,
  ) async {
    DocumentSnapshot document;
    try {
      document = await getDocumentSnapshotFromFirebaseWithId(
          documentId, 'lists', ownerId);
    } catch (error, stackTrace) {
      final warning =
          "Could not get document from Firebase during toggling favorite of shopping list, error: $error";
      FirebaseCrashlytics.instance.recordError(warning, stackTrace);
      return _toolsVM.printWarning(warning);
    }
    if (!document.exists) return debugPrint('Document does not exist');
    List<dynamic> listFavorite = document.get('listFavorite');
    // When added to favorite last item in the list, there was an error related to index range - fix in future
    listFavorite[itemIndex] = !listFavorite[itemIndex];
    await users
        .doc(ownerId)
        .collection('lists')
        .doc(documentId)
        .update({
          'listFavorite': listFavorite,
        })
        .then((value) => debugPrint("Changed state of item"))
        .catchError((error, stackTrace) {
          final warning = "Failed to toggle item's state: $error";
          _toolsVM.printWarning(warning);
          FirebaseCrashlytics.instance.recordError(warning, stackTrace);
        });
  }

  Future<String> getUserName(String userId) async {
    return await users.doc(userId).get().then((doc) => doc.get('nickname'));
  }

  Future<User> getUserById(String userId) async {
    final doc = await users.doc(userId).get();
    if (!doc.exists) return User('', '', userId);
    return User(
      (doc.get('nickname') as String?) ?? '',
      (doc.get('email') as String?) ?? '',
      userId,
    );
  }

  // -- LOYALTY CARDS
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
        })
        .catchError((error, stackTrace) {
      final warning =
          "Failed to fetch loyalty cards data from Firebase: $error";
      _toolsVM.printWarning(warning);
      FirebaseCrashlytics.instance.recordError(warning, stackTrace);
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
          final warning = "Failed to create Loyalty card: $error";
          _toolsVM.printWarning(warning);
          FirebaseCrashlytics.instance.recordError(warning, stackTrace);
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
        .then((value) => debugPrint("Created new Loyalty card"))
        .catchError((error, stackTrace) {
          final warning = "Failed to update [$documentId] Loyalty card: $error";
          _toolsVM.printWarning(warning);
          FirebaseCrashlytics.instance.recordError(warning, stackTrace);
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
      final warning = "Failed to delete [$documentId] loyalty card: $error";
      _toolsVM.printWarning(warning);
      FirebaseCrashlytics.instance.recordError(warning, stackTrace);
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
      final warning =
          "Could not get document from Firebase during toogling favorite of loyalty list, error: $error";
      FirebaseCrashlytics.instance.recordError(warning, stackTrace);
      return _toolsVM.printWarning(warning);
    }
    bool isFavorite = document.get('isFavorite');
    isFavorite = !isFavorite;
    await users
        .doc(uid)
        .collection('loyaltyCards')
        .doc(documentId)
        .update({
          'isFavorite': isFavorite,
        })
        .then((value) => debugPrint("Changed favorite of loyalty card"))
        .catchError((error, stackTrace) {
          final warning = "Failed to toggle loyalty card's favorite: $error";
          _toolsVM.printWarning(warning);
          FirebaseCrashlytics.instance.recordError(warning, stackTrace);
        });
  }

  // -- FRIENDS

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
    await users
        .doc(uid)
        .collection('friends')
        .get()
        .then((QuerySnapshot querySnapshot) {
      for (var doc in querySnapshot.docs) {
        friendsFetchedFromFirebase.add(doc);
      }
    }).catchError((error, stackTrace) {
      final warning = "Failed to fetch friends data from Firebase: $error";
      _toolsVM.printWarning(warning);
      FirebaseCrashlytics.instance.recordError(warning, stackTrace);
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
    await users
        .doc(uid)
        .collection('friendRequests')
        .get()
        .then((QuerySnapshot querySnapshot) {
      for (var doc in querySnapshot.docs) {
        friendRequestsFetchedFromFirebase.add(doc);
      }
    }).catchError((error, stackTrace) {
      final warning =
          "Failed to fetch friend requests data from Firebase: $error";
      _toolsVM.printWarning(warning);
      FirebaseCrashlytics.instance.recordError(warning, stackTrace);
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
    //Add current user to friendRequestReceiver's friend requests list
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
    //Delete user from requests list
    await users
        .doc(uid)
        .collection('friendRequests')
        .doc(friendRequestSender.userId)
        .delete();
    //Add user to currentUser's friends list
    await users
        .doc(uid)
        .collection('friends')
        .doc(friendRequestSender.userId)
        .set({
      'userId': friendRequestSender.userId,
      'email': friendRequestSender.email
    });
    //Add currentUser to friendRequestSender's friends list
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
    //Delete user from requests list
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
    //Delete friendToRemove from current user's friends list
    await users
        .doc(uid)
        .collection('friends')
        .doc(friendToRemove.userId)
        .delete();
    //Remove current user from friendToRemove's friends list
    await users
        .doc(friendToRemove.userId)
        .collection('friends')
        .doc(uid)
        .delete();
    _friendsServiceVM.removeUserFromFriendsList(friendToRemove);
  }

  /// Self-initiated "unshare from me": user rezygnuje z udostępnionej listy.
  /// Usuwa mapping w OBU stronach — moje `sharedLists` + mój uid z ownera
  /// `usersWithAccess`. Nie usuwa samej listy u ownera.
  Future<void> unshareListFromMe(ShoppingList list) async {
    final uid = _firebaseAuth.auth.currentUser?.uid;
    if (uid == null || list.ownerId == uid) return;
    await users
        .doc(uid)
        .collection('sharedLists')
        .doc(list.documentId)
        .delete()
        .catchError((error, stackTrace) {
      final warning = "Failed to delete own sharedLists entry: $error";
      _toolsVM.printWarning(warning);
      FirebaseCrashlytics.instance.recordError(warning, stackTrace);
    });
    final ownerListDoc =
        users.doc(list.ownerId).collection('lists').doc(list.documentId);
    DocumentSnapshot snapshot;
    try {
      snapshot = await ownerListDoc.get();
    } catch (e) {
      return _toolsVM.printWarning(
          "Could not fetch owner list snapshot during unshare: $e");
    }
    if (!snapshot.exists) return;
    final data = snapshot.data() as Map<String, dynamic>?;
    final currentAccess =
        List<String>.from(data?['usersWithAccess'] ?? const <String>[]);
    currentAccess.removeWhere((id) => id == uid);
    await ownerListDoc
        .update({'usersWithAccess': currentAccess}).catchError(
            (error, stackTrace) {
      final warning = "Failed to remove uid from owner usersWithAccess: $error";
      _toolsVM.printWarning(warning);
      FirebaseCrashlytics.instance.recordError(warning, stackTrace);
    });
  }

  Future<void> giveFriendAccessToYourShoppingList(
      User friend, String documentId) async {
    final uid = _firebaseAuth.auth.currentUser?.uid;
    if (uid == null || friend.userId == uid) return;
    //Add shopping list's data to friend's sharedLists
    await users
        .doc(friend.userId)
        .collection('sharedLists')
        .doc(documentId)
        .set({
      'documentId': documentId,
      'ownerId': uid,
    });
    //Add friend's id to shopping list's usersWithAccess list
    DocumentSnapshot document;
    try {
      document =
          await getDocumentSnapshotFromFirebaseWithId(documentId, 'lists');
    } catch (error, stackTrace) {
      final warning =
          "Could not get document with friend's list data from Firebase, error: $error";
      FirebaseCrashlytics.instance.recordError(warning, stackTrace);
      return _toolsVM.printWarning(warning);
    }
    List<dynamic> usersWithAccess = document.get('usersWithAccess');
    usersWithAccess.add(friend.userId);
    await users
        .doc(uid)
        .collection('lists')
        .doc(documentId)
        .update({'usersWithAccess': usersWithAccess});
  }

  Future<void> denyFriendAccessToYourShoppingList(
      User friend, String documentId, List<User> usersWithAccess) async {
    final uid = _firebaseAuth.auth.currentUser?.uid;
    if (uid == null || friend.userId == uid) return;
    //Remove shopping list's data from friend's sharedLists
    await users
        .doc(friend.userId)
        .collection('sharedLists')
        .doc(documentId)
        .delete();
    //Remove friend's id from shoppingList's usersWithAccess list
    List<String> usersIdsWithAccess = [];
    for (var user in usersWithAccess) {
      if (user.userId != friend.userId) {
        usersIdsWithAccess.add(user.userId);
      }
    }
    await users
        .doc(uid)
        .collection('lists')
        .doc(documentId)
        .update({'usersWithAccess': usersIdsWithAccess});
  }

  // -- SETTINGS

  Future<void> deleteEveryDataRelatedToCurrentUser() async {
    final uid = _firebaseAuth.auth.currentUser?.uid;
    if (uid == null) return;
    //Go through shared lists and delete currentUserId from usersWithAccess
    QuerySnapshot lists = await users
        .doc(uid)
        .collection('sharedLists')
        .get()
        .catchError((onError, stackTrace) {
      final warning = "Failet to fetch sharedLists data: $onError";
      _toolsVM.printWarning(warning);
      FirebaseCrashlytics.instance.recordError(warning, stackTrace);
      return onError;
    });
    for (final list in lists.docs) {
      try {
        DocumentSnapshot docSnap = await users
            .doc(list.get('ownerId'))
            .collection('lists')
            .doc(list.get('documentId'))
            .get();
        if (docSnap.exists) {
          List<dynamic> usersWithAccess = docSnap.get('usersWithAccess');
          usersWithAccess.remove(uid);
          await users
              .doc(list.get('ownerId'))
              .collection('lists')
              .doc(list.get('documentId'))
              .update({'usersWithAccess': usersWithAccess});
        }
      } catch (error, stackTrace) {
        final warning =
            "Failed to delete current user's id from usersWithAccess list in sharedLists: $error";
        _toolsVM.printWarning(warning);
        FirebaseCrashlytics.instance.recordError(warning, stackTrace);
      }
    }
    //Remove your friend's sharedLists data
    _shoppingListsVM.currentlyDisplayedListType =
        ShoppingListType.ownShoppingLists;
    for (var list in _shoppingListsVM.shoppingLists) {
      for (final user in list.usersWithAccess) {
        await users
            .doc(user.userId)
            .collection('sharedLists')
            .doc(list.documentId)
            .delete();
      }
    }
    //Remove all friends
    for (var friend in _friendsServiceVM.friendsList) {
      removeFriendFromFriendsList(friend);
    }

    _toolsVM.clearAuthenticationTextEditingControllers();
    //Delete account and Sign-out
    await Hive.box<ShoppingList>('shopping_lists').clear();
    await Hive.box<int>('data_variables').clear();
    await users.doc(uid).delete();
    await _firebaseAuth.deleteAccount();
  }
}
