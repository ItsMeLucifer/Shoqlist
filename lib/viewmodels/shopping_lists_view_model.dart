import 'package:flutter/material.dart';
import 'package:shoqlist/models/shopping_list.dart';
import 'package:shoqlist/models/shopping_list_item.dart';
import 'package:shoqlist/utilities/boxes.dart';

class ShoppingListsViewModel extends ChangeNotifier {
  List<ShoppingList> _shoppingLists = [];
  List<ShoppingList> get shoppingLists => _shoppingLists;
  final _box = Boxes.getShoppingLists();
  final _boxData = Boxes.getDataVariables();

  void overrideShoppingListLocally(
      List<ShoppingList> lists, int timestamp) async {
    _shoppingLists = lists;
    //HIVE
    await _box.clear();
    _box.addAll(lists);
    _boxData.put('timestamp', timestamp);
  }

  List<ShoppingList> getLocalShoppingList() {
    List<ShoppingList> lists = List<ShoppingList>();
    _box.toMap().forEach((key, value) {
      lists.add(value);
    });
    return lists;
  }

  void displayLocalShoppingLists() {
    _box.toMap().forEach((key, value) {
      _shoppingLists.add(value);
    });
  }

  int getLocalTimestamp() {
    return _boxData.get('timestamp');
  }

  void toggleItemStateLocally(int listIndex, int itemIndex) {
    _shoppingLists[listIndex].list[itemIndex].toggleGotItem();
    //HIVE
    _shoppingLists[listIndex].save();
    updateLocalTimestamp();
    notifyListeners();
  }

  void toggleItemFavoriteLocally(int listIndex, int itemIndex) {
    _shoppingLists[listIndex].list[itemIndex].toggleIsFavorite();
    //HIVE
    _shoppingLists[listIndex].save();
    updateLocalTimestamp();
    notifyListeners();
  }

  void saveNewShoppingListLocally(
      String name, Importance importance, String documentId) {
    final ShoppingList newList = ShoppingList(name, [], importance, documentId);
    _shoppingLists.add(newList);
    //HIVE
    _box.add(newList);
    updateLocalTimestamp();
    notifyListeners();
  }

  void updateExistingShoppingList(
      String name, Importance importance, int index) {
    _shoppingLists[index]
      ..importance = importance
      ..name = name;
    //HIVE
    _shoppingLists[index].save();
    notifyListeners();
  }

  void addNewItemToShoppingListLocally(
      String itemName, bool itemGot, bool isFavorited) {
    _shoppingLists[_currentListIndex]
        .list
        .add(ShoppingListItem(itemName, itemGot, isFavorited));
    //HIVE
    _box.putAt(_currentListIndex, _shoppingLists[_currentListIndex]);
    updateLocalTimestamp();
    notifyListeners();
  }

  void deleteItemFromShoppingListLocally(int itemIndex) {
    _shoppingLists[_currentListIndex].list.removeAt(itemIndex);
    //HIVE
    _shoppingLists[_currentListIndex].save();
    updateLocalTimestamp();
    notifyListeners();
  }

  void deleteShoppingListLocally(int index) {
    _shoppingLists.removeAt(index);
    //HIVE
    _box.deleteAt(index);
    updateLocalTimestamp();
    notifyListeners();
  }

  void updateLocalTimestamp() {
    _boxData.put('timestamp', DateTime.now().millisecondsSinceEpoch);
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
