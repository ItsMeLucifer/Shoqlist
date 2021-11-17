import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
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

  List<QueryDocumentSnapshot> _shoppingListsFromFetchedFirebase =
      List<QueryDocumentSnapshot>();
  void getShoppingListsFromFirebase(bool shouldUpdateLocalData) async {
    if (_firebaseAuth.auth.currentUser == null) return;
    _shoppingListsFromFetchedFirebase.clear();
    await users
        .doc(_firebaseAuth.auth.currentUser.uid)
        .collection('lists')
        .get()
        .then((QuerySnapshot querySnapshot) => {
              if (querySnapshot.size > 0)
                {
                  querySnapshot.docs.forEach((doc) {
                    _shoppingListsFromFetchedFirebase.add(doc);
                  })
                }
            })
        .catchError(
            (error) => print("Failed to fetch data from Firebase: $error"));
    notifyListeners();
    if (shouldUpdateLocalData) addFetchedDataToLocalList();
  }

  void addFetchedDataToLocalList() {
    List<ShoppingList> temp = [];
    for (int i = 0; i < _shoppingListsFromFetchedFirebase.length; i++) {
      List<ShoppingListItem> items = [];
      for (int j = 0;
          j < _shoppingListsFromFetchedFirebase[i].get('listContent').length;
          j++) {
        items.add(
          ShoppingListItem(
              _shoppingListsFromFetchedFirebase[i].get('listContent')[j],
              _shoppingListsFromFetchedFirebase[i].get('listState')[j],
              _shoppingListsFromFetchedFirebase[i].get('listFavorite')[j]),
        );
      }
      temp.add(ShoppingList(
          _shoppingListsFromFetchedFirebase[i].get('name'),
          items,
          _toolsVM.getImportanceValueFromLabel(
              _shoppingListsFromFetchedFirebase[i].get('importance')),
          _shoppingListsFromFetchedFirebase[i].get('id')));
    }
    _shoppingListsVM.overrideShoppingList(temp);
  }

  void saveNewShoppingListToFirebase(
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
          'listImportance': [],
          'listFavorite': [],
          'timestamp': DateTime.now().millisecondsSinceEpoch,
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
      String documentId) async {
    return await users
        .doc(_firebaseAuth.auth.currentUser.uid)
        .collection('lists')
        .doc(documentId)
        .get();
  }

  void addNewItemToShoppingListOnFirebase(
      String itemName, String documentId) async {
    DocumentSnapshot document;
    try {
      document = await getDocumentSnapshotFromFirebaseWithId(documentId);
    } catch (e) {
      return print(
          "Could not get document from Firebase, error: " + e.code.toString());
    }
    List<dynamic> listContent = document.get('listContent');
    listContent.add(itemName);
    List<dynamic> listState = document.get('listState');
    listState.add(false);
    List<dynamic> listImportance = document.get('listImportance');
    listImportance.add(false);
    List<dynamic> listFavorite = document.get('listFavorite');
    listFavorite.add(false);
    await users
        .doc(_firebaseAuth.auth.currentUser.uid)
        .collection('lists')
        .doc(documentId)
        .update({
          'listContent': listContent,
          'listState': listState,
          'listImportance': listImportance,
          'listFavorite': listFavorite
        })
        .then((value) => print("New item added"))
        .catchError((error) => print("Failed to add new item: $error"));
  }

  void deleteShoppingListItemOnFirebase(
      int itemIndex, String documentId) async {
    DocumentSnapshot document;
    try {
      document = await getDocumentSnapshotFromFirebaseWithId(documentId);
    } catch (e) {
      return print(
          "Could not get document from Firebase, error: " + e.code.toString());
    }
    List<dynamic> listContent = document.get('listContent');
    List<dynamic> listState = document.get('listState');
    List<dynamic> listImportance = document.get('listImportance');
    List<dynamic> listFavorite = document.get('listFavorite');
    listContent.removeAt(itemIndex);
    listState.removeAt(itemIndex);
    listImportance.removeAt(itemIndex);
    listFavorite.removeAt(itemIndex);
    await users
        .doc(_firebaseAuth.auth.currentUser.uid)
        .collection('lists')
        .doc(documentId)
        .update({
          'listContent': listContent,
          'listState': listState,
          'listImportance': listImportance,
          'listFavorite': listFavorite
        })
        .then((value) => print("List item deleted"))
        .catchError((error) => print("Failed to delete item: $error"));
  }

  void toggleStateOfShoppingListItemOnFirebase(
      String documentId, int itemIndex) async {
    DocumentSnapshot document;
    try {
      document = await getDocumentSnapshotFromFirebaseWithId(documentId);
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
      document = await getDocumentSnapshotFromFirebaseWithId(documentId);
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
}
