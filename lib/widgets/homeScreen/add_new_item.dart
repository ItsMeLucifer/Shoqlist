import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shoqlist/main.dart';
import 'package:shoqlist/models/shopping_list.dart';

class AddNewItem extends ConsumerWidget {
  Widget build(BuildContext context, ScopedReader watch) {
    TextEditingController nameController;
    final shoppingListsVM = watch(shoppingListsProvider);
    final toolsVM = watch(toolsProvider);
    return AlertDialog(
      content: Container(
          height: 300,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Add new Item",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              Container(
                height: 200,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 200,
                          height: 40,
                          child: TextFormField(
                            keyboardType: TextInputType.name,
                            autofocus: false,
                            autocorrect: false,
                            obscureText: false,
                            controller: nameController,
                            style: TextStyle(fontWeight: FontWeight.bold),
                            decoration: InputDecoration(
                              hintText: "Item name",
                              hintStyle: TextStyle(
                                  color: Color.fromRGBO(
                                    0,
                                    0,
                                    0,
                                    0.3,
                                  ),
                                  fontWeight: FontWeight.bold),
                              contentPadding:
                                  EdgeInsets.fromLTRB(20, 10, 20, 10),
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
                    DropdownButton<Importance>(
                      value: toolsVM.newItemImportance,
                      icon:
                          Icon(Icons.keyboard_arrow_down, color: Colors.black),
                      iconSize: 24,
                      elevation: 16,
                      underline: Container(
                        height: 2,
                        color: Colors.white,
                      ),
                      onChanged: (Importance imp) {
                        toolsVM.newItemImportance = imp;
                      },
                      items: <Importance>[
                        Importance.small,
                        Importance.normal,
                        Importance.important,
                        Importance.urgent
                      ].map<DropdownMenuItem<Importance>>((Importance value) {
                        return DropdownMenuItem<Importance>(
                          value: value,
                          child: Text(
                            value.toString(),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              FlatButton(
                  color: Color.fromRGBO(0, 0, 0, 0.2),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    'Add',
                  )),
            ],
          )),
    );
  }
}
