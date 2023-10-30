import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shoqlist/models/shopping_list.dart';
import 'package:shoqlist/models/user.dart';
import 'package:shoqlist/widgets/components/buttons.dart';
import 'package:shoqlist/widgets/components/forms.dart';
import 'package:shoqlist/widgets/social/users_list.dart';
import '../../main.dart';
import '../color_picker.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class YesNoDialog extends ConsumerWidget {
  final Function _onAccepted;
  final String _titleToDisplay;
  final Function? _onDeclined;
  YesNoDialog(
    this._onAccepted,
    this._titleToDisplay, [
    this._onDeclined,
  ]);

  Widget build(BuildContext context, WidgetRef ref) {
    return AlertDialog(
      backgroundColor: Theme.of(context).colorScheme.background,
      content: Padding(
        padding: const EdgeInsets.only(top: 8.0, left: 8.0, right: 8.0),
        child: Container(
            child: Text(_titleToDisplay,
                style: Theme.of(context).primaryTextTheme.titleLarge,
                textAlign: TextAlign.center)),
      ),
      actions: [
        TextButton(
          onPressed: () {
            if (_onDeclined == null) {
              return Navigator.of(context).pop();
            }
            _onDeclined!(context, ref);
          },
          child: Text(_onDeclined == null
              ? AppLocalizations.of(context)!.no
              : AppLocalizations.of(context)!.decline),
        ),
        TextButton(
          onPressed: () {
            _onAccepted(context, ref);
          },
          child: Text(_onDeclined == null
              ? AppLocalizations.of(context)!.yes
              : AppLocalizations.of(context)!.accept),
        ),
      ],
    );
  }
}

class PutShoppingListData extends ConsumerWidget {
  final Function _onPressedSave;
  final Function? _onPressedDelete;
  final BuildContext context;
  final String _deleteNotificationTitle;
  PutShoppingListData(
    this._onPressedSave,
    this.context, [
    this._deleteNotificationTitle = '',
    this._onPressedDelete,
  ]);

  Widget build(BuildContext context, WidgetRef ref) {
    final toolsVM = ref.watch(toolsProvider);
    return SimpleDialog(
        backgroundColor: Theme.of(context).colorScheme.background,
        children: [
          const SizedBox(height: 10.0),
          Container(
            height: 250,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _onPressedDelete == null
                      ? AppLocalizations.of(context)!.newListTitle
                      : AppLocalizations.of(context)!.editListTitle,
                  style: Theme.of(context).primaryTextTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 210,
                      child: BasicForm(
                        key: toolsVM.newListNameFormFieldKey,
                        keyboardType: TextInputType.name,
                        controller: toolsVM.newListNameController,
                        hintText: AppLocalizations.of(context)!.listName,
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.importance + ":",
                      style: Theme.of(context).primaryTextTheme.titleLarge,
                    ),
                    DropdownButton<Importance>(
                      value: toolsVM.newListImportance,
                      dropdownColor: Theme.of(context).colorScheme.background,
                      focusColor: Theme.of(context).disabledColor,
                      icon:
                          Icon(Icons.keyboard_arrow_down, color: Colors.black),
                      iconSize: 24,
                      elevation: 16,
                      underline: Container(
                        height: 2,
                        color: Colors.white,
                      ),
                      onChanged: (Importance? imp) {
                        if (imp == null) return;
                        toolsVM.newListImportance = imp;
                      },
                      items: <Importance>[
                        Importance.low,
                        Importance.normal,
                        Importance.important,
                        Importance.urgent
                      ].map<DropdownMenuItem<Importance>>((Importance value) {
                        return DropdownMenuItem<Importance>(
                          value: value,
                          child: Text(
                              toolsVM.getTranslatedImportanceLabel(
                                  context, value),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                      color: toolsVM.getImportanceColor(value)),
                              textAlign: TextAlign.center),
                        );
                      }).toList(),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: _onPressedDelete != null
                      ? MainAxisAlignment.spaceEvenly
                      : MainAxisAlignment.center,
                  children: [
                    _onPressedDelete != null
                        ? Card(
                            color: Theme.of(context)
                                .buttonTheme
                                .colorScheme
                                ?.background,
                            child: TextButton(
                              onPressed: () {
                                showDialog(
                                    context: context,
                                    builder: (context) {
                                      return YesNoDialog(_onPressedDelete!,
                                          _deleteNotificationTitle);
                                    });
                              },
                              child: Text(
                                AppLocalizations.of(context)!.remove,
                                style: Theme.of(context)
                                    .primaryTextTheme
                                    .bodyLarge,
                              ),
                            ),
                          )
                        : SizedBox(),
                    Card(
                      color:
                          Theme.of(context).buttonTheme.colorScheme!.background,
                      child: TextButton(
                        onPressed: () {
                          _onPressedSave(context, ref);
                          Navigator.of(context).pop();
                        },
                        child: Text(AppLocalizations.of(context)!.save,
                            style:
                                Theme.of(context).primaryTextTheme.bodyLarge),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ]);
  }
}

class ChooseUser extends ConsumerWidget {
  final Function _actionAfterTapUser;
  final List<User> _usersList;
  final String _titleToDisplayAfterTapUser;
  final String _dialogTitle;
  final String _noContentMsg;

  ChooseUser(
    this._actionAfterTapUser,
    this._usersList,
    this._titleToDisplayAfterTapUser,
    this._dialogTitle,
    this._noContentMsg,
  );

  Widget build(BuildContext context, WidgetRef ref) {
    var size = MediaQuery.of(context).size;
    return AlertDialog(
      backgroundColor: Theme.of(context).colorScheme.background,
      scrollable: true,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_dialogTitle,
              style: Theme.of(context).primaryTextTheme.headlineSmall,
              textAlign: TextAlign.center),
          SizedBox(height: 10),
          _usersList.isNotEmpty
              ? Container(
                  height: size.height * 0.6,
                  width: size.width * 0.9,
                  child: UsersList(
                    _actionAfterTapUser,
                    _usersList,
                    _titleToDisplayAfterTapUser,
                    null,
                    0.4,
                  ),
                )
              : Text(
                  _noContentMsg,
                  style: Theme.of(context).primaryTextTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
        ],
      ),
    );
  }
}

class ChangeName extends ConsumerWidget {
  final Function _onAccepted;
  final String _titleToDisplay;

  ChangeName(this._onAccepted, this._titleToDisplay);

  Widget build(BuildContext context, WidgetRef ref) {
    final toolsVM = ref.watch(toolsProvider);
    final screenSize = MediaQuery.of(context).size;
    return AlertDialog(
      backgroundColor: Theme.of(context).colorScheme.background,
      content: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Container(
          height: screenSize.height * 0.15,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                child: Text(
                  _titleToDisplay,
                  style: Theme.of(context).primaryTextTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
              ),
              BasicForm(
                keyboardType: TextInputType.name,
                controller: toolsVM.newNicknameController,
                hintText: AppLocalizations.of(context)!.nickname,
                onChanged: (BuildContext context, WidgetRef ref) => {},
                prefixIcon: Icons.person,
              )
            ],
          ),
        ),
      ),
      actions: [
        Padding(
            padding: const EdgeInsets.only(bottom: 8.0, right: 8),
            child: BasicButton(
                _onAccepted, AppLocalizations.of(context)!.save, .2)),
      ],
    );
  }
}

class PutLoyaltyCardsData extends ConsumerWidget {
  final Function _onPressed;
  final String _title;
  final Function? _onDestroy;
  final String? _removeTitle;

  PutLoyaltyCardsData(
    this._onPressed,
    this._title, [
    this._onDestroy,
    this._removeTitle,
  ]);

  Widget build(BuildContext context, WidgetRef ref) {
    final toolsVM = ref.watch(toolsProvider);
    const double _alertDialogWidth = 250;
    const double _dividerHeight = 15;
    Widget _suffixIcon = GestureDetector(
      onTap: () async {
        toolsVM.loyaltyCardBarCodeController.text =
            await FlutterBarcodeScanner.scanBarcode(
          "#ff6666",
          AppLocalizations.of(context)!.cancel,
          true,
          ScanMode.DEFAULT,
        );
        if (toolsVM.loyaltyCardBarCodeController.text == '-1')
          toolsVM.loyaltyCardBarCodeController.text = '';
      },
      child:
          Icon(Icons.qr_code, color: Theme.of(context).colorScheme.secondary),
    );
    return SimpleDialog(
        backgroundColor: Theme.of(context).colorScheme.background,
        children: [
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _title,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: _dividerHeight * 2),
                BasicForm(
                  keyboardType: TextInputType.name,
                  controller: toolsVM.loyaltyCardNameController,
                  hintText: AppLocalizations.of(context)!.cardName,
                ),
                SizedBox(height: _dividerHeight),
                ColorPicker(_alertDialogWidth, 100),
                SizedBox(height: _dividerHeight),
                BasicForm(
                  keyboardType: TextInputType.text,
                  controller: toolsVM.loyaltyCardBarCodeController,
                  hintText: AppLocalizations.of(context)!.cardCode,
                  suffixIcon: _suffixIcon,
                ),
                SizedBox(height: _dividerHeight),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _onDestroy != null
                        ? Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: Card(
                              color: Theme.of(context)
                                  .buttonTheme
                                  .colorScheme
                                  ?.background,
                              child: TextButton(
                                onPressed: () {
                                  showDialog(
                                      context: context,
                                      builder: (context) {
                                        return YesNoDialog(
                                          _onDestroy!,
                                          _removeTitle!,
                                        );
                                      });
                                },
                                child: Text(
                                  AppLocalizations.of(context)!.remove,
                                  style: Theme.of(context)
                                      .primaryTextTheme
                                      .bodyLarge,
                                ),
                              ),
                            ),
                          )
                        : Container(),
                    Card(
                      color:
                          Theme.of(context).buttonTheme.colorScheme?.background,
                      child: TextButton(
                          onPressed: () {
                            _onPressed(context, ref);
                          },
                          child: Text(
                            _onDestroy != null
                                ? AppLocalizations.of(context)!.save
                                : AppLocalizations.of(context)!.add,
                            style: Theme.of(context).primaryTextTheme.bodyLarge,
                          )),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ]);
  }
}
