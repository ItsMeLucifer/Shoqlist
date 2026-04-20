import 'package:flutter/material.dart';
import 'package:shoqlist/constants/app_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shoqlist/main.dart';
import 'package:shoqlist/viewmodels/shopping_lists_view_model.dart';
import 'package:shoqlist/widgets/components/dialogs.dart';
import 'package:shoqlist/l10n/l10n_extension.dart';

class LoyaltyCardButton extends ConsumerWidget {
  final String cardName;
  final bool isFavorite;
  final Color color;
  const LoyaltyCardButton(this.cardName, this.isFavorite, this.color, {super.key});
  @override
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
          ),
        ),
      ),
    );
  }
}

class ShoppingListTypeChangeButton extends ConsumerWidget {
  final String _buttonName;
  final ShoppingListType _shoppingListType;
  final IconData _icon;

  const ShoppingListTypeChangeButton(
    this._buttonName,
    this._shoppingListType,
    this._icon, {
    super.key,
  });

  @override
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
                  style: Theme.of(context).primaryTextTheme.titleLarge?.copyWith(
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
  final IconData? _iconData;

  const BasicButton(
    this._onTap,
    this._buttonName,
    this._percentageOfScreenWidth, [
    this._iconData,
    Key? key,
  ]) : super(key: key);

  @override
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
            color: Theme.of(context).buttonTheme.colorScheme?.surface,
            borderRadius: BorderRadius.circular(25),
          ),
          child: Padding(
            padding: const EdgeInsets.all(5.0),
            child: Center(
              child: _iconData == null
                  ? Text(
                      _buttonName,
                      style: Theme.of(context).primaryTextTheme.labelLarge,
                      textAlign: TextAlign.center,
                    )
                  : Icon(
                      _iconData,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
            ),
          )),
    );
  }
}

class WarningButton extends ConsumerWidget {
  final Function _onTap;
  final String _buttonName;
  final double _percentageOfScreenWidth;

  const WarningButton(
    this._onTap,
    this._buttonName,
    this._percentageOfScreenWidth, {
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenSize = MediaQuery.of(context).size;
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) {
            return YesNoDialog(
                _onTap, context.l10n.deleteAccountMsg);
          },
        );
      },
      child: Container(
        width: screenSize.width * _percentageOfScreenWidth,
        height: 40,
        decoration: BoxDecoration(
            color: Theme.of(context).buttonTheme.colorScheme?.surface,
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
                    Theme.of(context).primaryTextTheme.labelLarge?.fontFamily,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}

class ShoppingListButton extends ConsumerWidget {
  final Function() _onTap;
  final int _index;

  const ShoppingListButton(
    this._onTap,
    this._index, {
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shoppingListsVM = ref.watch(shoppingListsProvider);
    final toolsVM = ref.watch(toolsProvider);
    final screenSize = MediaQuery.of(context).size;

    return GestureDetector(
      onTap: _onTap,
      child: SizedBox(
        height: 60,
        child: Card(
          color: AppColors.surfaceGrayWarm,
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
                    SizedBox(
                      width: screenSize.width * 0.65,
                      child: Text(
                        shoppingListsVM.shoppingLists[_index].name,
                        maxLines: 1,
                        softWrap: false,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).primaryTextTheme.labelLarge,
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
