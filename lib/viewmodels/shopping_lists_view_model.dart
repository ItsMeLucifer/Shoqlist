import 'package:flutter/material.dart';
import 'package:shoqlist/models/loyalty_card.dart';
import 'package:shoqlist/models/shopping_list.dart';
import 'package:shoqlist/models/shopping_list_item.dart';

class ShoppingListsViewModel extends ChangeNotifier {
  List<ShoppingList> _shoppingList = [
    ShoppingList(
        "Biedronka",
        [
          ShoppingListItem("Ziemniaki", false, Importance.normal),
          ShoppingListItem("Siemię lniane", false, Importance.important),
          ShoppingListItem("Płatki", false, Importance.important),
          ShoppingListItem("Herbata", false, Importance.important),
          ShoppingListItem("Chleb", false, Importance.important),
          ShoppingListItem("Ziemniaki", false, Importance.important),
          ShoppingListItem("Siemię lniane", false, Importance.important),
          ShoppingListItem("Płatki", false, Importance.important),
          ShoppingListItem("Herbata", false, Importance.important),
          ShoppingListItem("Chleb", false, Importance.important),
          ShoppingListItem("Ziemniaki", false, Importance.urgent),
          ShoppingListItem("Siemię lniane", false, Importance.important),
          ShoppingListItem("Płatki", false, Importance.important),
          ShoppingListItem("Herbata", false, Importance.important),
          ShoppingListItem("Chleb", false, Importance.important),
          ShoppingListItem("Ziemniaki", false, Importance.important),
          ShoppingListItem("Siemię lniane", false, Importance.important),
          ShoppingListItem("Płatki", false, Importance.important),
          ShoppingListItem("Herbata", false, Importance.important),
          ShoppingListItem("Chleb", false, Importance.important),
        ],
        Importance.normal),
    ShoppingList(
        "Rossman",
        [
          ShoppingListItem("Waciki", false, Importance.important),
          ShoppingListItem("Pasta do zębów", false, Importance.normal),
        ],
        Importance.important),
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
          ShoppingListItem("Czarna nić", false, Importance.normal),
        ],
        Importance.low)
  ];
  List<ShoppingList> get shoppingList => _shoppingList;
  List<LoyaltyCard> _loyaltyCardsList = [
    LoyaltyCard("Biedronka", "1243221312"),
    LoyaltyCard("Aushan", "1243221312")
  ];
  List<LoyaltyCard> get loyaltyCardsList => _loyaltyCardsList;

  void toggleItemActivation(int listIndex, int itemIndex) {
    bool gotItem = _shoppingList[listIndex].list[itemIndex].gotItem;
    _shoppingList[listIndex].list[itemIndex].gotItem = !gotItem;
    notifyListeners();
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
