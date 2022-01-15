import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
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
  ShoppingListsViewModel _shoppingListsVM;
  LoyaltyCardsViewModel _loyaltyCardsVM;
  Tools _toolsVM;
  FirebaseAuthViewModel _firebaseAuth;
  FriendsServiceViewModel _friendsServiceVM;
  FirebaseViewModel(this._shoppingListsVM, this._loyaltyCardsVM, this._toolsVM,
      this._firebaseAuth, this._friendsServiceVM);

  CollectionReference users = FirebaseFirestore.instance.collection('users');

  //SYNCHRONIZATION
  int _cloudTimestamp = 0;

  void compareDiscrepanciesBetweenCloudAndLocalData() {
    int localTimestamp = _shoppingListsVM.getLocalTimestamp();
    if (localTimestamp == null || _cloudTimestamp >= localTimestamp) {
      return addFetchedShoppingListsDataToLocalList();
    }
    _toolsVM.fetchStatus = FetchStatus.fetched;
    return putLocalShoppingListsDataToFirebase();
  }

  // -- SHOPPING LISTS
  List<QueryDocumentSnapshot> _shoppingListsFetchedFromFirebase = [];
  List<DocumentSnapshot> _sharedShoppingListsFetchedFromFirebase = [];

  void getShoppingListsFromFirebase(
      bool shouldCompareCloudDataWithLocalOne) async {
    if (_firebaseAuth.auth.currentUser == null) return;
    //Fetch shopping lists
    _sharedShoppingListsFetchedFromFirebase.clear();
    await users
        .doc(_firebaseAuth.auth.currentUser.uid)
        .get()
        .then((DocumentSnapshot snapshot) => {
              if (snapshot.exists) {_cloudTimestamp = snapshot.get('timestamp')}
            });
    await users
        .doc(_firebaseAuth.auth.currentUser.uid)
        .collection('lists')
        .get()
        .then((QuerySnapshot querySnapshot) {
      if (querySnapshot.size > 0) {
        _shoppingListsFetchedFromFirebase.clear();
        querySnapshot.docs.forEach((doc) {
          _shoppingListsFetchedFromFirebase.add(doc);
        });
      }
    }).catchError((error) {
      _toolsVM.printWarning(
          "Failed to fetch shopping lists data from Firebase: $error");
    });
    //Fetch informations about shared shopping lists
    List<DocumentSnapshot> _sharedListsReferences = [];
    await users
        .doc(_firebaseAuth.auth.currentUser.uid)
        .collection('sharedLists')
        .get()
        .then((QuerySnapshot querySnapshot) {
      if (querySnapshot.size > 0) {
        querySnapshot.docs.forEach((doc) {
          _sharedListsReferences.add(doc);
        });
      }
    }).catchError((error) {
      _toolsVM.printWarning(
          "Failed to fetch informations about shared shopping lists from Firebase: $error");
    });
    await getDocumentsFromReferences(_sharedListsReferences);
    if (shouldCompareCloudDataWithLocalOne) {
      compareDiscrepanciesBetweenCloudAndLocalData();
    } else {
      addFetchedShoppingListsDataToLocalList();
    }

    if (_toolsVM.refreshStatus == RefreshStatus.duringRefresh) {
      _toolsVM.refreshStatus = RefreshStatus.refreshed;
    }
  }

  Future<void> getDocumentsFromReferences(List<DocumentSnapshot> _list) async {
    _sharedShoppingListsFetchedFromFirebase.clear();
    for (DocumentSnapshot doc in _list) {
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
          .catchError((error) {
        _toolsVM.printWarning(
            "Failed to fetch shared shopping lists data from Firebase: $error");
      });
    }
  }

  void fetchOneShoppingList(String documentId, String ownerId) async {
    List<String> usersIdsWithAccess = [];
    List<User> usersWithAccess = [];
    ShoppingList _currentShoppingList;
    String ownerName = '';
    DocumentSnapshot doc = await users
        .doc(ownerId)
        .collection('lists')
        .doc(documentId)
        .get()
        .catchError((error) {
      _toolsVM.printWarning(
          "Failed to fetch shopping list [$documentId] data from Firebase: $error");
    });
    if (doc != null && doc.exists) {
      doc
          .get('usersWithAccess')
          .forEach((userId) => usersIdsWithAccess.add(userId));
      usersIdsWithAccess.forEach((userId) async {
        User user = await getUserById(userId);
        usersWithAccess.add(user);
      });
      List<ShoppingListItem> items = [];
      for (int j = 0; j < doc.get('listContent').length; j++) {
        items.add(
          ShoppingListItem(doc.get('listContent')[j], doc.get('listState')[j],
              doc.get('listFavorite')[j]),
        );
      }

      ownerName = await getUserName(doc.get('ownerId'));
      _currentShoppingList = ShoppingList(
          doc.get('name'),
          items,
          _toolsVM.getImportanceValueFromLabel(doc.get('importance')),
          doc.get('id'),
          doc.get('ownerId'),
          ownerName,
          usersWithAccess);
    }
    _shoppingListsVM.updateCurrentShoppingList(_currentShoppingList);
  }

  void putLocalShoppingListsDataToFirebase() {
    if (_firebaseAuth.auth.currentUser == null) return;
    List<ShoppingList> localLists = _shoppingListsVM.getLocalShoppingList();
    List<String> listContent = [];
    List<bool> listFavorite = [];
    List<bool> listState = [];
    List<String> usersWithAccess = [];
    for (ShoppingList localList in localLists) {
      listContent.clear();
      listFavorite.clear();
      listState.clear();
      localList.list.forEach((element) {
        listContent.add(element.itemName);
        listFavorite.add(element.isFavorite);
        listState.add(element.gotItem);
      });
      usersWithAccess.clear();
      localList.usersWithAccess.forEach((user) {
        usersWithAccess.add(user.userId);
      });
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
          .then((value) => print("Updated list on Firebase"))
          .catchError((error) => _toolsVM
              .printWarning("Failed to update list on Firebase: $error"));
    }
    users
        .doc(_firebaseAuth.auth.currentUser.uid)
        .update({'timestamp': _shoppingListsVM.getLocalTimestamp()});
    _shoppingListsVM
        .displayLocalShoppingLists(_firebaseAuth.currentUser.userId);
  }

  void addFetchedShoppingListsDataToLocalList() async {
    List<ShoppingList> result = [];
    List<String> usersIdsWithAccess = [];
    List<User> usersWithAccess = [];
    List<ShoppingList> shoppingLists = [];
    String ownerName = "";
    //Fetched Shopping lists to List<ShoppingList>
    for (int i = 0; i < _shoppingListsFetchedFromFirebase.length; i++) {
      usersIdsWithAccess.clear();
      usersWithAccess.clear();
      _shoppingListsFetchedFromFirebase[i]
          .get('usersWithAccess')
          .forEach((userId) => usersIdsWithAccess.add(userId));
      usersIdsWithAccess.forEach((userId) async {
        User user = await getUserById(userId);
        usersWithAccess.add(user);
      });
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
    for (int i = 0;
        _sharedShoppingListsFetchedFromFirebase != null &&
            i < _sharedShoppingListsFetchedFromFirebase.length;
        i++) {
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

      //To be honest, it is not necessary to fetch informations
      //about who has the access to shared list, this information
      //has only a meaning for the owner of list. So the function doesn't
      //pass anything

      // usersIdsWithAccess.clear();
      // usersWithAccess.clear();
      // _sharedShoppingListsFetchedFromFirebase[i]
      //     .get('usersWithAccess')
      //     .forEach((userId) => usersIdsWithAccess.add(userId));
      // usersIdsWithAccess.forEach((userId) async {
      //   User user = await getUserById(userId);
      //   usersWithAccess.add(user);
      // });
      sharedLists.add(ShoppingList(
          _sharedShoppingListsFetchedFromFirebase[i].get('name'),
          sharedItems,
          _toolsVM.getImportanceValueFromLabel(
              _sharedShoppingListsFetchedFromFirebase[i].get('importance')),
          _sharedShoppingListsFetchedFromFirebase[i].get('id'),
          _sharedShoppingListsFetchedFromFirebase[i].get('ownerId'),
          ownerName));
    }
    result = [...shoppingLists, ...sharedLists];
    _shoppingListsVM.overrideShoppingListsLocally(
        result, _cloudTimestamp, _firebaseAuth.auth.currentUser.uid);
    _toolsVM.fetchStatus = FetchStatus.fetched;
  }

  void putShoppingListToFirebase(
      String name, Importance importance, String documentId) async {
    if (_firebaseAuth.auth.currentUser == null) return;
    users
        .doc(_firebaseAuth.auth.currentUser.uid)
        .collection('lists')
        .doc(documentId)
        .set({
          'name': name,
          'importance': _toolsVM.getImportanceLabel(importance),
          'listContent': [],
          'listState': [],
          'listFavorite': [],
          'id': documentId,
          'ownerId': _firebaseAuth.auth.currentUser.uid,
          'usersWithAccess': []
        })
        .then((value) => print("Created new List"))
        .catchError(
            (error) => _toolsVM.printWarning("Failed to create list: $error"));
  }

  void updateShoppingListToFirebase(
      String name, Importance importance, String documentId) async {
    //ONLY FOR YOUR OWN LISTS, NOT SHARED ONE
    if (_firebaseAuth.auth.currentUser == null) return;
    users
        .doc(_firebaseAuth.auth.currentUser.uid)
        .collection('lists')
        .doc(documentId)
        .update({
          'name': name,
          'importance': _toolsVM.getImportanceLabel(importance),
        })
        .then((value) => print("Updated list"))
        .catchError(
            (error) => _toolsVM.printWarning("Failed to update list: $error"));
  }

  void deleteShoppingListOnFirebase(String documentId) async {
    //If this list was shared to someone, delete his reference to this list
    DocumentSnapshot document;
    try {
      document =
          await getDocumentSnapshotFromFirebaseWithId(documentId, 'lists');
    } catch (e) {
      return _toolsVM.printWarning(
          "Could not get document from Firebase during deleting a shopping list, error: " +
              e.code.toString());
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
        .doc(_firebaseAuth.auth.currentUser.uid)
        .collection('lists')
        .doc(documentId)
        .delete()
        .then((value) => print("List Deleted"))
        .catchError(
            (error) => _toolsVM.printWarning("Failed to delete list: $error"));
  }

  Future<DocumentSnapshot> getDocumentSnapshotFromFirebaseWithId(
      String documentId, String collectionName,
      [String ownerId]) async {
    return await users
        .doc(ownerId ?? _firebaseAuth.auth.currentUser.uid)
        .collection(collectionName)
        .doc(documentId)
        .get();
  }

  void addNewItemToShoppingListOnFirebase(String itemName, String documentId,
      [String ownerId]) async {
    DocumentSnapshot document;
    try {
      document = await getDocumentSnapshotFromFirebaseWithId(
          documentId, 'lists', ownerId);
    } catch (e) {
      return _toolsVM.printWarning(
          "Could not get document from Firebase during adding new item to shopping list, error: " +
              e.code.toString());
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
        .then((value) => print("New item added"))
        .catchError(
            (error) => _toolsVM.printWarning("Failed to add new item: $error"));
  }

  void deleteShoppingListItemOnFirebase(int itemIndex, String documentId,
      [String ownerId]) async {
    DocumentSnapshot document;
    try {
      document = await getDocumentSnapshotFromFirebaseWithId(
          documentId, 'lists', ownerId);
    } catch (e) {
      return _toolsVM.printWarning(
          "Could not get document from Firebase during deleting shopping list's item, error: " +
              e.code.toString());
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
        .then((value) => print("List item deleted"))
        .catchError(
            (error) => _toolsVM.printWarning("Failed to delete item: $error"));
  }

  void toggleStateOfShoppingListItemOnFirebase(String documentId, int itemIndex,
      [String ownerId]) async {
    DocumentSnapshot document;
    try {
      document = await getDocumentSnapshotFromFirebaseWithId(
          documentId, 'lists', ownerId);
    } catch (e) {
      return _toolsVM.printWarning(
          "Could not get document from Firebase during toogling state of shopping list, error: " +
              e.code.toString());
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
        .then((value) => print("Changed state of item"))
        .catchError((error) =>
            _toolsVM.printWarning("Failed to toggle item's state: $error"));
  }

  void toggleFavoriteOfShoppingListItemOnFirebase(
      String documentId, int itemIndex, String ownerId) async {
    DocumentSnapshot document;
    try {
      document = await getDocumentSnapshotFromFirebaseWithId(
          documentId, 'lists', ownerId);
    } catch (e) {
      return _toolsVM.printWarning(
          "Could not get document from Firebase during toggling favorite of shopping list, error: " +
              e.code.toString());
    }
    if (!document.exists) return print('Document does not exist');
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
        .then((value) => print("Changed state of item"))
        .catchError((error) =>
            _toolsVM.printWarning("Failed to toggle item's state: $error"));
  }

  Future<String> getUserName(String userId) async {
    return await users.doc(userId).get().then((doc) => doc.get('nickname'));
  }

  Future<User> getUserById(String userId) async {
    String nickname = "";
    String email = "";
    await users.doc(userId).get().then((doc) {
      if (doc.exists) {
        nickname = doc.get('nickname');
      }
    });
    await users.doc(userId).get().then((doc) {
      if (doc.exists) {
        doc.get('email');
      }
    });
    return User(nickname, email, userId);
  }

  // -- LOYALTY CARDS
  List<QueryDocumentSnapshot> _loyaltyCardsFetchedFromFirebase = [];
  void getLoyaltyCardsFromFirebase(bool shouldUpdateLocalData) async {
    if (_firebaseAuth.auth.currentUser == null) return;
    _loyaltyCardsFetchedFromFirebase.clear();
    await users
        .doc(_firebaseAuth.auth.currentUser.uid)
        .collection('loyaltyCards')
        .get()
        .then((QuerySnapshot querySnapshot) => {
              if (querySnapshot.size > 0)
                {
                  querySnapshot.docs.forEach((doc) {
                    _loyaltyCardsFetchedFromFirebase.add(doc);
                  })
                }
            })
        .catchError((error) {
      _toolsVM.printWarning(
          "Failed to fetch loyalty cards data from Firebase: $error");
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

  void addNewLoyaltyCardToFirebase(
      String name, String barCode, String documentId, int colorValue) async {
    if (_firebaseAuth.auth.currentUser == null) return;
    users
        .doc(_firebaseAuth.auth.currentUser.uid)
        .collection('loyaltyCards')
        .doc(documentId)
        .set({
          'name': name,
          'barCode': barCode,
          'isFavorite': false,
          'id': documentId,
          'color': colorValue
        })
        .then((value) => print("Created new Loyalty card"))
        .catchError((error) =>
            _toolsVM.printWarning("Failed to create Loyalty card: $error"));
  }

  void updateLoyaltyCard(
      String name, String barCode, String documentId, int colorValue) async {
    if (_firebaseAuth.auth.currentUser == null) return;
    users
        .doc(_firebaseAuth.auth.currentUser.uid)
        .collection('loyaltyCards')
        .doc(documentId)
        .update({'name': name, 'barCode': barCode, 'color': colorValue})
        .then((value) => print("Created new Loyalty card"))
        .catchError((error) => _toolsVM.printWarning(
            "Failed to update [$documentId] Loyalty card: $error"));
  }

  void deleteLoyaltyCardOnFirebase(String documentId) async {
    await users
        .doc(_firebaseAuth.currentUser.userId)
        .collection('loyaltyCards')
        .doc(documentId)
        .delete()
        .then((value) => print("Loyalty card Deleted"))
        .catchError((error) => _toolsVM.printWarning(
            "Failed to delete [$documentId] loyalty card: $error"));
  }

  void toggleFavoriteOfLoyaltyCardOnFirebase(String documentId) async {
    DocumentSnapshot document;
    try {
      document = await getDocumentSnapshotFromFirebaseWithId(
          documentId, 'loyaltyCards');
    } catch (e) {
      return _toolsVM.printWarning(
          "Could not get document from Firebase during toogling favorite of loyalty list, error: " +
              e.code.toString());
    }
    bool isFavorite = document.get('isFavorite');
    isFavorite = !isFavorite;
    await users
        .doc(_firebaseAuth.auth.currentUser.uid)
        .collection('loyaltyCards')
        .doc(documentId)
        .update({
          'isFavorite': isFavorite,
        })
        .then((value) => print("Changed favorite of loyalty card"))
        .catchError((error) => _toolsVM
            .printWarning("Failed to toggle loyalty card's favorite: $error"));
  }

  // -- FRIENDS

  Future<void> searchForUser(String input) async {
    _toolsVM.friendsFetchStatus = FetchStatus.duringFetching;
    List<User> _usersGet = [];
    input = _toolsVM.deleteAllWhitespacesFromString(input);
    await users.where("email", isEqualTo: input).get().then((querySnapshot) {
      querySnapshot.docs.forEach((document) {
        if (document.get('userId') != _firebaseAuth.currentUser.userId &&
            !_friendsServiceVM.friendsList.any((element) {
              return element.email == input;
            }) &&
            !_friendsServiceVM.friendRequestsList
                .any((element) => element.email == input)) {
          User _user = User(document.get('nickname'), document.get('email'),
              document.get('userId'));
          _usersGet.add(_user);
        }
      });
    });
    _toolsVM.friendsFetchStatus = FetchStatus.fetched;
    _friendsServiceVM.putUsersList(_usersGet);
  }

  void fetchFriendsList() async {
    List<QueryDocumentSnapshot> _friendsFetchedFromFirebase = [];
    if (_firebaseAuth.auth.currentUser == null) return;
    await users
        .doc(_firebaseAuth.auth.currentUser.uid)
        .collection('friends')
        .get()
        .then((QuerySnapshot querySnapshot) {
      querySnapshot.docs.forEach((doc) {
        _friendsFetchedFromFirebase.add(doc);
      });
    }).catchError((error) => _toolsVM.printWarning(
            "Failed to fetch friends data from Firebase: $error"));
    addFetchedFriendsDataToLocalList(_friendsFetchedFromFirebase);
  }

  void addFetchedFriendsDataToLocalList(
      List<QueryDocumentSnapshot> _friendsFetchedFromFirebase) async {
    List<User> newList = [];
    for (int i = 0; i < _friendsFetchedFromFirebase.length; i++) {
      DocumentSnapshot doc =
          await users.doc(_friendsFetchedFromFirebase[i].get('userId')).get();
      newList.add(User(
          doc.get('nickname') ?? 'No nickname',
          _friendsFetchedFromFirebase[i].get('email'),
          _friendsFetchedFromFirebase[i].get('userId')));
    }
    _friendsServiceVM.putFriendsList(newList);
  }

  void fetchFriendRequestsList() async {
    List<QueryDocumentSnapshot> _friendRequestsFetchedFromFirebase = [];
    if (_firebaseAuth.auth.currentUser == null) return;
    await users
        .doc(_firebaseAuth.auth.currentUser.uid)
        .collection('friendRequests')
        .get()
        .then((QuerySnapshot querySnapshot) {
      querySnapshot.docs.forEach((doc) {
        _friendRequestsFetchedFromFirebase.add(doc);
      });
    }).catchError((error) => _toolsVM.printWarning(
            "Failed to fetch friend requests data from Firebase: $error"));
    addFetchedFriendRequestsDataToLocalList(_friendRequestsFetchedFromFirebase);
  }

  void addFetchedFriendRequestsDataToLocalList(
      List<QueryDocumentSnapshot> _friendRequestsFetchedFromFirebase) async {
    List<User> newList = [];
    for (int i = 0; i < _friendRequestsFetchedFromFirebase.length; i++) {
      DocumentSnapshot doc = await users
          .doc(_friendRequestsFetchedFromFirebase[i].get('userId'))
          .get();
      newList.add(User(
          doc.get('nickname') ?? 'No nickname',
          _friendRequestsFetchedFromFirebase[i].get('email'),
          _friendRequestsFetchedFromFirebase[i].get('userId')));
    }
    _friendsServiceVM.putFriendRequestsList(newList);
  }

  void sendFriendRequest(User friendRequestReceiver) async {
    //Add current user to friendRequestReceiver's friend requests list
    await users
        .doc(friendRequestReceiver.userId)
        .collection('friendRequests')
        .doc(_firebaseAuth.auth.currentUser.uid)
        .set({
      'userId': _firebaseAuth.auth.currentUser.uid,
      'email': _firebaseAuth.auth.currentUser.email
    });
    _friendsServiceVM.removeUserFromUsersList(friendRequestReceiver);
  }

  void acceptFriendRequest(User friendRequestSender) async {
    //Delete user from requests list
    await users
        .doc(_firebaseAuth.currentUser.userId)
        .collection('friendRequests')
        .doc(friendRequestSender.userId)
        .delete();
    //Add user to currentUser's friends list
    await users
        .doc(_firebaseAuth.currentUser.userId)
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
        .doc(_firebaseAuth.currentUser.userId)
        .set({
      'userId': _firebaseAuth.currentUser.userId,
      'email': _firebaseAuth.auth.currentUser.email
    });
    _friendsServiceVM.addUserToFriendsList(friendRequestSender);
    _friendsServiceVM.removeUserFromFriendRequestsList(friendRequestSender);
  }

  void declineFriendRequest(User friendRequestSender) async {
    //Delete user from requests list
    await users
        .doc(_firebaseAuth.currentUser.userId)
        .collection('friendRequests')
        .doc(friendRequestSender.userId)
        .delete();
    _friendsServiceVM.removeUserFromFriendRequestsList(friendRequestSender);
  }

  void removeFriendFromFriendsList(User friendToRemove) async {
    //Delete friendToRemove from current user's friends list
    await users
        .doc(_firebaseAuth.currentUser.userId)
        .collection('friends')
        .doc(friendToRemove.userId)
        .delete();
    //Remove current user from friendToRemove's friends list
    await users
        .doc(friendToRemove.userId)
        .collection('friends')
        .doc(_firebaseAuth.currentUser.userId)
        .delete();
    _friendsServiceVM.removeUserFromFriendsList(friendToRemove);
  }

  void giveFriendAccessToYourShoppingList(
      User friend, String documentId) async {
    if (friend.userId == _firebaseAuth.auth.currentUser.uid) return;
    //Add shopping list's data to friend's sharedLists
    await users
        .doc(friend.userId)
        .collection('sharedLists')
        .doc(documentId)
        .set({
      'documentId': documentId,
      'ownerId': _firebaseAuth.auth.currentUser.uid,
    });
    //Add friend's id to shopping list's usersWithAccess list
    DocumentSnapshot document;
    try {
      document =
          await getDocumentSnapshotFromFirebaseWithId(documentId, 'lists');
    } catch (e) {
      return _toolsVM.printWarning(
          "Could not get document with friend's list data from Firebase, error: " +
              e.code.toString());
    }
    List<dynamic> usersWithAccess = document.get('usersWithAccess');
    usersWithAccess.add(friend.userId);
    await users
        .doc(_firebaseAuth.currentUser.userId)
        .collection('lists')
        .doc(documentId)
        .update({'usersWithAccess': usersWithAccess});
  }

  void denyFriendAccessToYourShoppingList(
      User friend, String documentId, List<User> usersWithAccess) async {
    if (friend.userId == _firebaseAuth.auth.currentUser.uid) return;
    //Remove shopping list's data from friend's sharedLists
    await users
        .doc(friend.userId)
        .collection('sharedLists')
        .doc(documentId)
        .delete();
    //Remove friend's id from shoppingList's usersWithAccess list
    List<String> usersIdsWithAccess = [];
    usersWithAccess.forEach((user) {
      if (user.userId != friend.userId) {
        usersIdsWithAccess.add(user.userId);
      }
    });
    await users
        .doc(_firebaseAuth.currentUser.userId)
        .collection('lists')
        .doc(documentId)
        .update({'usersWithAccess': usersIdsWithAccess});
  }

  // -- SETTINGS

  void deleteEveryDataRelatedToCurrentUser() async {
    //Go through shared lists and delete currentUserId from usersWithAccess
    QuerySnapshot lists = await users
        .doc(_firebaseAuth.auth.currentUser.uid)
        .collection('sharedLists')
        .get()
        .catchError((onError) {
      _toolsVM.printWarning("Failet to fetch sharedLists data: $onError");
    });
    lists.docs.forEach((list) async {
      try {
        DocumentSnapshot docSnap = await users
            .doc(list.get('ownerId'))
            .collection('lists')
            .doc(list.get('documentId'))
            .get();
        if (docSnap.exists) {
          List<dynamic> usersWithAccess = docSnap.get('usersWithAccess');
          usersWithAccess.remove(_firebaseAuth.auth.currentUser.uid);
          await users
              .doc(list.get('ownerId'))
              .collection('lists')
              .doc(list.get('documentId'))
              .update({'usersWithAccess': usersWithAccess});
        }
      } catch (err) {
        _toolsVM.printWarning(
            "Failed to delete current user's id from usersWithAccess list in sharedLists: $err");
      }
    });
    //Remove your friend's sharedLists data
    _shoppingListsVM.currentlyDisplayedListType =
        ShoppingListType.ownShoppingLists;
    _shoppingListsVM.shoppingLists.forEach((list) {
      list.usersWithAccess.forEach((user) async {
        await users
            .doc(user.userId)
            .collection('sharedLists')
            .doc(list.documentId)
            .delete();
      });
    });
    //Remove all friends
    _friendsServiceVM.friendsList.forEach((friend) {
      removeFriendFromFriendsList(friend);
    });

    _toolsVM.clearAuthenticationTextEditingControllers();
    //Delete account and Sign-out
    await Hive.box<ShoppingList>('shopping_lists').clear();
    await Hive.box<int>('data_variables').clear();
    await users.doc(_firebaseAuth.auth.currentUser.uid).delete();
    await _firebaseAuth.deleteAccount();
  }
}
