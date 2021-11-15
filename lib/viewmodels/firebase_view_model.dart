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
  void getShoppingListsFromFirebase() async {
    if (_firebaseAuth.auth.currentUser == null) return;
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
            });
    addFetchedDataToLocalList();
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
              _toolsVM.getImportanceValueFromLabel(
                  _shoppingListsFromFetchedFirebase[i]
                      .get('listImportance')[j])),
        );
      }
      temp.add(ShoppingList(
          _shoppingListsFromFetchedFirebase[i].get('name'),
          items,
          _toolsVM.getImportanceValueFromLabel(
              _shoppingListsFromFetchedFirebase[i].get('importance'))));
    }
    _shoppingListsVM.overrideShoppingList(temp);
  }

  void saveNewShoppingListToFirebase(String name, Importance importance) async {
    if (_firebaseAuth.auth.currentUser == null) return;
    users.doc(_firebaseAuth.auth.currentUser.uid).collection('lists').add({
      'name': name,
      'importance': _toolsVM.getImportanceLabel(importance),
      'listContent': [],
      'listState': [],
    });
  }
}
