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
  final IconData _icon;
  ShoppingListTypeChangeButton(
      this._buttonName, this._shoppingListType, this._icon);
  Widget build(BuildContext context, WidgetRef ref) {
    final shoppingListsVM = ref.watch(shoppingListsProvider);
    final screenSize = MediaQuery.of(context).size;
    return GestureDetector(
      onTap: () {
        shoppingListsVM.currentlyDisplayedListType = _shoppingListType;
      },
      child: Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: shoppingListsVM.currentlyDisplayedListType ==
                        _shoppingListType
                    ? Theme.of(context).colorScheme.secondary
                    : Theme.of(context).disabledColor,
                width: shoppingListsVM.currentlyDisplayedListType ==
                        _shoppingListType
                    ? 2
                    : 1,
              ),
            ),
          ),
          width: screenSize.width * 0.5,
          child: Center(
            child: Column(
              children: [
                Icon(_icon,
                    size: 30,
                    color: shoppingListsVM.currentlyDisplayedListType ==
                            _shoppingListType
                        ? Theme.of(context).colorScheme.secondary
                        : Theme.of(context).disabledColor),
                SizedBox(height: 5),
                Text(
                  _buttonName,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).primaryTextTheme.headline6.copyWith(
                      color: shoppingListsVM.currentlyDisplayedListType ==
                              _shoppingListType
                          ? Theme.of(context).colorScheme.secondary
                          : Theme.of(context).disabledColor),
                ),
                SizedBox(height: 8),
              ],
            ),
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
            borderRadius: BorderRadius.circular(25),
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
      key: UniqueKey(),
      child: GestureDetector(
        onTap: () {
          _onTap(context, _index, ref);
        },
        onLongPress: () {
          _onLongPress(context, _index, ref);
        },
        child: Card(
          color: Color.fromRGBO(237, 236, 243, 1),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    SizedBox(
                      width: screenSize.width * 0.1,
                      child: CircleAvatar(
                        backgroundColor: toolsVM.getImportanceColor(
                            shoppingListsVM.shoppingLists[_index].importance),
                        foregroundColor: Colors.white,
                        child: Icon(
                          Icons.list,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      width: screenSize.width * 0.65,
                      child: Text(
                        shoppingListsVM.shoppingLists[_index].name,
                        maxLines: 1,
                        softWrap: false,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).primaryTextTheme.button,
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  width: screenSize.width * 0.08,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        shoppingListsVM.shoppingLists[_index].list.length
                            .toString(),
                        style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 15),
                      ),
                      Icon(Icons.arrow_forward_ios,
                          color: Theme.of(context).disabledColor, size: 12)
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
