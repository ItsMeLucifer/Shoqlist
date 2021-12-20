import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shoqlist/main.dart';
import 'package:shoqlist/viewmodels/shopping_lists_view_model.dart';

class LoyaltyCardButton extends ConsumerWidget {
  final String cardName;
  final bool isFavorite;
  final Color color;
  LoyaltyCardButton(this.cardName, this.isFavorite, this.color);
  Widget build(BuildContext context, ScopedReader watch) {
    return Card(
      color: color,
      child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Center(
              child: Stack(
            children: <Widget>[
              Text(cardName,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                      foreground: Paint()
                        ..style = PaintingStyle.stroke
                        ..strokeWidth = 2
                        ..color = Colors.black)),
              Text(cardName,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isFavorite ? Colors.yellow : Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  )),
            ],
          ))),
    );
  }
}

class ShoppingListTypeChangeButton extends ConsumerWidget {
  final String _buttonName;
  final ShoppingListType _shoppingListType;
  ShoppingListTypeChangeButton(this._buttonName, this._shoppingListType);
  Widget build(BuildContext context, ScopedReader watch) {
    final shoppingListsVM = watch(shoppingListsProvider);
    final screenSize = MediaQuery.of(context).size;
    return GestureDetector(
      onTap: () {
        shoppingListsVM.currentlyDisplayedListType = _shoppingListType;
      },
      child: Container(
          width: screenSize.width * 0.45,
          color: shoppingListsVM.currentlyDisplayedListType == _shoppingListType
              ? Color.fromRGBO(0, 0, 0, 0.1)
              : Colors.transparent,
          child: Center(
            child: Text(_buttonName,
                textAlign: TextAlign.center,
                style: Theme.of(context).primaryTextTheme.headline6),
          )),
    );
  }
}
