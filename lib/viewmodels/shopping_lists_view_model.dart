import 'package:flutter/material.dart';
import 'package:shoqlist/models/shopping_list.dart';
import 'package:shoqlist/models/shopping_list_item.dart';
import 'package:shoqlist/utilities/boxes.dart';

enum ShoppingListType { ownShoppingLists, sharedShoppingLists }

class ShoppingListsViewModel extends ChangeNotifier {
  List<ShoppingList> _shoppingLists = [];
  List<ShoppingList> _shoppingListsFiltered = [];
  List<ShoppingList> get shoppingLists => _shoppingListsFiltered;

  String currentUserId;

  final _box = Boxes.getShoppingLists();
  final _boxData = Boxes.getDataVariables();

  ShoppingListType _currentlyDisplayedListType =
      ShoppingListType.ownShoppingLists;
  ShoppingListType get currentlyDisplayedListType =>
      _currentlyDisplayedListType;
  set currentlyDisplayedListType(ShoppingListType value) {
    _currentlyDisplayedListType = value;
    filterDisplayedShoppingLists();
  }

  void filterDisplayedShoppingLists() {
    _shoppingListsFiltered = _shoppingLists.where((shoppingList) {
      if (_currentlyDisplayedListType == ShoppingListType.ownShoppingLists) {
        return shoppingList.ownerId == currentUserId;
      }
      return shoppingList.ownerId != currentUserId;
    }).toList();
    notifyListeners();
  }

  void overrideShoppingListLocally(
      List<ShoppingList> lists, int timestamp) async {
    _shoppingLists = lists;
    filterDisplayedShoppingLists();
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
    sortShoppingListItemsDisplay();
    notifyListeners();
  }

  void toggleItemFavoriteLocally(int listIndex, int itemIndex) {
    _shoppingLists[listIndex].list[itemIndex].toggleIsFavorite();
    //HIVE
    _shoppingLists[listIndex].save();
    updateLocalTimestamp();
    sortShoppingListItemsDisplay();
    notifyListeners();
  }

  void saveNewShoppingListLocally(
      String name, Importance importance, String documentId,
      [String ownerId]) {
    final ShoppingList newList =
        ShoppingList(name, [], importance, documentId, ownerId);
    _shoppingLists.add(newList);
    //HIVE
    _box.add(newList);
    updateLocalTimestamp();
    notifyListeners();
  }

  void updateExistingShoppingListLocally(
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

  String getCurrentShoppingListDataInString() {
    String result = "";
    ShoppingList currentShoppingList = _shoppingLists[_currentListIndex];
    result += "🛒 " + currentShoppingList.name + " list:\n";
    result += "__________\n";
    for (int i = 0; i < currentShoppingList.list.length; i++) {
      String item = "";
      if (currentShoppingList.list[i].gotItem) {
        item += "▣ ";
        for (int j = 0; j < currentShoppingList.list[i].itemName.length; j++) {
          item += (j == 0
                  ? currentShoppingList.list[i].itemName[j].toUpperCase()
                  : currentShoppingList.list[i].itemName[j]) +
              '\u{0336}';
        }
      } else {
        item = "▢ " + currentShoppingList.list[i].itemName;
      }
      result +=
          item + (currentShoppingList.list[i].isFavorite ? " ★" : "") + "\n";
    }
    return result;
  }

  void sortShoppingListItemsDisplay() {
    _shoppingLists[_currentListIndex].list.sort((a, b) {
      if (a.gotItem) return 1;
      if (b.gotItem) return -1;
      if (a.isFavorite && !b.isFavorite) {
        return -1;
      }
      if (!a.isFavorite && b.isFavorite) {
        return 1;
      }
      return 0;
    });
  }

  List<String> getUsersWithAccessToCurrentList() {
    return _shoppingLists[_currentListIndex].usersWithAccess;
  }

  void addUserIdToUsersWithAccessList(String userId) {
    _shoppingLists[_currentListIndex].usersWithAccess.add(userId);
    notifyListeners();
  }
}
