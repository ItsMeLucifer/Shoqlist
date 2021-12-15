import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shoqlist/models/user.dart';
import 'package:shoqlist/models/loyalty_card.dart';
import 'package:shoqlist/models/shopping_list.dart';
import 'package:shoqlist/models/shopping_list_item.dart';
import 'package:shoqlist/viewmodels/firebase_auth_view_model.dart';
import 'package:shoqlist/viewmodels/loyalty_cards_view_model.dart';
import 'package:shoqlist/viewmodels/shopping_lists_view_model.dart';
import 'package:shoqlist/viewmodels/tools.dart';

class FirebaseViewModel extends ChangeNotifier {
  ShoppingListsViewModel _shoppingListsVM;
  LoyaltyCardsViewModel _loyaltyCardsVM;
  Tools _toolsVM;
  FirebaseAuthViewModel _firebaseAuth;
  FirebaseViewModel(this._shoppingListsVM, this._loyaltyCardsVM, this._toolsVM,
      this._firebaseAuth);

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
            'id': localList.documentId
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
          _shoppingListsFetchedFromFirebase[i].get('id')));
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
          'id': documentId
        })
        .then((value) => print("Created new List"))
        .catchError((error) => print("Failed to create list: $error"));
  }

  void deleteShoppingListOnFirebase(String documentId) async {
    await users
        .doc(_firebaseAuth.auth.currentUser.uid)
        .collection('lists')
        .doc(documentId)
        .delete()
        .then((value) => print("List Deleted"))
        .catchError((error) => print("Failed to delete list: $error"));
  }

  Future<DocumentSnapshot> getDocumentSnapshotFromFirebaseWithId(
      String documentId, String collectionName) async {
    return await users
        .doc(_firebaseAuth.auth.currentUser.uid)
        .collection(collectionName)
        .doc(documentId)
        .get();
  }

  void addNewItemToShoppingListOnFirebase(
      String itemName, String documentId) async {
    DocumentSnapshot document;
    try {
      document =
          await getDocumentSnapshotFromFirebaseWithId(documentId, 'lists');
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
        .doc(_firebaseAuth.auth.currentUser.uid)
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

  void deleteShoppingListItemOnFirebase(
      int itemIndex, String documentId) async {
    DocumentSnapshot document;
    try {
      document =
          await getDocumentSnapshotFromFirebaseWithId(documentId, 'lists');
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
        .doc(_firebaseAuth.auth.currentUser.uid)
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

  void toggleStateOfShoppingListItemOnFirebase(
      String documentId, int itemIndex) async {
    DocumentSnapshot document;
    try {
      document =
          await getDocumentSnapshotFromFirebaseWithId(documentId, 'lists');
    } catch (e) {
      return print(
          "Could not get document from Firebase, error: " + e.code.toString());
    }
    List<dynamic> listState = document.get('listState');
    listState[itemIndex] = !listState[itemIndex];
    await users
        .doc(_firebaseAuth.auth.currentUser.uid)
        .collection('lists')
        .doc(documentId)
        .update({
          'listState': listState,
        })
        .then((value) => print("Changed state of item"))
        .catchError((error) => print("Failed to toggle item's state: $error"));
  }

  void toggleFavoriteOfShoppingListItemOnFirebase(
      String documentId, int itemIndex) async {
    DocumentSnapshot document;
    try {
      document =
          await getDocumentSnapshotFromFirebaseWithId(documentId, 'lists');
    } catch (e) {
      return print(
          "Could not get document from Firebase, error: " + e.code.toString());
    }
    List<dynamic> listFavorite = document.get('listFavorite');
    listFavorite[itemIndex] = !listFavorite[itemIndex];
    await users
        .doc(_firebaseAuth.auth.currentUser.uid)
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

  //--FRIENDS
  List<User> _friendsList = List<User>();
  List<User> get friendsList => _friendsList;

  List<User> _friendRequestsList = List<User>();
  List<User> get friendRequestList => _friendRequestsList;

  List<User> _usersList = List<User>();
  List<User> get usersList => usersList;

  void searchForUser(String input) async {
    input = _toolsVM.deleteAllWhitespacesFromString(input);
    await users.where("email", isEqualTo: input).get().then((querySnapshot) {
      querySnapshot.docs.forEach((document) {
        if (document.get('userId') != _firebaseAuth.auth.currentUser.uid) {
          User _user = User(document.get('nickname'), document.get('email'),
              document.get('userId'));
          _usersList.add(_user);
        }
      });
    });
    notifyListeners();
  }

  void sendFriendRequest(User friendRequestReceiver) async {
    //Check if friendRequestReceiver didnt invite currentUser before
    if (await users
        .doc(_firebaseAuth.auth.currentUser.uid)
        .collection('friendRequests')
        .where('userId', isEqualTo: friendRequestReceiver.userId)
        .get()
        .then((querySnapshot) => querySnapshot.size > 0)) {
      return acceptFriendRequest(friendRequestReceiver);
    }
    //Add current user to friendRequestReceiver's friend requests list
    await users
        .doc(friendRequestReceiver.userId)
        .collection('friendRequests')
        .doc(_firebaseAuth.auth.currentUser.uid)
        .set({
      'userId': _firebaseAuth.auth.currentUser.uid,
      'nickname': _firebaseAuth.currentUserNickname,
      'email': _firebaseAuth.auth.currentUser.email
    });
    notifyListeners();
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
      'nickname': _firebaseAuth.currentUserNickname,
      'email': _firebaseAuth.auth.currentUser.email
    });
    friendRequestList.remove(friendRequestSender);
    friendsList.add(friendRequestSender);
    notifyListeners();
  }

  void declineFriendRequest(User friendRequestSender) async {
    //Delete user from requests list
    await users
        .doc(_firebaseAuth.auth.currentUser.uid)
        .collection('friendRequests')
        .doc(friendRequestSender.userId)
        .delete();
    friendRequestList.remove(friendRequestSender);
    notifyListeners();
  }
}
