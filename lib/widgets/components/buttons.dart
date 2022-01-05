import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shoqlist/main.dart';
import 'package:shoqlist/viewmodels/shopping_lists_view_model.dart';
import 'package:shoqlist/widgets/components/dialogs.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class LoyaltyCardButton extends ConsumerWidget {
  final String cardName;
  final bool isFavorite;
  final Color color;
  LoyaltyCardButton(this.cardName, this.isFavorite, this.color);
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      color: color,
      child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Center(
              child: Stack(
            children: <Widget>[
              Text(cardName,
                  overflow: TextOverflow.fade,
                  softWrap: false,
                  maxLines: 1,
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                      foreground: Paint()
                        ..style = PaintingStyle.stroke
                        ..strokeWidth = 2
                        ..color = Colors.black)),
              Text(cardName,
                  overflow: TextOverflow.fade,
                  softWrap: false,
                  maxLines: 1,
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
  Widget build(BuildContext context, WidgetRef ref) {
    final shoppingListsVM = ref.watch(shoppingListsProvider);
    final screenSize = MediaQuery.of(context).size;
    return GestureDetector(
      onTap: () {
        shoppingListsVM.currentlyDisplayedListType = _shoppingListType;
      },
      child: Container(
          decoration: BoxDecoration(
              color: shoppingListsVM.currentlyDisplayedListType ==
                      _shoppingListType
                  ? Theme.of(context).colorScheme.secondary.withOpacity(0.1)
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
  Widget build(BuildContext context, WidgetRef ref) {
    final screenSize = MediaQuery.of(context).size;
    return GestureDetector(
      onTap: () {
        _onTap(context, ref);
      },
      child: Container(
          width: screenSize.width * _percentageOfScreenWidth,
          height: 40,
          decoration: BoxDecoration(
            color: Theme.of(context).buttonTheme.colorScheme.background,
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
                    : Icon(_iconData,
                        color: Theme.of(context).colorScheme.secondary)),
          )),
    );
  }
}

class WarningButton extends ConsumerWidget {
  final Function _onTap;
  final String _buttonName;
  final double _percentageOfScreenWidth;
  WarningButton(this._onTap, this._buttonName, this._percentageOfScreenWidth);
  Widget build(BuildContext context, WidgetRef ref) {
    final screenSize = MediaQuery.of(context).size;
    return GestureDetector(
      onTap: () {
        showDialog(
            context: context,
            builder: (context) {
              return YesNoDialog(
                  _onTap, AppLocalizations.of(context).deleteAccountMsg);
            });
      },
      child: Container(
          width: screenSize.width * _percentageOfScreenWidth,
          height: 40,
          decoration: BoxDecoration(
              color: Theme.of(context).buttonTheme.colorScheme.background,
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

class ShoppingListButton extends ConsumerWidget {
  final Function _onTap;
  final Function _onLongPress;
  final int _index;
  ShoppingListButton(this._onTap, this._onLongPress, this._index);
  Widget build(BuildContext context, WidgetRef ref) {
    final shoppingListsVM = ref.watch(shoppingListsProvider);
    final toolsVM = ref.watch(toolsProvider);
    final screenSize = MediaQuery.of(context).size;
    return Container(
      height: 60,
      child: GestureDetector(
        onTap: () {
          _onTap(context, _index, ref);
        },
        onLongPress: () {
          _onLongPress(context, _index, ref);
        },
        child: Card(
            color: toolsVM.getImportanceColor(
                shoppingListsVM.shoppingLists[_index].importance),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: screenSize.width * 0.5,
                    child: Text(
                      shoppingListsVM.shoppingLists[_index].name,
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.fade,
                      style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 20),
                    ),
                  ),
                  Row(
                    children: [
                      shoppingListsVM.shoppingLists[_index].list.length != 0
                          ? Container(
                              width: screenSize.width * 0.28,
                              child: Text(
                                shoppingListsVM.shoppingLists[_index].list[0]
                                        .itemName +
                                    "${shoppingListsVM.shoppingLists[_index].list.length > 1 ? ', ...' : ''}",
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                                style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.normal,
                                    fontSize: 15),
                                textAlign: TextAlign.end,
                              ),
                            )
                          : Container(),
                      Text(
                        "   [" +
                            shoppingListsVM.shoppingLists[_index].list.length
                                .toString() +
                            "]",
                        style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 15),
                      ),
                    ],
                  ),
                ],
              ),
            )),
      ),
    );
  }
}
