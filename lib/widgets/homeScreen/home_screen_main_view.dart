import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shoqlist/main.dart';
import 'package:shoqlist/viewmodels/shopping_lists_view_model.dart';
import 'package:shoqlist/widgets/components/buttons.dart';
import 'package:shoqlist/widgets/components/dialogs.dart';
import 'package:shoqlist/widgets/homeScreen/shopping_list_display.dart';

class HomeScreenMainView extends ConsumerWidget {
  void _navigateToShoppingList(BuildContext context) {
    Navigator.push(context,
        MaterialPageRoute(builder: (context) => ShoppingListDisplay()));
  }

  void _deleteShoppingList(BuildContext context) {
    final firebaseVM = context.read(firebaseProvider);
    final shoppingListsVM = context.read(shoppingListsProvider);
    //DELETE LIST ON FIREBASE
    firebaseVM.deleteShoppingListOnFirebase(shoppingListsVM
        .shoppingLists[shoppingListsVM.currentListIndex].documentId);
    //DELETE LIST LOCALLY
    shoppingListsVM.deleteShoppingListLocally(shoppingListsVM.currentListIndex);
    Navigator.of(context).popUntil((route) => !route.navigator.canPop());
  }

  void _updateShoppingList(BuildContext context) {
    if (context.read(toolsProvider).newListNameController.text != "") {
      final firebaseVM = context.read(firebaseProvider);
      final toolsVM = context.read(toolsProvider);
      final shoppingListsVM = context.read(shoppingListsProvider);
      //UPDATE LIST ON SERVER
      firebaseVM.updateShoppingListToFirebase(
          toolsVM.newListNameController.text,
          toolsVM.newListImportance,
          shoppingListsVM
              .shoppingLists[shoppingListsVM.currentListIndex].documentId);
      //UPDATE LIST LOCALLY
      shoppingListsVM.updateExistingShoppingListLocally(
          toolsVM.newListNameController.text,
          toolsVM.newListImportance,
          shoppingListsVM.currentListIndex);
    }
  }

  Widget build(BuildContext context, ScopedReader watch) {
    final shoppingListsVM = watch(shoppingListsProvider);
    final toolsVM = watch(toolsProvider);
    final firebaseAuthVM = watch(firebaseAuthProvider);
    final screenSize = MediaQuery.of(context).size;
    return SafeArea(
      child: Stack(
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              SizedBox(height: 5),
              Text("Shoqlist",
                  style: Theme.of(context).primaryTextTheme.headline3),
              Divider(
                color: Theme.of(context).accentColor,
                indent: 50,
                endIndent: 50,
              ),
              Container(
                height: screenSize.height * 0.05,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ShoppingListTypeChangeButton(
                        'Your lists', ShoppingListType.ownShoppingLists),
                    VerticalDivider(
                      color: Theme.of(context).accentColor,
                      indent: screenSize.height * 0.01,
                      endIndent: screenSize.height * 0.01,
                    ),
                    ShoppingListTypeChangeButton(
                        'Shared lists', ShoppingListType.sharedShoppingLists),
                  ],
                ),
              ),
              SizedBox(height: 5),
              shoppingListsVM.shoppingLists.isNotEmpty
                  ? ListView.builder(
                      shrinkWrap: true,
                      itemCount: shoppingListsVM.shoppingLists.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(left: 8.0, right: 8.0),
                          child: Container(
                            height: 60,
                            child: GestureDetector(
                              onTap: () {
                                shoppingListsVM.currentListIndex = index;
                                _navigateToShoppingList(context);
                              },
                              onLongPress: () {
                                shoppingListsVM.currentListIndex = index;
                                if (shoppingListsVM
                                        .shoppingLists[index].ownerId ==
                                    firebaseAuthVM.currentUser.userId) {
                                  showDialog(
                                      context: context,
                                      builder: (context) {
                                        String title = "Remove the '" +
                                            shoppingListsVM
                                                .shoppingLists[index].name +
                                            "' list?";
                                        return PutShoppingListData(
                                          _updateShoppingList,
                                          context,
                                          title,
                                          _deleteShoppingList,
                                        );
                                      });
                                  toolsVM.newListImportance = shoppingListsVM
                                      .shoppingLists[index].importance;
                                  toolsVM.setNewListNameControllerText(
                                      shoppingListsVM
                                          .shoppingLists[index].name);
                                }
                              },
                              child: Card(
                                  color: toolsVM.getImportanceColor(
                                      shoppingListsVM
                                          .shoppingLists[index].importance),
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          shoppingListsVM
                                              .shoppingLists[index].name,
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 20),
                                        ),
                                        Row(
                                          children: [
                                            shoppingListsVM.shoppingLists[index]
                                                        .list.length !=
                                                    0
                                                ? Container(
                                                    width: 100,
                                                    child: Text(
                                                      shoppingListsVM
                                                              .shoppingLists[
                                                                  index]
                                                              .list[0]
                                                              .itemName +
                                                          "${shoppingListsVM.shoppingLists[index].list.length > 1 ? ', ...' : ''}",
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      maxLines: 1,
                                                      style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.normal,
                                                          fontSize: 15),
                                                      textAlign: TextAlign.end,
                                                    ),
                                                  )
                                                : Container(),
                                            Text(
                                              "   [" +
                                                  shoppingListsVM
                                                      .shoppingLists[index]
                                                      .list
                                                      .length
                                                      .toString() +
                                                  "]",
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 15),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  )),
                            ),
                          ),
                        );
                      })
                  : Text(
                      shoppingListsVM.currentlyDisplayedListType ==
                              ShoppingListType.ownShoppingLists
                          ? 'You have no shopping lists'
                          : 'You have no shared lists',
                      style: Theme.of(context).primaryTextTheme.bodyText1)
            ],
          ),
        ],
      ),
    );
  }
}
