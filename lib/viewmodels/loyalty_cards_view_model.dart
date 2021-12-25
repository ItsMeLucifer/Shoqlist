import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:shoqlist/models/loyalty_card.dart';

class LoyaltyCardsViewModel extends ChangeNotifier {
  List<LoyaltyCard> _loyaltyCardsList = [];
  List<LoyaltyCard> get loyaltyCardsList => _loyaltyCardsList;
  int _currentLoyaltyCardsListIndex = 0;
  int get currentLoyaltyCardsListIndex => _currentLoyaltyCardsListIndex;
  set currentLoyaltyCardsListIndex(int index) {
    _currentLoyaltyCardsListIndex = index;
    notifyListeners();
  }

  void addNewLoyaltyCardLocally(
      String cardName, String barCode, String documentId, int colorValue) {
    _loyaltyCardsList.add(
        LoyaltyCard(cardName, barCode, false, documentId, Color(colorValue)));
    notifyListeners();
  }

  void overrideLoyaltyCardsListLocally(List<LoyaltyCard> newLoyaltyCardsList) {
    _loyaltyCardsList = newLoyaltyCardsList;
    sortLoyaltyCardsListLocally();
    notifyListeners();
  }

  void deleteLoyaltyCardLocally(int index) {
    _loyaltyCardsList.removeAt(index);
    notifyListeners();
  }

  void toggleLoyaltyCardFavoriteLocally() {
    _loyaltyCardsList[_currentLoyaltyCardsListIndex].toggleIsFavorite();
    notifyListeners();
  }

  List<Color> _loyaltyCardsColorsToPick = [
    Colors.red[300],
    Colors.blue[300],
    Colors.white,
    Colors.purple[300],
    Colors.pink[300],
    Colors.teal[300],
    Colors.green[300],
    Colors.cyan[300],
    Colors.brown[300],
    Colors.orange[600]
  ];
  List<Color> get loyaltyCardsColorsToPick => _loyaltyCardsColorsToPick;
  void sortLoyaltyCardsListLocally() {
    loyaltyCardsList.sort((a, b) {
      if (a.isFavorite && !b.isFavorite) {
        return -1;
      }
      if (!a.isFavorite && b.isFavorite) {
        return 1;
      }
      return 0;
    });
  }
}
