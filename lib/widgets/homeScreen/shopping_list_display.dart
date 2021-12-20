import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:share/share.dart';
import 'package:shoqlist/main.dart';
import 'package:shoqlist/models/shopping_list.dart';
import 'package:shoqlist/models/user.dart';
import 'package:shoqlist/viewmodels/firebase_view_model.dart';
import 'package:shoqlist/viewmodels/shopping_lists_view_model.dart';
import 'package:shoqlist/viewmodels/tools.dart';
import 'package:shoqlist/widgets/components/dialogs.dart';

class ShoppingListDisplay extends ConsumerWidget {
  void _onLongPressShoppingListItem(BuildContext context) {
    final firebaseVM = context.read(firebaseProvider);
    final shoppingListsVM = context.read(shoppingListsProvider);
    //DELETE ITEM ON FIREBASE
    firebaseVM.deleteShoppingListItemOnFirebase(
        shoppingListsVM.currentListIndex,
        shoppingListsVM
            .shoppingLists[shoppingListsVM.currentListIndex].documentId,
        shoppingListsVM
            .shoppingLists[shoppingListsVM.currentListIndex].ownerId);
    //DELETE ITEM LOCALLY
    shoppingListsVM
        .deleteItemFromShoppingListLocally(shoppingListsVM.pickedListItemIndex);
    Navigator.of(context).pop();
  }

  void _addNewItemToCurrentShoppingList(BuildContext context) {
    final toolsVM = context.read(toolsProvider);
    final firebaseVM = context.read(firebaseProvider);
    final shoppingListsVM = context.read(shoppingListsProvider);
    if (toolsVM.newItemNameController.text != "") {
      //ADD ITEM TO FIREBASE
      firebaseVM.addNewItemToShoppingListOnFirebase(
          toolsVM.newItemNameController.text,
          shoppingListsVM
              .shoppingLists[shoppingListsVM.currentListIndex].documentId,
          shoppingListsVM
              .shoppingLists[shoppingListsVM.currentListIndex].ownerId);
      //ADD ITEM LOCALLY
      shoppingListsVM.addNewItemToShoppingListLocally(
          toolsVM.newItemNameController.text, false, false);
    }
    toolsVM.clearNewItemTextEditingController();
    FocusManager.instance.primaryFocus.unfocus();
  }

  void _giveAccessToTheFriendAfterTap(BuildContext context) {
    final friendsServiceVM = context.read(friendsServiceProvider);
    final firebaseVM = context.read(firebaseProvider);
    final shoppingListsVM = context.read(shoppingListsProvider);
    List<User> friendsWithoutAccess =
        friendsServiceVM.getFriendsWithoutAccessToCurrentShoppingList(
            shoppingListsVM.getUsersWithAccessToCurrentList());
    //GIVE ACCESS
    firebaseVM.giveFriendAccessToYourShoppingList(
        friendsWithoutAccess[friendsServiceVM.currentUserIndex],
        shoppingListsVM
            .shoppingLists[shoppingListsVM.currentListIndex].documentId);
    shoppingListsVM.addUserIdToUsersWithAccessList(
        friendsWithoutAccess[friendsServiceVM.currentUserIndex].userId);
    Navigator.of(context).popUntil((route) => Navigator.of(context).canPop());
  }

  Widget build(BuildContext context, ScopedReader watch) {
    final shoppingListsVM = watch(shoppingListsProvider);
    final toolsVM = watch(toolsProvider);
    final firebaseVM = watch(firebaseProvider);
    final friendsServiceVM = watch(friendsServiceProvider);
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
          children: shoppingListsVM
                      .shoppingLists[shoppingListsVM.currentListIndex]
                      .ownerId ==
                  firebaseVM.currentUserId
              ? [
                  SpeedDialChild(
                      child: Icon(Icons.share),
                      onTap: () {
                        Share.share(
                            shoppingListsVM
                                .getCurrentShoppingListDataInString(),
                            subject: 'A shared list for you');
                      },
                      backgroundColor: Theme.of(context)
                          .floatingActionButtonTheme
                          .backgroundColor,
                      label: "Share"),
                  SpeedDialChild(
                      child: Icon(Icons.add_moderator),
                      onTap: () {
                        showDialog(
                            context: context,
                            builder: (context) => ChooseUser(
                                _giveAccessToTheFriendAfterTap,
                                friendsServiceVM
                                    .getFriendsWithoutAccessToCurrentShoppingList(
                                        shoppingListsVM
                                            .getUsersWithAccessToCurrentList()),
                                "Give access to that Friend?"));
                      },
                      backgroundColor: Theme.of(context)
                          .floatingActionButtonTheme
                          .backgroundColor,
                      label: "Give access"),
                ]
              : [
                  SpeedDialChild(
                      child: Icon(Icons.share),
                      onTap: () {
                        Share.share(
                            shoppingListsVM
                                .getCurrentShoppingListDataInString(),
                            subject: 'A shared list for you');
                      },
                      backgroundColor: Theme.of(context)
                          .floatingActionButtonTheme
                          .backgroundColor,
                      label: "Share"),
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
                            _addNewItemToCurrentShoppingList(context);
                          },
                        ),
                      ),
                    ),
                    GestureDetector(
                        onTap: () {
                          _addNewItemToCurrentShoppingList(context);
                        },
                        child: Icon(Icons.add)),
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
                  shoppingList.documentId,
                  index,
                  shoppingListsVM
                      .shoppingLists[shoppingListsVM.currentListIndex].ownerId);
              //TOGGLE ITEM STATE LOCALLY
              shoppingListsVM.toggleItemStateLocally(
                  shoppingListsVM.currentListIndex, index);
            },
            onLongPress: () {
              shoppingListsVM.pickedListItemIndex = index;
              showDialog(
                  context: context,
                  builder: (context) {
                    return YesNoDialog(
                        _onLongPressShoppingListItem, "Remove this item?");
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
                              shoppingList.documentId, index);
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
