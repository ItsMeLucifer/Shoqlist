import 'package:flutter/material.dart';
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
      String cardName, String barCode, String documentId) {
    _loyaltyCardsList.add(LoyaltyCard(cardName, barCode, false, documentId));
    notifyListeners();
  }

  void overrideLoyaltyCardsListLocally(List<LoyaltyCard> newLoyaltyCardsList) {
    _loyaltyCardsList = newLoyaltyCardsList;
    notifyListeners();
  }
}
