import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shoqlist/models/shopping_list.dart';
import 'package:shoqlist/models/user.dart';
import 'package:shoqlist/widgets/components/forms.dart';
import 'package:shoqlist/widgets/social/users_list.dart';
import '../../main.dart';
import '../color_picker.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';

class YesNoDialog extends ConsumerWidget {
  final Function _onAccepted;
  final String _titleToDisplay;
  final Function _onDeclined;
  YesNoDialog(this._onAccepted, this._titleToDisplay, [this._onDeclined]);

  Widget build(BuildContext context, ScopedReader watch) {
    return AlertDialog(
      backgroundColor: Theme.of(context).backgroundColor,
      content: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Container(
            child: Text(_titleToDisplay,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center)),
      ),
      actions: [
        FlatButton(
          onPressed: () {
            _onAccepted(context);
          },
          child: Text(_onDeclined == null ? 'Yes' : 'Accept'),
        ),
        FlatButton(
          onPressed: () {
            if (_onDeclined == null) {
              Navigator.of(context).pop();
            } else {
              _onDeclined(context);
            }
          },
          child: Text(_onDeclined == null ? 'No' : 'Decline'),
        )
      ],
    );
  }
}

class PutShoppingListData extends ConsumerWidget {
  final Function _onPressedSave;
  final Function _onPressedDelete;
  final BuildContext context;
  final String _deleteNotificationTitle;
  PutShoppingListData(this._onPressedSave, this.context,
      [this._deleteNotificationTitle = '', this._onPressedDelete]);

  Widget build(BuildContext context, ScopedReader watch) {
    final toolsVM = watch(toolsProvider);
    return SimpleDialog(
        backgroundColor: Theme.of(context).backgroundColor,
        children: [
          Container(
            height: 250,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _onPressedDelete == null
                      ? "Add new List"
                      : "Edit List's data",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 210,
                      child: TextFormField(
                        key: toolsVM.newListNameFormFieldKey,
                        keyboardType: TextInputType.name,
                        autofocus: false,
                        autocorrect: false,
                        obscureText: false,
                        controller: toolsVM.newListNameController,
                        style: TextStyle(fontWeight: FontWeight.bold),
                        decoration: InputDecoration(
                          hintText: "List name",
                          hintStyle:
                              Theme.of(context).primaryTextTheme.bodyText2,
                          contentPadding: EdgeInsets.fromLTRB(20, 10, 20, 10),
                          enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                  width: 1,
                                  color: Theme.of(context).primaryColorDark)),
                          focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                  width: 1,
                                  color: Theme.of(context).accentColor)),
                        ),
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Text("Importance:"),
                    DropdownButton<Importance>(
                      value: toolsVM.newListImportance,
                      dropdownColor: Theme.of(context).backgroundColor,
                      focusColor: Theme.of(context).disabledColor,
                      icon:
                          Icon(Icons.keyboard_arrow_down, color: Colors.black),
                      iconSize: 24,
                      elevation: 16,
                      underline: Container(
                        height: 2,
                        color: Colors.white,
                      ),
                      onChanged: (Importance imp) {
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
                            toolsVM.getImportanceLabel(value),
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
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
                    FlatButton(
                        color: Theme.of(context).buttonColor,
                        onPressed: () {
                          _onPressedSave(context);
                          Navigator.of(context).pop();
                        },
                        child: Text('Save',
                            style:
                                Theme.of(context).primaryTextTheme.bodyText1)),
                    _onPressedDelete != null
                        ? FlatButton(
                            color: Theme.of(context).buttonColor,
                            onPressed: () {
                              showDialog(
                                  context: context,
                                  builder: (context) {
                                    return YesNoDialog(_onPressedDelete,
                                        _deleteNotificationTitle);
                                  });
                            },
                            child: Text('Remove',
                                style: Theme.of(context)
                                    .primaryTextTheme
                                    .bodyText1))
                        : SizedBox(),
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
  final String _titleToDisplay;
  ChooseUser(this._actionAfterTapUser, this._usersList, this._titleToDisplay);

  Widget build(BuildContext context, ScopedReader watch) {
    var size = MediaQuery.of(context).size;
    return AlertDialog(
      backgroundColor: Theme.of(context).backgroundColor,
      scrollable: true,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text("Choose User",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center),
          SizedBox(height: 10),
          _usersList.isNotEmpty
              ? Container(
                  height: size.height * 0.6,
                  width: size.width * 0.9,
                  child: UsersList(_actionAfterTapUser, _usersList,
                      _titleToDisplay, null, 0.4))
              : Text(
                  "You have no friends or every one of your friends already has access.",
                  style: Theme.of(context).primaryTextTheme.bodyText1,
                  textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class ChangeName extends ConsumerWidget {
  final Function _onAccepted;
  final String _titleToDisplay;
  ChangeName(this._onAccepted, this._titleToDisplay);
  Widget build(BuildContext context, ScopedReader watch) {
    final toolsVM = watch(toolsProvider);
    final screenSize = MediaQuery.of(context).size;
    return AlertDialog(
      backgroundColor: Theme.of(context).backgroundColor,
      content: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Container(
          height: screenSize.height * 0.15,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                  child: Text(_titleToDisplay,
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center)),
              BasicForm(TextInputType.name, toolsVM.newNicknameController,
                  'Nickname', () => {}, Icons.person, false)
            ],
          ),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Container(
            height: screenSize.height * 0.02,
            child: FlatButton(
              onPressed: () {
                _onAccepted(context);
                Navigator.of(context).pop();
              },
              child: Text('Save'),
            ),
          ),
        ),
      ],
    );
  }
}

class PutLoyaltyCardsData extends ConsumerWidget {
  final Function _onPressed;
  final String _title;
  final Function _onDestroy;
  final String _removeTitle;
  PutLoyaltyCardsData(this._onPressed, this._title,
      [this._onDestroy, this._removeTitle]);
  Widget build(BuildContext context, ScopedReader watch) {
    final toolsVM = watch(toolsProvider);
    const double _alertDialogWidth = 250;
    const double _dividerHeight = 10;
    Widget _suffixIcon = GestureDetector(
      onTap: () async {
        toolsVM.loyaltyCardBarCodeController.text =
            await FlutterBarcodeScanner.scanBarcode(
                "#ff6666", "Cancel", true, ScanMode.DEFAULT);
        if (toolsVM.loyaltyCardBarCodeController.text == '-1')
          toolsVM.loyaltyCardBarCodeController.text = '';
      },
      child: Icon(Icons.qr_code, color: Theme.of(context).accentColor),
    );
    return SimpleDialog(
        backgroundColor: Theme.of(context).backgroundColor,
        children: [
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Container(
                height: 320,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _title,
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: _dividerHeight),
                    BasicForm(
                        TextInputType.name,
                        toolsVM.loyaltyCardNameController,
                        'Card name',
                        (value) => {},
                        null,
                        false),
                    SizedBox(height: _dividerHeight),
                    ColorPicker(_alertDialogWidth, 100),
                    SizedBox(height: _dividerHeight),
                    BasicForm(
                        TextInputType.text,
                        toolsVM.loyaltyCardBarCodeController,
                        'Card code',
                        (value) => {},
                        null,
                        false,
                        _suffixIcon),
                    SizedBox(height: _dividerHeight),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _onDestroy != null
                            ? Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: FlatButton(
                                    color: Theme.of(context).buttonColor,
                                    onPressed: () {
                                      showDialog(
                                          context: context,
                                          builder: (context) {
                                            return YesNoDialog(
                                                _onDestroy, _removeTitle);
                                          });
                                    },
                                    child: Text(
                                      'Remove',
                                      style: Theme.of(context)
                                          .primaryTextTheme
                                          .bodyText1,
                                    )),
                              )
                            : Container(),
                        FlatButton(
                            color: Theme.of(context).buttonColor,
                            onPressed: () {
                              _onPressed(context);
                            },
                            child: Text(
                              _onDestroy != null ? 'Save' : 'Add',
                              style:
                                  Theme.of(context).primaryTextTheme.bodyText1,
                            )),
                      ],
                    ),
                  ],
                )),
          ),
        ]);
  }
}
