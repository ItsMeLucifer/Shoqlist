import 'package:flutter/cupertino.dart';
import 'package:shoqlist/models/user.dart';

class FriendsServiceViewModel extends ChangeNotifier {
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
}
