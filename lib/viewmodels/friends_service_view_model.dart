import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shoqlist/models/user.dart';

class FriendsServiceViewModel extends ChangeNotifier {
  List<User> _friendsList = [];
  List<User> get friendsList => _friendsList;

  List<User> _friendRequestsList = [];
  List<User> get friendRequestsList => _friendRequestsList;

  List<User> _usersList = [];
  List<User> get usersList => _usersList;

  void clearUsersList() {
    _usersList.clear();
  }

  void putFriendsList(List<User> newList) {
    _friendsList = newList;
    notifyListeners();
  }

  void putFriendRequestsList(List<User> newList) {
    _friendRequestsList = newList;
    notifyListeners();
  }

  void putUsersList(List<User> newList) {
    _usersList = newList;
    notifyListeners();
  }

  void removeUserFromFriendsList(User user) {
    _friendsList.remove(user);
    notifyListeners();
  }

  void removeUserFromFriendRequestsList(User user) {
    _friendRequestsList.remove(user);
    notifyListeners();
  }

  void removeUserFromUsersList(User user) {
    _usersList.remove(user);
    notifyListeners();
  }

  void addUserToFriendsList(User user) {
    _friendsList.add(user);
    notifyListeners();
  }

  void addUserToFriendRequestsList(User user) {
    _friendRequestsList.add(user);
    notifyListeners();
  }

  int _currentUserIndex;
  int get currentUserIndex => _currentUserIndex;
  set currentUserIndex(int newUserIndex) {
    _currentUserIndex = newUserIndex;
    notifyListeners();
  }

  TextEditingController searchFriendTextController = TextEditingController();
  void clearSearchFriendTextController() {
    searchFriendTextController.clear();
    notifyListeners();
  }

  List<User> getFriendsWithoutAccessToCurrentShoppingList(
      List<User> usersWithAccess) {
    List<User> result = List.from(_friendsList);
    usersWithAccess.forEach((userWA) {
      _friendsList.forEach((friend) {
        if (userWA.userId == friend.userId) result.remove(friend);
      });
    });
    return result;
  }
  // List<User> getFriendsWithoutAccessToCurrentShoppingList(
  //     List<User> usersWithAccess) {
  //   List<User> result =
  //       _friendsList.where((user) => !usersWithAccess.contains(user)).toList();
  //   return result;
  // }
}
