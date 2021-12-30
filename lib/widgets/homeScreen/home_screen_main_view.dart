import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';
import 'package:shoqlist/main.dart';
import 'package:shoqlist/viewmodels/shopping_lists_view_model.dart';
import 'package:shoqlist/viewmodels/tools.dart';
import 'package:shoqlist/widgets/components/buttons.dart';
import 'package:shoqlist/widgets/components/dialogs.dart';
import 'package:shoqlist/widgets/homeScreen/shopping_list_display.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class HomeScreenMainView extends ConsumerWidget {
  void _navigateToShoppingList(BuildContext context) {
    Navigator.push(context,
        MaterialPageRoute(builder: (context) => ShoppingListDisplay()));
  }

  void _onRefresh(BuildContext context, WidgetRef ref) {
    ref.read(toolsProvider).refreshStatus = RefreshStatus.duringRefresh;
    ref.read(firebaseProvider).getShoppingListsFromFirebase(true);
  }

  void _deleteShoppingList(BuildContext context, WidgetRef ref) {
    final firebaseVM = ref.read(firebaseProvider);
    final shoppingListsVM = ref.read(shoppingListsProvider);
    //DELETE LIST ON FIREBASE
    firebaseVM.deleteShoppingListOnFirebase(shoppingListsVM
        .shoppingLists[shoppingListsVM.currentListIndex].documentId);
    //DELETE LIST LOCALLY
    shoppingListsVM.deleteShoppingListLocally(shoppingListsVM.currentListIndex);
    Navigator.of(context).popUntil((route) => !route.navigator.canPop());
  }

  void _updateShoppingList(BuildContext context, WidgetRef ref) {
    if (ref.read(toolsProvider).newListNameController.text != "") {
      final firebaseVM = ref.read(firebaseProvider);
      final toolsVM = ref.read(toolsProvider);
      final shoppingListsVM = ref.read(shoppingListsProvider);
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

  Widget build(BuildContext context, WidgetRef ref) {
    final shoppingListsVM = ref.watch(shoppingListsProvider);
    final toolsVM = ref.watch(toolsProvider);
    final firebaseAuthVM = ref.watch(firebaseAuthProvider);
    final screenSize = MediaQuery.of(context).size;
    return SafeArea(
      child: Stack(
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              SizedBox(height: 5),
              Text(AppLocalizations.of(context).appName,
                  style: Theme.of(context).primaryTextTheme.headline3),
              Divider(
                color: Theme.of(context).colorScheme.secondary,
                indent: 50,
                endIndent: 50,
              ),
              Container(
                height: screenSize.height * 0.05,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ShoppingListTypeChangeButton(
                        AppLocalizations.of(context).myLists,
                        ShoppingListType.ownShoppingLists),
                    VerticalDivider(
                      color: Theme.of(context).colorScheme.secondary,
                      indent: screenSize.height * 0.01,
                      endIndent: screenSize.height * 0.01,
                    ),
                    ShoppingListTypeChangeButton(
                        AppLocalizations.of(context).sharedLists,
                        ShoppingListType.sharedShoppingLists),
                  ],
                ),
              ),
              SizedBox(height: 5),
              Expanded(
                child: GestureDetector(
                    onPanUpdate: (details) {
                      //swipe right
                      if (details.delta.dx > 0) {
                        shoppingListsVM.currentlyDisplayedListType =
                            ShoppingListType.ownShoppingLists;
                      }
                      //swipe left
                      if (details.delta.dx < 0) {
                        shoppingListsVM.currentlyDisplayedListType =
                            ShoppingListType.sharedShoppingLists;
                      }
                    },
                    child: toolsVM.fetchStatus == FetchStatus.fetched ||
                            toolsVM.refreshStatus == RefreshStatus.duringRefresh
                        ? LiquidPullToRefresh(
                            backgroundColor:
                                Theme.of(context).colorScheme.secondary,
                            color: Theme.of(context).primaryColor,
                            height: 50,
                            animSpeedFactor: 5,
                            showChildOpacityTransition: false,
                            onRefresh: () async {
                              _onRefresh(context, ref);
                            },
                            child: shoppingListsVM.shoppingLists.isNotEmpty
                                ? ListView.builder(
                                    itemCount:
                                        shoppingListsVM.shoppingLists.length,
                                    itemBuilder: (context, index) {
                                      return Padding(
                                        padding: EdgeInsets.only(
                                            left: 8.0,
                                            right: 8.0,
                                            bottom: index ==
                                                    shoppingListsVM
                                                            .shoppingLists
                                                            .length -
                                                        1
                                                ? 50
                                                : 0),
                                        child: Container(
                                          height: 60,
                                          child: GestureDetector(
                                            onTap: () {
                                              shoppingListsVM.currentListIndex =
                                                  index;
                                              shoppingListsVM
                                                  .sortShoppingListItemsDisplay();
                                              _navigateToShoppingList(context);
                                            },
                                            onLongPress: () {
                                              shoppingListsVM.currentListIndex =
                                                  index;
                                              if (shoppingListsVM
                                                      .shoppingLists[index]
                                                      .ownerId ==
                                                  firebaseAuthVM
                                                      .currentUser.userId) {
                                                String title =
                                                    AppLocalizations.of(context)
                                                        .removeListTitle(
                                                            shoppingListsVM
                                                                .shoppingLists[
                                                                    index]
                                                                .name);
                                                showDialog(
                                                    context: context,
                                                    builder: (context) {
                                                      return PutShoppingListData(
                                                        _updateShoppingList,
                                                        context,
                                                        title,
                                                        _deleteShoppingList,
                                                      );
                                                    });
                                                toolsVM.newListImportance =
                                                    shoppingListsVM
                                                        .shoppingLists[index]
                                                        .importance;
                                                toolsVM
                                                    .setNewListNameControllerText(
                                                        shoppingListsVM
                                                            .shoppingLists[
                                                                index]
                                                            .name);
                                              }
                                            },
                                            child: Card(
                                                color:
                                                    toolsVM.getImportanceColor(
                                                        shoppingListsVM
                                                            .shoppingLists[
                                                                index]
                                                            .importance),
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.all(8.0),
                                                  child: Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                    children: [
                                                      Text(
                                                        shoppingListsVM
                                                            .shoppingLists[
                                                                index]
                                                            .name,
                                                        style: TextStyle(
                                                            color: Colors.black,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            fontSize: 20),
                                                      ),
                                                      Row(
                                                        children: [
                                                          shoppingListsVM
                                                                      .shoppingLists[
                                                                          index]
                                                                      .list
                                                                      .length !=
                                                                  0
                                                              ? Container(
                                                                  width: 100,
                                                                  child: Text(
                                                                    shoppingListsVM
                                                                            .shoppingLists[index]
                                                                            .list[0]
                                                                            .itemName +
                                                                        "${shoppingListsVM.shoppingLists[index].list.length > 1 ? ', ...' : ''}",
                                                                    overflow:
                                                                        TextOverflow
                                                                            .ellipsis,
                                                                    maxLines: 1,
                                                                    style: TextStyle(
                                                                        color: Colors
                                                                            .black,
                                                                        fontWeight:
                                                                            FontWeight
                                                                                .normal,
                                                                        fontSize:
                                                                            15),
                                                                    textAlign:
                                                                        TextAlign
                                                                            .end,
                                                                  ),
                                                                )
                                                              : Container(),
                                                          Text(
                                                            "   [" +
                                                                shoppingListsVM
                                                                    .shoppingLists[
                                                                        index]
                                                                    .list
                                                                    .length
                                                                    .toString() +
                                                                "]",
                                                            style: TextStyle(
                                                                color: Colors
                                                                    .black,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
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
                                : ListView(
                                    children: [
                                      SizedBox(height: 10),
                                      Center(
                                          child: Text(
                                              shoppingListsVM
                                                          .currentlyDisplayedListType ==
                                                      ShoppingListType
                                                          .ownShoppingLists
                                                  ? AppLocalizations.of(context)
                                                      .noListsMsg
                                                  : AppLocalizations.of(context)
                                                      .noSharedListsMsg,
                                              style: Theme.of(context)
                                                  .primaryTextTheme
                                                  .bodyText1))
                                    ],
                                  ))
                        : Column(
                            children: [
                              Container(
                                  height: 30,
                                  width: 30,
                                  child: CircularProgressIndicator()),
                            ],
                          )),
              ),
              SizedBox(height: 50)
            ],
          ),
        ],
      ),
    );
  }
}
