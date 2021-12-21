import 'package:flutter/material.dart';
import 'package:shoqlist/models/shopping_list.dart';
import 'package:shoqlist/models/shopping_list_item.dart';
import 'package:shoqlist/utilities/boxes.dart';

enum ShoppingListType { ownShoppingLists, sharedShoppingLists }

class ShoppingListsViewModel extends ChangeNotifier {
  List<ShoppingList> _shoppingLists = [];
  List<ShoppingList> _ownShoppingLists = [];
  List<ShoppingList> _sharedShoppingLists = [];
  List<ShoppingList> get shoppingLists =>
      _currentlyDisplayedListType == ShoppingListType.ownShoppingLists
          ? _ownShoppingLists
          : _sharedShoppingLists;

  String currentUserId = "";

  final _box = Boxes.getShoppingLists();
  final _boxData = Boxes.getDataVariables();

  ShoppingListType _currentlyDisplayedListType =
      ShoppingListType.ownShoppingLists;
  ShoppingListType get currentlyDisplayedListType =>
      _currentlyDisplayedListType;
  set currentlyDisplayedListType(ShoppingListType value) {
    _currentlyDisplayedListType = value;
    notifyListeners();
  }

  void filterDisplayedShoppingLists() {
    _sharedShoppingLists = _shoppingLists.where((shoppingList) {
      return shoppingList.ownerId != currentUserId;
    }).toList();
    _ownShoppingLists = _shoppingLists.where((shoppingList) {
      return shoppingList.ownerId == currentUserId;
    }).toList();
    notifyListeners();
  }

  void overrideShoppingListsLocally(
      List<ShoppingList> lists, int timestamp, String userId) async {
    _shoppingLists = lists;
    currentUserId = userId;
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
    filterDisplayedShoppingLists();
  }

  int getLocalTimestamp() {
    return _boxData.get('timestamp');
  }

  void toggleItemStateLocally(int listIndex, int itemIndex) {
    shoppingLists[listIndex].list[itemIndex].toggleGotItem();
    //HIVE
    shoppingLists[listIndex].save();
    updateLocalTimestamp();
    sortShoppingListItemsDisplay();
    notifyListeners();
  }

  void toggleItemFavoriteLocally(int listIndex, int itemIndex) {
    shoppingLists[listIndex].list[itemIndex].toggleIsFavorite();
    //HIVE
    shoppingLists[listIndex].save();
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
    filterDisplayedShoppingLists();
    //HIVE
    _box.add(newList);
    updateLocalTimestamp();
    notifyListeners();
  }

  void updateExistingShoppingListLocally(
      String name, Importance importance, int index) {
    shoppingLists[index]
      ..importance = importance
      ..name = name;
    //HIVE
    shoppingLists[index].save();
    notifyListeners();
  }

  void addNewItemToShoppingListLocally(
      String itemName, bool itemGot, bool isFavorited) {
    shoppingLists[_currentListIndex]
        .list
        .add(ShoppingListItem(itemName, itemGot, isFavorited));
    //HIVE
    int index = _shoppingLists
        .indexWhere((element) => element == shoppingLists[_currentListIndex]);
    _box.putAt(index, shoppingLists[_currentListIndex]);
    updateLocalTimestamp();
    notifyListeners();
  }

  void deleteItemFromShoppingListLocally(int itemIndex) {
    shoppingLists[_currentListIndex].list.removeAt(itemIndex);
    //HIVE
    shoppingLists[_currentListIndex].save();
    updateLocalTimestamp();
    notifyListeners();
  }

  void deleteShoppingListLocally(int index) {
    shoppingLists.removeAt(index);
    filterDisplayedShoppingLists();
    //HIVE
    int fixedIndex =
        _shoppingLists.indexWhere((element) => element == shoppingLists[index]);
    _box.deleteAt(fixedIndex);
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
    ShoppingList currentShoppingList = shoppingLists[_currentListIndex];
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
    shoppingLists[_currentListIndex].list.sort((a, b) {
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
    return shoppingLists[_currentListIndex].usersWithAccess;
  }

  void addUserIdToUsersWithAccessList(String userId) {
    shoppingLists[_currentListIndex].usersWithAccess.add(userId);
    notifyListeners();
  }
}
