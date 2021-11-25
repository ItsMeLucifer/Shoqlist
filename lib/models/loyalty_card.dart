import 'package:flutter/material.dart';

class LoyaltyCard {
  String name;
  String barCode;
  bool isFavorite;
  String documentId;
  Color color;
  LoyaltyCard(
      this.name, this.barCode, this.isFavorite, this.documentId, this.color);
  void toggleIsFavorite() {
    isFavorite = !isFavorite;
  }
}
