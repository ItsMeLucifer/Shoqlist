import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shoqlist/main.dart';
import 'package:shoqlist/viewmodels/shopping_lists_view_model.dart';
import 'package:shoqlist/widgets/components/dialogs.dart';

class LoyaltyCardButton extends ConsumerWidget {
  final String cardName;
  final bool isFavorite;
  final Color color;
  LoyaltyCardButton(this.cardName, this.isFavorite, this.color);
  Widget build(BuildContext context, ScopedReader watch) {
    return Card(
      color: !context.read(toolsProvider).darkMode
          ? color
          : Color.lerp(color, Colors.black, 0.4),
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
          decoration: BoxDecoration(
              color: shoppingListsVM.currentlyDisplayedListType ==
                      _shoppingListType
                  ? Theme.of(context).accentColor.withOpacity(0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(5)),
          width: screenSize.width * 0.45,
          child: Center(
            child: Text(_buttonName,
                textAlign: TextAlign.center,
                style: Theme.of(context).primaryTextTheme.headline6),
          )),
    );
  }
}

///[_percentageOfScreenWidth] is what width of the screen this button should occupy.
///The value is given in the range from 0 - 1.
///Example: 60 percent of the screen width is [0.6].
class BasicButton extends ConsumerWidget {
  final Function _onTap;
  final String _buttonName;
  final double _percentageOfScreenWidth;
  final IconData _iconData;
  BasicButton(this._onTap, this._buttonName, this._percentageOfScreenWidth,
      [this._iconData]);
  Widget build(BuildContext context, ScopedReader watch) {
    final screenSize = MediaQuery.of(context).size;
    return GestureDetector(
      onTap: () {
        _onTap(context);
      },
      child: Container(
          width: screenSize.width * _percentageOfScreenWidth,
          height: 40,
          decoration: BoxDecoration(
            color: Theme.of(context).buttonColor,
            borderRadius: BorderRadius.circular(5),
          ),
          child: Padding(
            padding: const EdgeInsets.all(5.0),
            child: Center(
                child: _iconData == null
                    ? Text(
                        _buttonName,
                        style: Theme.of(context).primaryTextTheme.button,
                        textAlign: TextAlign.center,
                      )
                    : Icon(_iconData, color: Theme.of(context).accentColor)),
          )),
    );
  }
}

class WarningButton extends ConsumerWidget {
  final Function _onTap;
  final String _buttonName;
  final double _percentageOfScreenWidth;
  WarningButton(this._onTap, this._buttonName, this._percentageOfScreenWidth);
  Widget build(BuildContext context, ScopedReader watch) {
    final screenSize = MediaQuery.of(context).size;
    return GestureDetector(
      onTap: () {
        showDialog(
            context: context,
            builder: (context) {
              return YesNoDialog(_onTap,
                  'Are you sure you want to delete your account?\n\nThis change will be irreversible.');
            });
      },
      child: Container(
          width: screenSize.width * _percentageOfScreenWidth,
          height: 40,
          decoration: BoxDecoration(
              color: Theme.of(context).buttonColor,
              borderRadius: BorderRadius.circular(5),
              border: Border.all(color: Colors.red, width: 2)),
          child: Padding(
            padding: const EdgeInsets.all(5.0),
            child: Center(
              child: Text(
                _buttonName,
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                  fontFamily:
                      Theme.of(context).primaryTextTheme.button.fontFamily,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          )),
    );
  }
}
