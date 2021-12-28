import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';
import 'package:share/share.dart';
import 'package:shoqlist/main.dart';
import 'package:shoqlist/models/shopping_list.dart';
import 'package:shoqlist/models/user.dart';
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
    Navigator.of(context).popUntil((route) => !Navigator.of(context).canPop());
  }

  void _onRefresh(BuildContext context, String documentId, String ownerId) {
    context.read(firebaseProvider).fetchOneShoppingList(documentId, ownerId);
  }

  Widget build(BuildContext context, ScopedReader watch) {
    final shoppingListsVM = watch(shoppingListsProvider);
    final toolsVM = watch(toolsProvider);
    final firebaseAuthVM = watch(firebaseAuthProvider);
    final friendsServiceVM = watch(friendsServiceProvider);
    return Scaffold(
      backgroundColor: Theme.of(context).backgroundColor,
      //backgroundColor: Theme.of(context).backgroundColor,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 60.0),
        child: SpeedDial(
          overlayOpacity: 0,
          animatedIcon: AnimatedIcons.menu_close,
          foregroundColor:
              Theme.of(context).floatingActionButtonTheme.foregroundColor,
          backgroundColor:
              Theme.of(context).floatingActionButtonTheme.backgroundColor,
          children: shoppingListsVM
                      .shoppingLists[shoppingListsVM.currentListIndex]
                      .ownerId ==
                  firebaseAuthVM.currentUser.userId
              ? [
                  SpeedDialChild(
                      labelBackgroundColor: Theme.of(context)
                          .floatingActionButtonTheme
                          .backgroundColor,
                      labelStyle: Theme.of(context).textTheme.bodyText2,
                      child: Icon(Icons.share,
                          color: Theme.of(context)
                              .floatingActionButtonTheme
                              .foregroundColor),
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
                      labelBackgroundColor: Theme.of(context)
                          .floatingActionButtonTheme
                          .backgroundColor,
                      labelStyle: Theme.of(context).textTheme.bodyText2,
                      child: Icon(Icons.add_moderator,
                          color: Theme.of(context)
                              .floatingActionButtonTheme
                              .foregroundColor),
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
                      labelBackgroundColor: Theme.of(context)
                          .floatingActionButtonTheme
                          .backgroundColor,
                      labelStyle: Theme.of(context).textTheme.bodyText2,
                      child: Icon(Icons.share,
                          color: Theme.of(context)
                              .floatingActionButtonTheme
                              .foregroundColor),
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
                  child: LiquidPullToRefresh(
                      backgroundColor: Theme.of(context).accentColor,
                      color: Theme.of(context).primaryColor,
                      height: 50,
                      animSpeedFactor: 5,
                      showChildOpacityTransition: false,
                      onRefresh: () async {
                        _onRefresh(
                            context,
                            shoppingListsVM
                                .shoppingLists[shoppingListsVM.currentListIndex]
                                .documentId,
                            shoppingListsVM
                                .shoppingLists[shoppingListsVM.currentListIndex]
                                .ownerId);
                      },
                      child: Padding(
                          padding: const EdgeInsets.only(
                              left: 8, top: 8, right: 8, bottom: 65),
                          child: shoppingList(watch))),
                ),
              ],
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                height: 65,
                color: Theme.of(context).backgroundColor,
                child: Row(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: TextFormField(
                          key: toolsVM.addNewItemNameFormFieldKey,
                          focusNode: toolsVM.newItemFocusNode,
                          keyboardType: TextInputType.name,
                          autofocus: false,
                          autocorrect: false,
                          obscureText: false,
                          controller: toolsVM.newItemNameController,
                          style: TextStyle(fontWeight: FontWeight.bold),
                          decoration: InputDecoration(
                            fillColor: Colors.grey[600],
                            hintText: "New Item name",
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
                          onFieldSubmitted: (value) {
                            _addNewItemToCurrentShoppingList(context);
                            toolsVM.clearNewItemTextEditingController();
                            toolsVM.newItemFocusNode.requestFocus();
                          },
                        ),
                      ),
                    ),
                    GestureDetector(
                        onTap: () {
                          _addNewItemToCurrentShoppingList(context);
                        },
                        child: Icon(Icons.add,
                            color: Theme.of(context).accentColor)),
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
    final firebaseVM = watch(firebaseProvider);
    final toolsVM = watch(toolsProvider);
    ShoppingList shoppingList =
        shoppingListsVM.shoppingLists[shoppingListsVM.currentListIndex];
    return ListView.builder(
        shrinkWrap: false,
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
            child: Padding(
              padding: EdgeInsets.only(
                  bottom: shoppingList.list.length - 1 == index ? 70 : 0),
              child: Card(
                color: Theme.of(context).primaryColor,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Icon(
                          shoppingList.list[index].gotItem
                              ? Icons.radio_button_checked
                              : Icons.radio_button_off,
                          color: Theme.of(context).accentColor),
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
                            firebaseVM
                                .toggleFavoriteOfShoppingListItemOnFirebase(
                                    shoppingList.documentId,
                                    index,
                                    shoppingList.ownerId);
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
                                  color: Theme.of(context).accentColor),
                              Icon(
                                Icons.star_border_outlined,
                                color: Theme.of(context).accentColor,
                              )
                            ],
                          )),
                    ],
                  ),
                ),
              ),
            ),
          );
        });
  }
}
