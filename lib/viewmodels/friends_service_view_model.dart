import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shoqlist/models/user.dart';

class FriendsServiceViewModel extends ChangeNotifier {
  List<User> _friendsList = List<User>();
  List<User> get friendsList => _friendsList;

  List<User> _friendRequestsList = List<User>();
  List<User> get friendRequestsList => _friendRequestsList;

  List<User> _usersList = List<User>();
  List<User> get usersList => _usersList;

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

  int _currentUserIndex;
  int get currentUserIndex => _currentUserIndex;
  set currentUserIndex(int newUserIndex) {
    _currentUserIndex = newUserIndex;
    notifyListeners();
  }

  List<User> _currentUsersList = List<User>();
  List<User> get currentUsersList => _currentUsersList;
  void setCurrentUsersListToDisplay(List<User> newList) {
    _currentUsersList = newList;
    notifyListeners();
  }

  TextEditingController searchFriendTextController = TextEditingController();
  void clearSearchFriendTextController() {
    searchFriendTextController.clear();
    notifyListeners();
  }
}
