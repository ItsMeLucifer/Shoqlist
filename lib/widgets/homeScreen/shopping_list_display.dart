import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:shoqlist/main.dart';
import 'package:shoqlist/models/shopping_list.dart';
import 'package:shoqlist/widgets/homeScreen/add_new_item.dart';

class ShoppingListDisplay extends ConsumerWidget {
  Widget build(BuildContext context, ScopedReader watch) {
    final shoppingListsVM = watch(shoppingListsProvider);
    final toolsVM = watch(toolsProvider);

    return Scaffold(
      backgroundColor: Color.lerp(
          toolsVM.getImportanceColor(shoppingListsVM
              .shoppingList[shoppingListsVM.currentListIndex].importance),
          Colors.black,
          0.15),
      floatingActionButton: SpeedDial(
        overlayOpacity: 0,
        animatedIcon: AnimatedIcons.menu_close,
        backgroundColor:
            Theme.of(context).floatingActionButtonTheme.backgroundColor,
        children: [
          SpeedDialChild(
              onTap: () {
                showDialog(
                    context: context,
                    builder: (context) {
                      return AddNewItem();
                    });
              },
              backgroundColor:
                  Theme.of(context).floatingActionButtonTheme.backgroundColor,
              child: Icon(Icons.add),
              label: "Add item"),
          SpeedDialChild(
              child: Icon(Icons.add),
              backgroundColor:
                  Theme.of(context).floatingActionButtonTheme.backgroundColor,
              label: "Edit details")
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                SizedBox(height: 5),
                Text(
                    shoppingListsVM
                        .shoppingList[shoppingListsVM.currentListIndex].name,
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 30)),
                Expanded(
                  child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: shoppingList(watch)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget shoppingList(ScopedReader watch) {
    final shoppingListsVM = watch(shoppingListsProvider);
    final toolsVM = watch(toolsProvider);
    final firebaseVM = watch(firebaseProvider);
    ShoppingList shoppingList =
        shoppingListsVM.shoppingList[shoppingListsVM.currentListIndex];
    return ListView.builder(
        shrinkWrap: true,
        itemCount: shoppingList.list.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () {
              shoppingListsVM.toggleItemActivation(
                  shoppingListsVM.currentListIndex, index);
            },
            child: GestureDetector(
              onLongPress: () {
                showDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        content: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Container(
                              child: Text("Delete the this item?",
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center)),
                        ),
                        actions: [
                          FlatButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              //DELETE ITEM ON FIREBASE
                              firebaseVM.deleteShoppingListItemOnFirebase(
                                  shoppingListsVM.currentListIndex,
                                  shoppingListsVM
                                      .shoppingList[
                                          shoppingListsVM.currentListIndex]
                                      .documentId);
                              //DELETE ITEM LOCALLY
                              shoppingListsVM
                                  .deleteItemFromShoppingListLocally(index);
                            },
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
                    });
              },
              child: Card(
                color: Theme.of(context).primaryColor,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Icon(shoppingList.list[index].gotItem
                          ? Icons.radio_button_checked
                          : Icons.radio_button_off),
                      SizedBox(width: 5),
                      Expanded(
                        child: Text(shoppingList.list[index].itemName,
                            style: TextStyle(
                                decoration: shoppingList.list[index].gotItem
                                    ? TextDecoration.lineThrough
                                    : TextDecoration.none)),
                      ),
                      Icon(Icons.star_border_outlined)
                    ],
                  ),
                ),
              ),
            ),
          );
        });
  }
}
