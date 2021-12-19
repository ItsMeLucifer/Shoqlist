import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shoqlist/main.dart';
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

  //SYNCHRONIZATION
  CollectionReference users = FirebaseFirestore.instance.collection('users');
  int _cloudTimestamp = 0;

  void compareDiscrepanciesBetweenCloudAndLocalData() {
    int localTimestamp = _shoppingListsVM.getLocalTimestamp();
    if (localTimestamp == null || _cloudTimestamp >= localTimestamp) {
      return addFetchedShoppingListsDataToLocalList();
    }
    return putLocalShoppingListsDataToFirebase();
  }

  // -- SHOPPING LISTS
  List<QueryDocumentSnapshot> _shoppingListsFetchedFromFirebase =
      List<QueryDocumentSnapshot>();

  void getShoppingListsFromFirebase(
      bool shouldCompareCloudDataWithLocalOne) async {
    if (_firebaseAuth.auth.currentUser == null) return;
    _shoppingListsFetchedFromFirebase.clear();
    await users
        .doc(_firebaseAuth.auth.currentUser.uid)
        .get()
        .then((DocumentSnapshot snapshot) => {
              if (snapshot.exists)
                {
                  snapshot.data().forEach((key, value) {
                    if (key == "timestamp") {
                      _cloudTimestamp = value;
                      return;
                    }
                  })
                }
            });
    await users
        .doc(_firebaseAuth.auth.currentUser.uid)
        .collection('lists')
        .get()
        .then((QuerySnapshot querySnapshot) => {
              if (querySnapshot.size > 0)
                {
                  querySnapshot.docs.forEach((doc) {
                    _shoppingListsFetchedFromFirebase.add(doc);
                  })
                }
            })
        .catchError((error) =>
            print("Failed to fetch shopping lists data from Firebase: $error"));
    if (shouldCompareCloudDataWithLocalOne)
      compareDiscrepanciesBetweenCloudAndLocalData();
  }

  void putLocalShoppingListsDataToFirebase() {
    if (_firebaseAuth.auth.currentUser == null) return;
    List<ShoppingList> localLists = _shoppingListsVM.getLocalShoppingList();
    List<String> listContent = List<String>();
    List<bool> listFavorite = List<bool>();
    List<bool> listState = List<bool>();
    for (ShoppingList localList in localLists) {
      listContent.clear();
      listFavorite.clear();
      listState.clear();
      localList.list.forEach((element) {
        listContent.add(element.itemName);
        listFavorite.add(element.isFavorite);
        listState.add(element.gotItem);
      });
      users
          .doc(_firebaseAuth.auth.currentUser.uid)
          .collection('lists')
          .doc(localList.documentId)
          .set({
            'name': localList.name,
            'importance': _toolsVM.getImportanceLabel(localList.importance),
            'listContent': listContent,
            'listState': listState,
            'listFavorite': listFavorite,
            'id': localList.documentId,
            'ownerId': localList.ownerId
          })
          .then((value) => print("Updated list on Firebase"))
          .catchError(
              (error) => print("Failed to update list on Firebase: $error"));
    }
    users
        .doc(_firebaseAuth.auth.currentUser.uid)
        .update({'timestamp': _shoppingListsVM.getLocalTimestamp()});
    _shoppingListsVM.displayLocalShoppingLists();
  }

  void addFetchedShoppingListsDataToLocalList() {
    List<ShoppingList> temp = [];
    for (int i = 0; i < _shoppingListsFetchedFromFirebase.length; i++) {
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
      temp.add(ShoppingList(
          _shoppingListsFetchedFromFirebase[i].get('name'),
          items,
          _toolsVM.getImportanceValueFromLabel(
              _shoppingListsFetchedFromFirebase[i].get('importance')),
          _shoppingListsFetchedFromFirebase[i].get('id'),
          _shoppingListsFetchedFromFirebase[i].get('ownerId')));
    }
    _shoppingListsVM.overrideShoppingListLocally(temp, _cloudTimestamp);
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
          'ownerId': null
        })
        .then((value) => print("Created new List"))
        .catchError((error) => print("Failed to create list: $error"));
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
          'id': documentId,
        })
        .then((value) => print("Updated list"))
        .catchError((error) => print("Failed to update list: $error"));
  }

  void deleteShoppingListOnFirebase(String documentId) async {
    //ONLY CURRENT USER'S LISTS, YOU CANT DELETE SHARED LIST
    await users
        .doc(_firebaseAuth.auth.currentUser.uid)
        .collection('lists')
        .doc(documentId)
        .delete()
        .then((value) => print("List Deleted"))
        .catchError((error) => print("Failed to delete list: $error"));
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
      return print(
          "Could not get document from Firebase, error: " + e.code.toString());
    }
    List<dynamic> listContent = document.get('listContent');
    listContent.add(itemName);
    List<dynamic> listState = document.get('listState');
    listState.add(false);
    List<dynamic> listFavorite = document.get('listFavorite');
    listFavorite.add(false);
    await users
        .doc(ownerId ?? _firebaseAuth.auth.currentUser.uid)
        .collection('lists')
        .doc(documentId)
        .update({
          'listContent': listContent,
          'listState': listState,
          'listFavorite': listFavorite
        })
        .then((value) => print("New item added"))
        .catchError((error) => print("Failed to add new item: $error"));
  }

  void deleteShoppingListItemOnFirebase(int itemIndex, String documentId,
      [String ownerId]) async {
    DocumentSnapshot document;
    try {
      document = await getDocumentSnapshotFromFirebaseWithId(
          documentId, 'lists', ownerId);
    } catch (e) {
      return print(
          "Could not get document from Firebase, error: " + e.code.toString());
    }
    List<dynamic> listContent = document.get('listContent');
    List<dynamic> listState = document.get('listState');
    List<dynamic> listFavorite = document.get('listFavorite');
    listContent.removeAt(itemIndex);
    listState.removeAt(itemIndex);
    listFavorite.removeAt(itemIndex);
    await users
        .doc(ownerId ?? _firebaseAuth.auth.currentUser.uid)
        .collection('lists')
        .doc(documentId)
        .update({
          'listContent': listContent,
          'listState': listState,
          'listFavorite': listFavorite
        })
        .then((value) => print("List item deleted"))
        .catchError((error) => print("Failed to delete item: $error"));
  }

  void toggleStateOfShoppingListItemOnFirebase(String documentId, int itemIndex,
      [String ownerId]) async {
    DocumentSnapshot document;
    try {
      document = await getDocumentSnapshotFromFirebaseWithId(
          documentId, 'lists', ownerId);
    } catch (e) {
      return print(
          "Could not get document from Firebase, error: " + e.code.toString());
    }
    List<dynamic> listState = document.get('listState');
    listState[itemIndex] = !listState[itemIndex];
    await users
        .doc(ownerId ?? _firebaseAuth.auth.currentUser.uid)
        .collection('lists')
        .doc(documentId)
        .update({
          'listState': listState,
        })
        .then((value) => print("Changed state of item"))
        .catchError((error) => print("Failed to toggle item's state: $error"));
  }

  void toggleFavoriteOfShoppingListItemOnFirebase(
      String documentId, int itemIndex,
      [String ownerId]) async {
    DocumentSnapshot document;
    try {
      document = await getDocumentSnapshotFromFirebaseWithId(
          documentId, 'lists', ownerId);
    } catch (e) {
      return print(
          "Could not get document from Firebase, error: " + e.code.toString());
    }
    List<dynamic> listFavorite = document.get('listFavorite');
    // When added to favorite last item in the list, there was an error related to index range - fix in future
    listFavorite[itemIndex] = !listFavorite[itemIndex];
    await users
        .doc(ownerId ?? _firebaseAuth.auth.currentUser.uid)
        .collection('lists')
        .doc(documentId)
        .update({
          'listFavorite': listFavorite,
        })
        .then((value) => print("Changed state of item"))
        .catchError((error) => print("Failed to toggle item's state: $error"));
  }

  // -- LOYALTY CARDS
  List<QueryDocumentSnapshot> _loyaltyCardsFetchedFromFirebase =
      List<QueryDocumentSnapshot>();
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
        .catchError((error) =>
            print("Failed to fetch cards data from Firebase: $error"));
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
        .catchError((error) => print("Failed to create Loyalty card: $error"));
  }

  void deleteLoyaltyCardOnFirebase(String documentId) async {
    await users
        .doc(_firebaseAuth.auth.currentUser.uid)
        .collection('loyaltyCards')
        .doc(documentId)
        .delete()
        .then((value) => print("Loyalty card Deleted"))
        .catchError((error) => print("Failed to delete loyalty card: $error"));
  }

  void toggleFavoriteOfLoyaltyCardOnFirebase(String documentId) async {
    DocumentSnapshot document;
    try {
      document = await getDocumentSnapshotFromFirebaseWithId(
          documentId, 'loyaltyCards');
    } catch (e) {
      return print(
          "Could not get document from Firebase, error: " + e.code.toString());
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
        .catchError((error) =>
            print("Failed to toggle loyalty card's favorite: $error"));
  }

  // -- FRIENDS

  Future<void> searchForUser(String input) async {
    List<User> _usersGet = List<User>();
    input = _toolsVM.deleteAllWhitespacesFromString(input);
    await users.where("email", isEqualTo: input).get().then((querySnapshot) {
      querySnapshot.docs.forEach((document) {
        if (document.get('userId') != _firebaseAuth.auth.currentUser.uid &&
            !_friendsServiceVM.friendsList.any((element) {
              print('compare: ' + element.email + ' ' + input);
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
    _friendsServiceVM.putUsersList(_usersGet);
  }

  void fetchFriendsList() async {
    List<QueryDocumentSnapshot> _friendsFetchedFromFirebase =
        List<QueryDocumentSnapshot>();
    if (_firebaseAuth.auth.currentUser == null) return;
    await users
        .doc(_firebaseAuth.auth.currentUser.uid)
        .collection('friends')
        .get()
        .then((QuerySnapshot querySnapshot) => {
              if (querySnapshot.size > 0)
                {
                  querySnapshot.docs.forEach((doc) {
                    _friendsFetchedFromFirebase.add(doc);
                  })
                }
            })
        .catchError((error) =>
            print("Failed to fetch friends data from Firebase: $error"));
    addFetchedFriendsDataToLocalList(_friendsFetchedFromFirebase);
  }

  void addFetchedFriendsDataToLocalList(
      List<QueryDocumentSnapshot> _friendsFetchedFromFirebase) {
    List<User> newList = List<User>();
    for (int i = 0; i < _friendsFetchedFromFirebase.length; i++) {
      newList.add(User(
          _friendsFetchedFromFirebase[i].get('nickname'),
          _friendsFetchedFromFirebase[i].get('email'),
          _friendsFetchedFromFirebase[i].get('userId')));
    }
    _friendsServiceVM.putFriendsList(newList);
  }

  void fetchFriendRequestsList() async {
    List<QueryDocumentSnapshot> _friendRequestsFetchedFromFirebase =
        List<QueryDocumentSnapshot>();
    if (_firebaseAuth.auth.currentUser == null) return;
    await users
        .doc(_firebaseAuth.auth.currentUser.uid)
        .collection('friendRequests')
        .get()
        .then((QuerySnapshot querySnapshot) => {
              if (querySnapshot.size > 0)
                {
                  querySnapshot.docs.forEach((doc) {
                    _friendRequestsFetchedFromFirebase.add(doc);
                  })
                }
            })
        .catchError((error) => print(
            "Failed to fetch friend requests data from Firebase: $error"));
    addFetchedFriendRequestsDataToLocalList(_friendRequestsFetchedFromFirebase);
  }

  void addFetchedFriendRequestsDataToLocalList(
      List<QueryDocumentSnapshot> _friendRequestsFetchedFromFirebase) {
    List<User> newList = List<User>();
    for (int i = 0; i < _friendRequestsFetchedFromFirebase.length; i++) {
      newList.add(User(
          _friendRequestsFetchedFromFirebase[i].get('nickname'),
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
      'nickname': await _firebaseAuth.currentUserNickname,
      'email': _firebaseAuth.auth.currentUser.email
    });
    _friendsServiceVM.addUserToFriendRequestsList(friendRequestReceiver);
    _friendsServiceVM.removeUserFromUsersList(friendRequestReceiver);
  }

  void acceptFriendRequest(User friendRequestSender) async {
    //Delete user from requests list
    await users
        .doc(_firebaseAuth.auth.currentUser.uid)
        .collection('friendRequests')
        .doc(friendRequestSender.userId)
        .delete();
    //Add user to currentUser's friends list
    await users
        .doc(_firebaseAuth.auth.currentUser.uid)
        .collection('friends')
        .doc(friendRequestSender.userId)
        .set({
      'userId': friendRequestSender.userId,
      'nickname': friendRequestSender.nickname,
      'email': friendRequestSender.email
    });
    //Add currentUser to friendRequestSender's friends list
    await users
        .doc(friendRequestSender.userId)
        .collection('friends')
        .doc(_firebaseAuth.auth.currentUser.uid)
        .set({
      'userId': _firebaseAuth.auth.currentUser.uid,
      'nickname': await _firebaseAuth.currentUserNickname,
      'email': _firebaseAuth.auth.currentUser.email
    });
    _friendsServiceVM.addUserToFriendsList(friendRequestSender);
    _friendsServiceVM.removeUserFromFriendRequestsList(friendRequestSender);
  }

  void declineFriendRequest(User friendRequestSender) async {
    //Delete user from requests list
    await users
        .doc(_firebaseAuth.auth.currentUser.uid)
        .collection('friendRequests')
        .doc(friendRequestSender.userId)
        .delete();
    _friendsServiceVM.removeUserFromFriendRequestsList(friendRequestSender);
  }

  void removeFriendFromFriendsList(User friendToRemove) async {
    //Delete friendToRemove from current user's friends list
    await users
        .doc(_firebaseAuth.auth.currentUser.uid)
        .collection('friends')
        .doc(friendToRemove.userId)
        .delete();
    //Delete current users from friendToRemove's friends list
    await users
        .doc(friendToRemove.userId)
        .collection('friends')
        .doc(_firebaseAuth.auth.currentUser.uid)
        .delete();
    _friendsServiceVM.removeUserFromFriendsList(friendToRemove);
  }

  void giveFriendAccessToYourShoppingList(
      User friend, String documentId) async {
    await users
        .doc(friend.userId)
        .collection('sharedLists')
        .doc(documentId)
        .set({
      'documentId': documentId,
      'ownerId': _firebaseAuth.auth.currentUser.uid,
    });
  }
}
