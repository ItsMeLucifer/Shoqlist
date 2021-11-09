import 'package:flutter/material.dart';
import 'package:shoqlist/models/shopping_list.dart';

class ShoppingListsViewModel extends ChangeNotifier {
  List<ShoppingList> shoppingList = [
    ShoppingList(
        "Biedronka",
        ["Ziemniaki", "Siemię lniane", "Płatki", "Herbata", "Chleb"],
        Importance.normal),
    ShoppingList("Rossman", ["Waciki", "Pasta do zębów"], Importance.important),
    ShoppingList("Komputerowy", ["Karta graficzna"], Importance.urgent),
    ShoppingList("Krawiec", ["Naszywka", "Czarna nić"], Importance.small)
  ];
  int _currentListIndex = 0;
  int get currentListIndex => _currentListIndex;
  set currentListIndex(int value) {
    _currentListIndex = value;
    notifyListeners();
  }
}
