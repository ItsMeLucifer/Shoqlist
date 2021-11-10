import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:shoqlist/main.dart';
import 'package:shoqlist/widgets/homeScreen/add_new_item.dart';

class ShoppingListDisplay extends ConsumerWidget {
  Widget build(BuildContext context, ScopedReader watch) {
    final shoppingListsVM = watch(shoppingListsProvider);
    final toolsVM = watch(toolsProvider);
    return Scaffold(
      backgroundColor: toolsVM.getImportanceColor(shoppingListsVM
          .shoppingList[shoppingListsVM.currentListIndex].importance),
      floatingActionButton: SpeedDial(
        overlayOpacity: 0,
        animatedIcon: AnimatedIcons.menu_close,
        children: [
          SpeedDialChild(
              onTap: () {
                showDialog(
                    context: context,
                    builder: (context) {
                      return AddNewItem();
                    });
              },
              child: Icon(Icons.add),
              label: "Add item"),
          SpeedDialChild(child: Icon(Icons.add), label: "Edit details")
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
                    child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: shoppingListsVM
                            .shoppingList[shoppingListsVM.currentListIndex]
                            .list
                            .length,
                        itemBuilder: (context, index) {
                          return Container(
                            height: 50,
                            child: Row(
                              children: [
                                Icon(Icons.crop_square),
                                SizedBox(width: 5),
                                Text(shoppingListsVM
                                    .shoppingList[
                                        shoppingListsVM.currentListIndex]
                                    .list[index]
                                    .itemName),
                              ],
                            ),
                          );
                        }),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
