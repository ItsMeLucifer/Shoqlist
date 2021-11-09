import 'package:flutter/material.dart';
import 'package:shoqlist/models/shopping_list.dart';

class ShoppingListsViewModel extends ChangeNotifier {
  List<ShoppingList> shoppingList = [
    ShoppingList(
        "Biedronka",
        ["Ziemniaki", "Siemię Lniane", "Płatki", "Herbata", "Chleb"],
        Importance.normal),
    ShoppingList("Rossman", ["Waciki", "Pasta do zębów"], Importance.important),
    ShoppingList("Komputerowy", ["Karta Graficzna"], Importance.urgent)
  ];
}
