import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shoqlist/main.dart';
import 'package:shoqlist/models/shopping_list.dart';

class AddNewItem extends ConsumerWidget {
  Widget build(BuildContext context, ScopedReader watch) {
    final shoppingListsVM = watch(shoppingListsProvider);
    final toolsVM = watch(toolsProvider);
    final firebaseVM = watch(firebaseProvider);
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
                            key: toolsVM.addNewItemNameFormFieldKey,
                            keyboardType: TextInputType.name,
                            autofocus: false,
                            autocorrect: false,
                            obscureText: false,
                            controller: toolsVM.nameController,
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
                  ],
                ),
              ),
              FlatButton(
                  color: Color.fromRGBO(0, 0, 0, 0.2),
                  onPressed: () {
                    if (toolsVM.nameController.text != "") {
                      //ADD ITEM TO FIREBASE
                      firebaseVM.addNewItemToShoppingListOnFirebase(
                          toolsVM.nameController.text,
                          shoppingListsVM
                              .shoppingList[shoppingListsVM.currentListIndex]
                              .documentId);
                      //ADD ITEM LOCALLY
                      shoppingListsVM.addNewItemToShoppingListLocally(
                          toolsVM.nameController.text, false, false);
                    }

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
