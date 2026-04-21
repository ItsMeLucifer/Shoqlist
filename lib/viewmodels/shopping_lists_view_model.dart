import 'package:flutter/material.dart';
import 'package:shoqlist/models/shopping_list.dart';
import 'package:shoqlist/models/shopping_list_item.dart';
import 'package:shoqlist/models/user.dart';
import 'package:shoqlist/utilities/boxes.dart';
import 'package:collection/collection.dart';

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
    sortShoppingListsDisplay();
    notifyListeners();
  }

  void clearDisplayedData() {
    _shoppingLists.clear();
    _ownShoppingLists.clear();
    _sharedShoppingLists.clear();
    notifyListeners();
  }

  bool _isValidListIndex(int index) =>
      index >= 0 && index < shoppingLists.length;

  bool _isValidItemIndex(int listIndex, int itemIndex) =>
      _isValidListIndex(listIndex) &&
      itemIndex >= 0 &&
      itemIndex < shoppingLists[listIndex].list.length;

  void updateCurrentShoppingList(ShoppingList newList) {
    if (!_isValidListIndex(_currentListIndex)) return;
    shoppingLists[_currentListIndex] = newList;
    sortShoppingListItemsDisplay();
    notifyListeners();
  }

  void filterDisplayedShoppingLists() {
    _sharedShoppingLists = _shoppingLists.where((shoppingList) {
      return shoppingList.ownerId != currentUserId;
    }).toList();
    _ownShoppingLists = _shoppingLists.where((shoppingList) {
      return shoppingList.ownerId == currentUserId;
    }).toList();
    sortShoppingListsDisplay();
    notifyListeners();
  }

  void overrideShoppingListsLocally(
      List<ShoppingList> lists, int timestamp, String userId) async {
    clearDisplayedData();
    _shoppingLists = lists;
    currentUserId = userId;
    filterDisplayedShoppingLists();
    //HIVE
    await _box.clear();
    _box.addAll(lists);
    _boxData.put('timestamp', timestamp);
  }

  List<ShoppingList> getLocalShoppingList() {
    List<ShoppingList> lists = [];
    _box.toMap().forEach((key, value) {
      lists.add(value);
    });
    return lists;
  }

  void displayLocalShoppingLists(String userId) {
    clearDisplayedData();
    currentUserId = userId;
    _box.toMap().forEach((key, value) {
      _shoppingLists.add(value);
    });
    filterDisplayedShoppingLists();
  }

  int? getLocalTimestamp() {
    return _boxData.get('timestamp');
  }

  void toggleItemStateLocally(int listIndex, int itemIndex) {
    if (!_isValidItemIndex(listIndex, itemIndex)) return;
    shoppingLists[listIndex].list[itemIndex].toggleGotItem();
    shoppingLists[listIndex].save();
    updateLocalTimestamp();
    sortShoppingListItemsDisplay();
    notifyListeners();
  }

  void toggleItemFavoriteLocally(int listIndex, int itemIndex) {
    if (!_isValidItemIndex(listIndex, itemIndex)) return;
    shoppingLists[listIndex].list[itemIndex].toggleIsFavorite();
    shoppingLists[listIndex].save();
    updateLocalTimestamp();
    sortShoppingListItemsDisplay();
    notifyListeners();
  }

  void updateShoppingListItemNameLocally(
      int listIndex, int itemIndex, String newName) {
    if (!_isValidItemIndex(listIndex, itemIndex)) return;
    shoppingLists[listIndex].list[itemIndex].itemName = newName;
    shoppingLists[listIndex].save();
    updateLocalTimestamp();
    notifyListeners();
  }

  void removeSharedListLocally(String documentId) {
    _shoppingLists.removeWhere((l) => l.documentId == documentId);
    filterDisplayedShoppingLists();
    updateLocalTimestamp();
    notifyListeners();
  }

  void saveNewShoppingListLocally(
      String name, Importance importance, String documentId) {
    final ShoppingList newList = ShoppingList(
        name, [], importance, documentId, currentUserId, 'You', []);
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
    if (!_isValidListIndex(_currentListIndex)) return;
    final target = shoppingLists[_currentListIndex];
    final firstGotItem =
        target.list.firstWhereOrNull((element) => element.gotItem);
    final newItem = ShoppingListItem(itemName, itemGot, isFavorited);
    if (firstGotItem != null) {
      target.list.insert(target.list.indexOf(firstGotItem), newItem);
    } else {
      target.list.add(newItem);
    }
    // HIVE persistence: best-effort. Gdy `_box` desync'uje się z
    // `_shoppingLists` (race z async `overrideShoppingListsLocally`), wcześniej
    // rzucało RangeError i blokowało UI update. Teraz bounds-check, a przy
    // niepowodzeniu state w pamięci i tak już wyszedł z `notifyListeners()`.
    final boxIndex =
        _shoppingLists.indexWhere((element) => identical(element, target));
    if (boxIndex >= 0 && boxIndex < _box.length) {
      _box.putAt(boxIndex, target);
    }
    updateLocalTimestamp();
    notifyListeners();
  }

  void deleteItemFromShoppingListLocally(int itemIndex) {
    if (!_isValidItemIndex(_currentListIndex, itemIndex)) return;
    shoppingLists[_currentListIndex].list.removeAt(itemIndex);
    shoppingLists[_currentListIndex].save();
    updateLocalTimestamp();
    notifyListeners();
  }

  void deleteShoppingListLocally(int index) {
    if (!_isValidListIndex(index)) return;
    int fixedIndex =
        _shoppingLists.indexWhere((element) => element == shoppingLists[index]);
    if (fixedIndex < 0) return;
    _box.deleteAt(fixedIndex);
    _shoppingLists.removeAt(fixedIndex);
    updateLocalTimestamp();
    shoppingLists.removeAt(index);
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

  static const _strikeCombiner = '\u{0336}';

  String _formatItem(ShoppingListItem item) {
    final capitalized =
        item.itemName.isEmpty ? '' : item.itemName[0].toUpperCase() + item.itemName.substring(1);
    final name = item.gotItem
        ? capitalized.split('').join(_strikeCombiner) + _strikeCombiner
        : item.itemName;
    final prefix = item.gotItem ? '▣ ' : '▢ ';
    final star = item.isFavorite ? ' ★' : '';
    return '$prefix$name$star';
  }

  String getCurrentShoppingListDataInString() {
    if (!_isValidListIndex(_currentListIndex)) return '';
    final list = shoppingLists[_currentListIndex];
    final buffer = StringBuffer()
      ..writeln('🛒 ${list.name} list:')
      ..writeln('__________');
    for (final item in list.list) {
      buffer.writeln(_formatItem(item));
    }
    return buffer.toString();
  }

  void sortShoppingListItemsDisplay() {
    if (!_isValidListIndex(_currentListIndex)) return;
    shoppingLists[_currentListIndex].list.sort((a, b) {
      if (a.gotItem) return 1;
      if (b.gotItem) return -1;
      if (a.isFavorite && !b.isFavorite) return -1;
      if (!a.isFavorite && b.isFavorite) return 1;
      return 0;
    });
  }

  void sortShoppingListsDisplay() {
    shoppingLists.sort((a, b) {
      if (a.importance.index < b.importance.index) {
        return 1;
      }
      if (a.importance.index > b.importance.index) {
        return -1;
      }
      return 0;
    });
  }

  List<User> getUsersWithAccessToCurrentList() {
    if (!_isValidListIndex(_currentListIndex)) return const [];
    return shoppingLists[_currentListIndex].usersWithAccess;
  }

  void addUserToUsersWithAccessList(User user) {
    if (user.userId == currentUserId) return;
    if (!_isValidListIndex(_currentListIndex)) return;
    shoppingLists[_currentListIndex].usersWithAccess.add(user);
    notifyListeners();
  }

  void removeUserFromUsersWithAccessList(User user) {
    if (user.userId == currentUserId) return;
    if (!_isValidListIndex(_currentListIndex)) return;
    shoppingLists[_currentListIndex].usersWithAccess.remove(user);
    notifyListeners();
  }
}
