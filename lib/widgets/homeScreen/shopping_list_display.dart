import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:shoqlist/main.dart';
import 'package:shoqlist/models/shopping_list.dart';
import 'package:shoqlist/viewmodels/firebase_view_model.dart';
import 'package:shoqlist/viewmodels/shopping_lists_view_model.dart';
import 'package:shoqlist/viewmodels/tools.dart';
import 'package:shoqlist/widgets/components/notifications.dart';

class ShoppingListDisplay extends ConsumerWidget {
  void _onLongPressShoppingListItem(BuildContext context) {
    Navigator.of(context).pop();
    //DELETE ITEM ON FIREBASE
    context.read(firebaseProvider).deleteShoppingListItemOnFirebase(
        context.read(shoppingListsProvider).currentListIndex,
        context
            .read(shoppingListsProvider)
            .shoppingLists[context.read(shoppingListsProvider).currentListIndex]
            .documentId);
    //DELETE ITEM LOCALLY
    context.read(shoppingListsProvider).deleteItemFromShoppingListLocally(
        context.read(shoppingListsProvider).pickedListItemIndex);
  }

  void _addNewItemToCurrentShoppingList(Tools toolsVM,
      FirebaseViewModel firebaseVM, ShoppingListsViewModel shoppingListsVM) {
    if (toolsVM.newItemNameController.text != "") {
      //ADD ITEM TO FIREBASE
      firebaseVM.addNewItemToShoppingListOnFirebase(
          toolsVM.newItemNameController.text,
          shoppingListsVM
              .shoppingLists[shoppingListsVM.currentListIndex].documentId);
      //ADD ITEM LOCALLY
      shoppingListsVM.addNewItemToShoppingListLocally(
          toolsVM.newItemNameController.text, false, false);
    }
    toolsVM.clearNewItemTextEditingController();
    FocusManager.instance.primaryFocus.unfocus();
  }

  Widget build(BuildContext context, ScopedReader watch) {
    final shoppingListsVM = watch(shoppingListsProvider);
    final toolsVM = watch(toolsProvider);
    final firebaseVM = watch(firebaseProvider);
    const Color _disabledGreyColor = Color.fromRGBO(0, 0, 0, 0.3);
    return Scaffold(
      backgroundColor: Color.lerp(
          toolsVM.getImportanceColor(shoppingListsVM
              .shoppingLists[shoppingListsVM.currentListIndex].importance),
          Colors.black,
          0.15),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 60.0),
        child: SpeedDial(
          overlayOpacity: 0,
          animatedIcon: AnimatedIcons.menu_close,
          backgroundColor:
              Theme.of(context).floatingActionButtonTheme.backgroundColor,
          children: [
            SpeedDialChild(
                child: Icon(Icons.add),
                backgroundColor:
                    Theme.of(context).floatingActionButtonTheme.backgroundColor,
                label: "Edit details"),
          ],
        ),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                SizedBox(height: 5),
                Text(
                    shoppingListsVM
                        .shoppingLists[shoppingListsVM.currentListIndex].name,
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 30)),
                Divider(
                  color: Theme.of(context).accentColor,
                  indent: 50,
                  endIndent: 50,
                ),
                Expanded(
                  child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: shoppingList(watch)),
                ),
              ],
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                color: Colors.white,
                child: Row(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: TextFormField(
                          key: toolsVM.addNewItemNameFormFieldKey,
                          keyboardType: TextInputType.name,
                          autofocus: false,
                          autocorrect: false,
                          obscureText: false,
                          controller: toolsVM.newItemNameController,
                          style: TextStyle(fontWeight: FontWeight.bold),
                          decoration: InputDecoration(
                            hintText: "New Item name",
                            hintStyle: TextStyle(
                                color: _disabledGreyColor,
                                fontWeight: FontWeight.bold),
                            contentPadding: EdgeInsets.fromLTRB(20, 10, 20, 10),
                            enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                    width: 1, color: _disabledGreyColor)),
                            focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                    width: 1, color: _disabledGreyColor)),
                          ),
                          onFieldSubmitted: (value) {
                            _addNewItemToCurrentShoppingList(
                                toolsVM, firebaseVM, shoppingListsVM);
                          },
                        ),
                      ),
                    ),
                    GestureDetector(
                        onTap: () {
                          _addNewItemToCurrentShoppingList(
                              toolsVM, firebaseVM, shoppingListsVM);
                        },
                        child: Icon(Icons.send)),
                    SizedBox(width: 10)
                  ],
                ),
              ),
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
        shoppingListsVM.shoppingLists[shoppingListsVM.currentListIndex];
    return ListView.builder(
        shrinkWrap: true,
        itemCount: shoppingList.list.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () {
              shoppingListsVM.pickedListItemIndex = index;
              //TOGGLE ITEM STATE ON FIREBASE
              firebaseVM.toggleStateOfShoppingListItemOnFirebase(
                  shoppingListsVM
                      .shoppingLists[shoppingListsVM.currentListIndex]
                      .documentId,
                  index);
              //TOGGLE ITEM STATE LOCALLY
              shoppingListsVM.toggleItemStateLocally(
                  shoppingListsVM.currentListIndex, index);
            },
            onLongPress: () {
              shoppingListsVM.pickedListItemIndex = index;
              showDialog(
                  context: context,
                  builder: (context) {
                    return DeleteNotification(
                        _onLongPressShoppingListItem, "this item?", context);
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
                    GestureDetector(
                        onTap: () {
                          //TOGGLE ITEM FAVORITE ON FIREBASE
                          firebaseVM.toggleFavoriteOfShoppingListItemOnFirebase(
                              shoppingListsVM
                                  .shoppingLists[
                                      shoppingListsVM.currentListIndex]
                                  .documentId,
                              index);
                          //TOGGLE ITEM FAVORITE LOCALLY
                          shoppingListsVM.toggleItemFavoriteLocally(
                              shoppingListsVM.currentListIndex, index);
                        },
                        child: Stack(
                          children: [
                            Icon(
                                !shoppingList.list[index].isFavorite
                                    ? null
                                    : Icons.star,
                                color: Colors.yellow),
                            Icon(Icons.star_border_outlined,
                                color: Colors.black),
                          ],
                        )),
                  ],
                ),
              ),
            ),
          );
        });
  }
}
