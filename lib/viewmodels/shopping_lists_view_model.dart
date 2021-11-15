import 'package:flutter/material.dart';
import 'package:shoqlist/models/shopping_list.dart';
import 'package:shoqlist/models/shopping_list_item.dart';

class ShoppingListsViewModel extends ChangeNotifier {
  List<ShoppingList> _shoppingList = [
    ShoppingList(
        "Komputerowy",
        [
          ShoppingListItem("Karta Graficzna", false, Importance.urgent),
        ],
        Importance.urgent),
    ShoppingList(
        "Krawiec",
        [
          ShoppingListItem("Naszywka", false, Importance.low),
        ],
        Importance.low)
  ];
  List<ShoppingList> get shoppingList => _shoppingList;

  void toggleItemActivation(int listIndex, int itemIndex) {
    bool gotItem = _shoppingList[listIndex].list[itemIndex].gotItem;
    _shoppingList[listIndex].list[itemIndex].gotItem = !gotItem;
    notifyListeners();
  }

  void addNewShoppingList(ShoppingList list) {
    _shoppingList.add(list);
  }

  void addNewItemToShoppingList(
      String itemName, bool itemGot, Importance importance) {
    _shoppingList[_currentListIndex]
        .list
        .add(ShoppingListItem(itemName, itemGot, importance));
    notifyListeners();
  }

  int _currentListIndex = 0;
  int get currentListIndex => _currentListIndex;
  set currentListIndex(int value) {
    _currentListIndex = value;
    notifyListeners();
  }
}
