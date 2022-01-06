import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';
import 'package:share/share.dart';
import 'package:shoqlist/main.dart';
import 'package:shoqlist/models/shopping_list.dart';
import 'package:shoqlist/models/user.dart';
import 'package:shoqlist/widgets/components/dialogs.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ShoppingListDisplay extends ConsumerWidget {
  void _onLongPressShoppingListItem(BuildContext context, WidgetRef ref) {
    final firebaseVM = ref.read(firebaseProvider);
    final shoppingListsVM = ref.read(shoppingListsProvider);
    //DELETE ITEM ON FIREBASE
    firebaseVM.deleteShoppingListItemOnFirebase(
        shoppingListsVM.pickedListItemIndex,
        shoppingListsVM
            .shoppingLists[shoppingListsVM.currentListIndex].documentId,
        shoppingListsVM
            .shoppingLists[shoppingListsVM.currentListIndex].ownerId);
    //DELETE ITEM LOCALLY
    shoppingListsVM
        .deleteItemFromShoppingListLocally(shoppingListsVM.pickedListItemIndex);
    Navigator.of(context).pop();
  }

  void _addNewItemToCurrentShoppingList(BuildContext context, WidgetRef ref) {
    final toolsVM = ref.read(toolsProvider);
    final firebaseVM = ref.read(firebaseProvider);
    final shoppingListsVM = ref.read(shoppingListsProvider);
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

  void _giveAccessToTheFriendAfterTap(BuildContext context, WidgetRef ref) {
    final friendsServiceVM = ref.read(friendsServiceProvider);
    final firebaseVM = ref.read(firebaseProvider);
    final shoppingListsVM = ref.read(shoppingListsProvider);
    List<User> friendsWithoutAccess =
        friendsServiceVM.getFriendsWithoutAccessToCurrentShoppingList(
            shoppingListsVM.getUsersWithAccessToCurrentList());
    //GIVE ACCESS
    firebaseVM.giveFriendAccessToYourShoppingList(
        friendsWithoutAccess[friendsServiceVM.currentUserIndex],
        shoppingListsVM
            .shoppingLists[shoppingListsVM.currentListIndex].documentId);
    shoppingListsVM.addUserToUsersWithAccessList(
        friendsWithoutAccess[friendsServiceVM.currentUserIndex]);
    Navigator.of(context).pop();
    Navigator.of(context).pop();
  }

  void _denyFriendAccessAfterTap(BuildContext context, WidgetRef ref) {
    final friendsServiceVM = ref.read(friendsServiceProvider);
    final firebaseVM = ref.read(firebaseProvider);
    final shoppingListsVM = ref.read(shoppingListsProvider);
    List<User> usersWithAccess = shoppingListsVM
        .shoppingLists[shoppingListsVM.currentListIndex].usersWithAccess;

    firebaseVM.denyFriendAccessToYourShoppingList(
        usersWithAccess[friendsServiceVM.currentUserIndex],
        shoppingListsVM
            .shoppingLists[shoppingListsVM.currentListIndex].documentId,
        usersWithAccess);

    shoppingListsVM.removeUserFromUsersWithAccessList(
        usersWithAccess[friendsServiceVM.currentUserIndex]);
    Navigator.of(context).pop();
    Navigator.of(context).pop();
  }

  void _onRefresh(WidgetRef ref, String documentId, String ownerId) {
    ref.read(firebaseProvider).fetchOneShoppingList(documentId, ownerId);
  }

  Widget build(BuildContext context, WidgetRef ref) {
    final shoppingListsVM = ref.watch(shoppingListsProvider);
    final toolsVM = ref.watch(toolsProvider);
    final firebaseAuthVM = ref.watch(firebaseAuthProvider);
    final friendsServiceVM = ref.watch(friendsServiceProvider);
    final screenSize = MediaQuery.of(context).size;
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
                            subject:
                                AppLocalizations.of(context).shareListSubject);
                      },
                      backgroundColor: Theme.of(context)
                          .floatingActionButtonTheme
                          .backgroundColor,
                      label: AppLocalizations.of(context).share),
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
                                AppLocalizations.of(context).giveAccessTitle));
                      },
                      backgroundColor: Theme.of(context)
                          .floatingActionButtonTheme
                          .backgroundColor,
                      label: AppLocalizations.of(context).giveAccess),
                  SpeedDialChild(
                      labelBackgroundColor: Theme.of(context)
                          .floatingActionButtonTheme
                          .backgroundColor,
                      labelStyle: Theme.of(context).textTheme.bodyText2,
                      child: Icon(Icons.info,
                          color: Theme.of(context)
                              .floatingActionButtonTheme
                              .foregroundColor),
                      onTap: () {
                        showDialog(
                            context: context,
                            builder: (context) => ChooseUser(
                                _denyFriendAccessAfterTap,
                                shoppingListsVM
                                    .shoppingLists[
                                        shoppingListsVM.currentListIndex]
                                    .usersWithAccess,
                                AppLocalizations.of(context).removeAccessMsg));
                      },
                      backgroundColor: Theme.of(context)
                          .floatingActionButtonTheme
                          .backgroundColor,
                      label: AppLocalizations.of(context).whoHasAccess),
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
                            subject:
                                AppLocalizations.of(context).shareListSubject);
                      },
                      backgroundColor: Theme.of(context)
                          .floatingActionButtonTheme
                          .backgroundColor,
                      label: AppLocalizations.of(context).share),
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
                  color: Theme.of(context).colorScheme.secondary,
                  indent: 50,
                  endIndent: 50,
                ),
                Container(
                    width: screenSize.width - 100,
                    child: Text(
                      AppLocalizations.of(context).owner +
                          ": " +
                          shoppingListsVM
                              .shoppingLists[shoppingListsVM.currentListIndex]
                              .ownerName,
                      textAlign: TextAlign.end,
                      overflow: TextOverflow.ellipsis,
                      softWrap: false,
                      maxLines: 1,
                    )),
                Expanded(
                  child: LiquidPullToRefresh(
                      backgroundColor: Theme.of(context).colorScheme.secondary,
                      color: Theme.of(context).primaryColor,
                      height: 50,
                      animSpeedFactor: 5,
                      showChildOpacityTransition: false,
                      onRefresh: () async {
                        _onRefresh(
                            ref,
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
                          child: shoppingList(ref))),
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
                            hintText: AppLocalizations.of(context).itemNameHint,
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
                                    color: Theme.of(context)
                                        .colorScheme
                                        .secondary)),
                          ),
                          onFieldSubmitted: (value) {
                            _addNewItemToCurrentShoppingList(context, ref);
                            toolsVM.clearNewItemTextEditingController();
                            toolsVM.newItemFocusNode.requestFocus();
                          },
                        ),
                      ),
                    ),
                    GestureDetector(
                        onTap: () {
                          _addNewItemToCurrentShoppingList(context, ref);
                          toolsVM.clearNewItemTextEditingController();
                          toolsVM.newItemFocusNode.requestFocus();
                        },
                        child: Icon(Icons.add,
                            color: Theme.of(context).colorScheme.secondary)),
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

  Widget shoppingList(WidgetRef ref) {
    final shoppingListsVM = ref.watch(shoppingListsProvider);
    final firebaseVM = ref.watch(firebaseProvider);
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
                        _onLongPressShoppingListItem,
                        AppLocalizations.of(context)
                            .removeItemMsg(shoppingList.list[index].itemName));
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
                          color: Theme.of(context).colorScheme.secondary),
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
                                  color:
                                      Theme.of(context).colorScheme.secondary),
                              Icon(
                                Icons.star_border_outlined,
                                color: Theme.of(context).colorScheme.secondary,
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
