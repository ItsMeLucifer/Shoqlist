import 'package:flutter/material.dart';
import 'package:shoqlist/models/shopping_list.dart';

class ShoppingListsViewModel extends ChangeNotifier {
  List<ShoppingList> _shoppingList = [
    ShoppingList(
        "Biedronka",
        [
          Item("Ziemniaki", false, Importance.normal),
          Item("Siemię lniane", false, Importance.important),
          Item("Płatki", false, Importance.important),
          Item("Herbata", false, Importance.important),
          Item("Chleb", false, Importance.important),
          Item("Ziemniaki", false, Importance.important),
          Item("Siemię lniane", false, Importance.important),
          Item("Płatki", false, Importance.important),
          Item("Herbata", false, Importance.important),
          Item("Chleb", false, Importance.important),
          Item("Ziemniaki", false, Importance.urgent),
          Item("Siemię lniane", false, Importance.important),
          Item("Płatki", false, Importance.important),
          Item("Herbata", false, Importance.important),
          Item("Chleb", false, Importance.important),
          Item("Ziemniaki", false, Importance.important),
          Item("Siemię lniane", false, Importance.important),
          Item("Płatki", false, Importance.important),
          Item("Herbata", false, Importance.important),
          Item("Chleb", false, Importance.important),
        ],
        Importance.normal),
    ShoppingList(
        "Rossman",
        [
          Item("Waciki", false, Importance.important),
          Item("Pasta do zębów", false, Importance.normal),
        ],
        Importance.important),
    ShoppingList(
        "Komputerowy",
        [
          Item("Karta Graficzna", false, Importance.urgent),
        ],
        Importance.urgent),
    ShoppingList(
        "Krawiec",
        [
          Item("Naszywka", false, Importance.small),
          Item("Czarna nić", false, Importance.normal),
        ],
        Importance.small)
  ];
  List<ShoppingList> get shoppingList => _shoppingList;

  void toggleItemActivation(int listIndex, int itemIndex) {
    bool gotItem = _shoppingList[listIndex].list[itemIndex].gotItem;
    _shoppingList[listIndex].list[itemIndex].gotItem = !gotItem;
    notifyListeners();
  }

  int _currentListIndex = 0;
  int get currentListIndex => _currentListIndex;
  set currentListIndex(int value) {
    _currentListIndex = value;
    notifyListeners();
  }
}
