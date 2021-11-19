import 'package:flutter/material.dart';
import 'package:shoqlist/models/shopping_list.dart';
import 'package:shoqlist/models/shopping_list_item.dart';

class ShoppingListsViewModel extends ChangeNotifier {
  List<ShoppingList> _shoppingList = [];
  List<ShoppingList> get shoppingList => _shoppingList;

  void overrideShoppingListLocally(List<ShoppingList> list) {
    _shoppingList = list;
  }

  void toggleItemStateLocally(int listIndex, int itemIndex) {
    _shoppingList[listIndex].list[itemIndex].toggleGotItem();
    notifyListeners();
  }

  void toggleItemFavoriteLocally(int listIndex, int itemIndex) {
    _shoppingList[listIndex].list[itemIndex].toggleIsFavorite();
    notifyListeners();
  }

  void saveNewShoppingListLocally(
      String name, Importance importance, String documentId) {
    _shoppingList.add(ShoppingList(name, [], importance, documentId));
    //SAVE IT TO THE LOCAL DATABASE
    notifyListeners();
  }

  void addNewItemToShoppingListLocally(
      String itemName, bool itemGot, bool isFavorited) {
    _shoppingList[_currentListIndex]
        .list
        .add(ShoppingListItem(itemName, itemGot, isFavorited));
    notifyListeners();
  }

  void deleteItemFromShoppingListLocally(int itemIndex) {
    _shoppingList[_currentListIndex].list.removeAt(itemIndex);
    notifyListeners();
  }

  void deleteShoppingListLocally(int index) {
    _shoppingList.removeAt(index);
    notifyListeners();
  }

  int _currentListIndex = 0;
  int get currentListIndex => _currentListIndex;
  set currentListIndex(int value) {
    _currentListIndex = value;
    notifyListeners();
  }

  int _pickedListItemIndex = 0;
  int get pickedListItemIndex => _pickedListItemIndex;
  set pickedListItemIndex(int value) {
    _pickedListItemIndex = value;
    notifyListeners();
  }
}
