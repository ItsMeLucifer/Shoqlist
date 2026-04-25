import 'package:flutter/material.dart';
import 'package:nanoid/nanoid.dart';
import 'package:shoqlist/models/shopping_list.dart';
import 'package:shoqlist/models/shopping_list_item.dart';
import 'package:shoqlist/models/user.dart';
import 'package:shoqlist/utilities/boxes.dart';
import 'package:collection/collection.dart';
import 'package:shoqlist/viewmodels/sync/pending_writes_tracker.dart';
import 'package:shoqlist/viewmodels/sync/shopping_list_doc.dart';

enum ShoppingListType { ownShoppingLists, sharedShoppingLists }

class ShoppingListsViewModel extends ChangeNotifier {
  final List<ShoppingList> _shoppingLists = [];
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

  void displayLocalShoppingLists(String userId) {
    clearDisplayedData();
    currentUserId = userId;
    _box.toMap().forEach((key, value) {
      _backfillItemIds(value);
      _shoppingLists.add(value);
    });
    filterDisplayedShoppingLists();
  }

  // Backfill id/createdAt oraz per-field timestampów na itemach cached
  // w Hive sprzed tych pól w modelu. Brak id → niestabilny ValueKey
  // w ListView (bug #2/#4). Brak *UpdatedAt → merge bierze null jak 0,
  // więc pierwszy remote snapshot zawsze wygrywa — co jest poprawnie.
  void _backfillItemIds(ShoppingList list) {
    bool dirty = false;
    for (final item in list.list) {
      if (item.id == null) {
        item.id = nanoid();
        dirty = true;
      }
      if (item.createdAt == null) {
        item.createdAt = 0;
        dirty = true;
      }
      if (item.nameUpdatedAt == null) {
        item.nameUpdatedAt = 0;
        dirty = true;
      }
      if (item.stateUpdatedAt == null) {
        item.stateUpdatedAt = 0;
        dirty = true;
      }
      if (item.favoriteUpdatedAt == null) {
        item.favoriteUpdatedAt = 0;
        dirty = true;
      }
    }
    if (list.nameUpdatedAt == null) {
      list.nameUpdatedAt = 0;
      dirty = true;
    }
    if (list.importanceUpdatedAt == null) {
      list.importanceUpdatedAt = 0;
      dirty = true;
    }
    if (list.usersWithAccessUpdatedAt == null) {
      list.usersWithAccessUpdatedAt = 0;
      dirty = true;
    }
    if (list.createdAt == null) {
      list.createdAt = 0;
      dirty = true;
    }
    if (list.updatedAt == null) {
      list.updatedAt = 0;
      dirty = true;
    }
    if (list.schemaVersion == null) {
      list.schemaVersion = 1; // migrowany lazy przez FirestoreMigrator
      dirty = true;
    }
    if (dirty) list.save();
  }

  int indexOfItemById(int listIndex, String? itemId) {
    if (itemId == null) return -1;
    if (!_isValidListIndex(listIndex)) return -1;
    return shoppingLists[listIndex].list.indexWhere((i) => i.id == itemId);
  }

  int indexOfListByDocId(String documentId) {
    return _shoppingLists.indexWhere((l) => l.documentId == documentId);
  }

  /// Dodaje listę lokalnie (wywoływane z snapshot listener gdy przychodzi
  /// nowo udostępniona lista / pierwszy snapshot po bootstrap).
  void addListLocally(ShoppingList list) {
    _shoppingLists.add(list);
    if (_box.length < _shoppingLists.length) _box.add(list);
    filterDisplayedShoppingLists();
  }

  /// Per-field merge lokalnego stanu z serwera.
  ///
  /// Dla każdego pola list-level (name/importance/usersWithAccess) i dla
  /// każdego pola item-level (name/state/favorite) nadpisujemy wartość
  /// TYLKO gdy timestamp serwera jest nowszy od lokalnego. To powala
  /// na prawidłowe łączenie równoczesnych edycji (A zmienia nazwę, B
  /// haczyk tego samego itemu → oba przetrwają).
  ///
  /// `tracker` — jeśli item jest w `touchedItems` (pending write) merge go
  /// pomija; inaczej echo naszego własnego write'u (ze stałym timestampem
  /// równym naszemu) mogłoby wyzerować świeży lokalny follow-up tap
  /// w trakcie tej samej 100ms okna między commit a echo.
  void applyMergedSnapshot(
    ShoppingListDoc remote, {
    required String ownerName,
    required List<User> usersWithAccess,
    required PendingWritesTracker tracker,
  }) {
    final localIdx = indexOfListByDocId(remote.documentId);
    if (localIdx < 0) {
      // Nowa lista — materializujemy z remote + backfill + dodanie.
      final fresh = remote.toShoppingList(ownerName, usersWithAccess);
      _backfillItemIds(fresh);
      _shoppingLists.add(fresh);
      if (_box.length < _shoppingLists.length) _box.add(fresh);
      filterDisplayedShoppingLists();
      return;
    }
    final local = _shoppingLists[localIdx];

    // --- list-level per-field ---
    if (remote.nameUpdatedAt > (local.nameUpdatedAt ?? 0)) {
      local.name = remote.name;
      local.nameUpdatedAt = remote.nameUpdatedAt;
    }
    if (remote.importanceUpdatedAt > (local.importanceUpdatedAt ?? 0)) {
      local.importance = remote.importance;
      local.importanceUpdatedAt = remote.importanceUpdatedAt;
    }
    if (remote.usersWithAccessUpdatedAt >
        (local.usersWithAccessUpdatedAt ?? 0)) {
      local.usersWithAccess = usersWithAccess;
      local.usersWithAccessUpdatedAt = remote.usersWithAccessUpdatedAt;
    }

    // --- item-level per-field ---
    final remoteById = <String, ShoppingListItem>{
      for (final i in remote.items)
        if (i.id != null) i.id!: i
    };

    // Updates + adds (iterate remote)
    for (final remoteItem in remote.items) {
      final id = remoteItem.id!;
      if (tracker.hasPendingFor(remote.documentId, id)) continue;
      final localItem = local.list.firstWhereOrNull((x) => x.id == id);
      // Tombstone: remove local if present, never add.
      if (remoteItem.deletedAt != null) {
        if (localItem != null) local.list.remove(localItem);
        continue;
      }
      if (localItem == null) {
        local.list.add(remoteItem);
        continue;
      }
      if ((remoteItem.nameUpdatedAt ?? 0) > (localItem.nameUpdatedAt ?? 0)) {
        localItem.itemName = remoteItem.itemName;
        localItem.nameUpdatedAt = remoteItem.nameUpdatedAt;
      }
      if ((remoteItem.stateUpdatedAt ?? 0) > (localItem.stateUpdatedAt ?? 0)) {
        localItem.gotItem = remoteItem.gotItem;
        localItem.stateUpdatedAt = remoteItem.stateUpdatedAt;
      }
      if ((remoteItem.favoriteUpdatedAt ?? 0) >
          (localItem.favoriteUpdatedAt ?? 0)) {
        localItem.isFavorite = remoteItem.isFavorite;
        localItem.favoriteUpdatedAt = remoteItem.favoriteUpdatedAt;
      }
    }

    // Local-only items: jeśli brak w remote i NIE jest pending — serwer
    // je usunął (lub nigdy nie widział). Bez tracker-shield trzymanie ich
    // by wskrzeszało skasowane itemy przy każdym snapshot. Z tarczą —
    // jeśli item jest świeżo utworzony i jeszcze nie dojechał do serwera,
    // zostaje.
    local.list.removeWhere((localItem) {
      final id = localItem.id;
      if (id == null) return false;
      if (remoteById.containsKey(id)) return false;
      if (tracker.hasPendingFor(remote.documentId, id)) return false;
      return true;
    });

    local.bumpUpdatedAt();
    local.save();
    if (localIdx == _currentListIndex) sortShoppingListItemsDisplay();
    filterDisplayedShoppingLists();
  }

  void toggleItemStateLocally(int listIndex, int itemIndex) {
    if (!_isValidItemIndex(listIndex, itemIndex)) return;
    // toggleGotItem bumpuje stateUpdatedAt — per-field merge potem to użyje.
    shoppingLists[listIndex].list[itemIndex].toggleGotItem();
    shoppingLists[listIndex].bumpUpdatedAt();
    shoppingLists[listIndex].save();
    updateLocalTimestamp();
    sortShoppingListItemsDisplay();
    notifyListeners();
  }

  void toggleItemFavoriteLocally(int listIndex, int itemIndex) {
    if (!_isValidItemIndex(listIndex, itemIndex)) return;
    shoppingLists[listIndex].list[itemIndex].toggleIsFavorite();
    shoppingLists[listIndex].bumpUpdatedAt();
    shoppingLists[listIndex].save();
    updateLocalTimestamp();
    sortShoppingListItemsDisplay();
    notifyListeners();
  }

  void updateShoppingListItemNameLocally(
      int listIndex, int itemIndex, String newName) {
    if (!_isValidItemIndex(listIndex, itemIndex)) return;
    shoppingLists[listIndex].list[itemIndex].setName(newName);
    shoppingLists[listIndex].bumpUpdatedAt();
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

  /// Zwraca utworzony item — UI przekazuje go dalej do Firestore write.
  /// Id itemu generowane przez konstruktor `ShoppingListItem` (nanoid).
  ShoppingListItem? addNewItemToShoppingListLocally(
      String itemName, bool itemGot, bool isFavorited) {
    if (!_isValidListIndex(_currentListIndex)) return null;
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
    // `_shoppingLists` (race z async merge), wcześniej rzucało RangeError.
    // Teraz bounds-check; state w pamięci już wyszedł przez `notifyListeners()`.
    final boxIndex =
        _shoppingLists.indexWhere((element) => identical(element, target));
    if (boxIndex >= 0 && boxIndex < _box.length) {
      _box.putAt(boxIndex, target);
    }
    target.bumpUpdatedAt();
    updateLocalTimestamp();
    notifyListeners();
    return newItem;
  }

  void deleteItemFromShoppingListLocally(int itemIndex) {
    if (!_isValidItemIndex(_currentListIndex, itemIndex)) return;
    shoppingLists[_currentListIndex].list.removeAt(itemIndex);
    shoppingLists[_currentListIndex].bumpUpdatedAt();
    shoppingLists[_currentListIndex].save();
    updateLocalTimestamp();
    notifyListeners();
  }

  void deleteShoppingListLocally(int index) {
    if (!_isValidListIndex(index)) return;
    final target = shoppingLists[index];
    final fixedIndex = _shoppingLists.indexOf(target);
    if (fixedIndex < 0) return;
    if (fixedIndex < _box.length) _box.deleteAt(fixedIndex);
    _shoppingLists.removeAt(fixedIndex);
    updateLocalTimestamp();
    // Flutter_slidable wymaga by rodzic natychmiast usunął dismissed widget
    // z listy dzieci. Wcześniej usuwaliśmy tylko z _shoppingLists i z widoku
    // filtrowanego przez `shoppingLists.removeAt(index)` — ale _ownShoppingLists
    // / _sharedShoppingLists (faktyczne źródło dla ListView) nie były przebudowane.
    // filterDisplayedShoppingLists() woła notifyListeners().
    filterDisplayedShoppingLists();
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
