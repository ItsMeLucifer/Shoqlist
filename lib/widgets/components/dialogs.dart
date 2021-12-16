import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shoqlist/models/shopping_list.dart';

import '../../main.dart';

class DeleteNotification extends ConsumerWidget {
  Function _onPressed;
  String nameOfComponentToDelete;
  BuildContext context;
  DeleteNotification(
      this._onPressed, this.nameOfComponentToDelete, this.context);
  void _onPressDelete() {
    _onPressed(context);
  }

  Widget build(BuildContext context, ScopedReader watch) {
    return AlertDialog(
      content: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Container(
            child: Text("Delete " + nameOfComponentToDelete,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center)),
      ),
      actions: [
        FlatButton(
          onPressed: _onPressDelete,
          child: Text('Yes'),
        ),
        FlatButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text('No'),
        )
      ],
    );
  }
}

class PutShoppingListData extends ConsumerWidget {
  Function _onPressedSave;
  Function _onPressedDelete;
  BuildContext context;
  String _deleteNotificationTitle;
  PutShoppingListData(this._onPressedSave, this.context,
      [this._deleteNotificationTitle = '', this._onPressedDelete]);

  void _onPressSave() {
    _onPressedSave(context);
    Navigator.of(context).pop();
  }

  Widget build(BuildContext context, ScopedReader watch) {
    final toolsVM = watch(toolsProvider);
    return SimpleDialog(children: [
      Container(
        height: 250,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _onPressedDelete == null ? "Add new List" : "Edit List's data",
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
                      hintStyle: TextStyle(
                          color: Color.fromRGBO(
                            0,
                            0,
                            0,
                            0.3,
                          ),
                          fontWeight: FontWeight.bold),
                      contentPadding: EdgeInsets.fromLTRB(20, 10, 20, 10),
                      enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                              width: 1,
                              color: Color.fromRGBO(
                                0,
                                0,
                                0,
                                0.3,
                              ))),
                      focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                              width: 1,
                              color: Color.fromRGBO(
                                0,
                                0,
                                0,
                                1,
                              ))),
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
                  icon: Icon(Icons.keyboard_arrow_down, color: Colors.black),
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
                    color: Color.fromRGBO(0, 0, 0, 0.2),
                    onPressed: _onPressSave,
                    child: Text(
                      'Save',
                    )),
                _onPressedDelete != null
                    ? FlatButton(
                        color: Color.fromRGBO(0, 0, 0, 0.2),
                        onPressed: () {
                          showDialog(
                              context: context,
                              builder: (context) {
                                return DeleteNotification(_onPressedDelete,
                                    _deleteNotificationTitle, context);
                              });
                        },
                        child: Text(
                          'Delete',
                        ))
                    : SizedBox(),
              ],
            )
          ],
        ),
      ),
    ]);
  }
}