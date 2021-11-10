import 'package:flutter/material.dart';
import 'package:shoqlist/models/shopping_list.dart';

class ShoppingListsViewModel extends ChangeNotifier {
  List<ShoppingList> shoppingList = [
    ShoppingList(
        "Biedronka",
        [
          Item("Ziemniaki", false),
          Item("Siemię lniane", false),
          Item("Płatki", false),
          Item("Herbata", false),
          Item("Chleb", false),
          Item("Ziemniaki", false),
          Item("Siemię lniane", false),
          Item("Płatki", false),
          Item("Herbata", false),
          Item("Chleb", false),
          Item("Ziemniaki", false),
          Item("Siemię lniane", false),
          Item("Płatki", false),
          Item("Herbata", false),
          Item("Chleb", false),
          Item("Ziemniaki", false),
          Item("Siemię lniane", false),
          Item("Płatki", false),
          Item("Herbata", false),
          Item("Chleb", false),
        ],
        Importance.normal),
    ShoppingList(
        "Rossman",
        [
          Item("Waciki", false),
          Item("Pasta do zębów", false),
        ],
        Importance.important),
    ShoppingList(
        "Komputerowy",
        [
          Item("Karta Graficzna", false),
        ],
        Importance.urgent),
    ShoppingList(
        "Krawiec",
        [
          Item("Naszywka", false),
          Item("Czarna nić", false),
        ],
        Importance.small)
  ];
  int _currentListIndex = 0;
  int get currentListIndex => _currentListIndex;
  set currentListIndex(int value) {
    _currentListIndex = value;
    notifyListeners();
  }
}
