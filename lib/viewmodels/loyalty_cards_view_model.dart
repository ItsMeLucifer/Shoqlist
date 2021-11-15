import 'package:flutter/material.dart';
import 'package:shoqlist/models/loyalty_card.dart';

class LoyaltyCardsViewModel extends ChangeNotifier {
  List<LoyaltyCard> _loyaltyCardsList = [
    LoyaltyCard("Payback", "0480404624192"),
    LoyaltyCard("Orsay", "000000005040008629"),
    LoyaltyCard("Biedronka", "000000005040008629")
  ];
  List<LoyaltyCard> get loyaltyCardsList => _loyaltyCardsList;
  int _currentLoyaltyCardsListIndex = 0;
  int get currentLoyaltyCardsListIndex => _currentLoyaltyCardsListIndex;
  set currentLoyaltyCardsListIndex(int index) {
    _currentLoyaltyCardsListIndex = index;
    notifyListeners();
  }

  void addNewLoyaltyCard(String cardName, String barCode) {
    _loyaltyCardsList.add(LoyaltyCard(cardName, barCode));
    notifyListeners();
  }
}
