import 'package:flutter/material.dart';
import 'package:shoqlist/models/shopping_list.dart';
import 'package:shoqlist/models/shopping_list_item.dart';

class ShoppingListsViewModel extends ChangeNotifier {
  List<ShoppingList> _shoppingList = [];
  List<ShoppingList> get shoppingList => _shoppingList;

  void overrideShoppingList(List<ShoppingList> list) {
    _shoppingList = list;
  }

  void toggleItemActivation(int listIndex, int itemIndex) {
    bool gotItem = _shoppingList[listIndex].list[itemIndex].gotItem;
    _shoppingList[listIndex].list[itemIndex].gotItem = !gotItem;
    notifyListeners();
  }

  void saveNewShoppingListLocally(
      String name, Importance importance, String documentId) {
    _shoppingList.add(ShoppingList(name, [], importance, documentId));
    //SAVE IT TO THE LOCAL DATABASE
  }

  void addNewItemToShoppingListLocally(
      String itemName, bool itemGot, bool isFavorited) {
    _shoppingList[_currentListIndex]
        .list
        .add(ShoppingListItem(itemName, itemGot, isFavorited));
    notifyListeners();
  }

  void deleteListLocally(int index) {
    _shoppingList.removeAt(index);
  }

  int _currentListIndex = 0;
  int get currentListIndex => _currentListIndex;
  set currentListIndex(int value) {
    _currentListIndex = value;
    notifyListeners();
  }
}
