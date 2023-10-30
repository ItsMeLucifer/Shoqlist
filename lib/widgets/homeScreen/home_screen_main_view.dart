import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';
import 'package:nanoid/nanoid.dart';
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
    ref.read(firebaseAuthProvider).setCurrentUserCredentials();
  }

  void _deleteShoppingList(BuildContext context, WidgetRef ref) {
    final firebaseVM = ref.read(firebaseProvider);
    final shoppingListsVM = ref.read(shoppingListsProvider);
    //DELETE LIST ON FIREBASE
    firebaseVM.deleteShoppingListOnFirebase(shoppingListsVM
        .shoppingLists[shoppingListsVM.currentListIndex].documentId);
    //DELETE LIST LOCALLY
    shoppingListsVM.deleteShoppingListLocally(shoppingListsVM.currentListIndex);
    Navigator.of(context)
        .popUntil((route) => route.navigator?.canPop() != false);
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

  void _createNewShoppingList(BuildContext context, WidgetRef ref) {
    final toolsVM = ref.read(toolsProvider);
    final firebaseVM = ref.read(firebaseProvider);
    final shopingListsProviderVM = ref.read(shoppingListsProvider);
    if (toolsVM.newListNameController.text != "") {
      String id = nanoid();
      //CREATE LIST ON SERVER
      firebaseVM.putShoppingListToFirebase(
          toolsVM.newListNameController.text, toolsVM.newListImportance, id);
      //CREATE LIST LOCALLY
      shopingListsProviderVM.saveNewShoppingListLocally(
          toolsVM.newListNameController.text, toolsVM.newListImportance, id);
    }
  }

  Widget build(BuildContext context, WidgetRef ref) {
    final shoppingListsVM = ref.watch(shoppingListsProvider);
    final toolsVM = ref.watch(toolsProvider);
    return SafeArea(
      child: Stack(
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              SizedBox(height: 5),
              Text(AppLocalizations.of(context)!.appName,
                  style: Theme.of(context).primaryTextTheme.displaySmall),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ShoppingListTypeChangeButton(
                      AppLocalizations.of(context)!.myLists,
                      ShoppingListType.ownShoppingLists,
                      Icons.list,
                    ),
                    ShoppingListTypeChangeButton(
                      AppLocalizations.of(context)!.sharedLists,
                      ShoppingListType.sharedShoppingLists,
                      Icons.people_alt,
                    ),
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
                                ? shoppingLists(context, ref)
                                : ListView(
                                    children: [
                                      SizedBox(height: 10),
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Center(
                                          child: Text(
                                            shoppingListsVM
                                                        .currentlyDisplayedListType ==
                                                    ShoppingListType
                                                        .ownShoppingLists
                                                ? AppLocalizations.of(context)!
                                                    .noListsMsg
                                                : AppLocalizations.of(context)!
                                                    .noSharedListsMsg,
                                            style: Theme.of(context)
                                                .primaryTextTheme
                                                .bodyLarge,
                                          ),
                                        ),
                                      )
                                    ],
                                  ),
                          )
                        : Column(
                            children: [
                              Container(
                                  height: 30,
                                  width: 30,
                                  child: CircularProgressIndicator()),
                            ],
                          )),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 25.0, left: 25, top: 10),
                child: Row(
                  children: [
                    Icon(Icons.add,
                        color: Theme.of(context).colorScheme.secondary,
                        size: 22),
                    TextButton(
                      onPressed: () {
                        ref.read(toolsProvider).resetNewListData();
                        showDialog(
                            context: context,
                            builder: (context) => PutShoppingListData(
                                _createNewShoppingList, context));
                      },
                      child: Text(
                        AppLocalizations.of(context)!.newList,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    )
                  ],
                ),
              )
            ],
          ),
        ],
      ),
    );
  }

  void _onLongPressShoppingListButton(
      BuildContext context, int index, WidgetRef ref) {
    final shoppingListsVM = ref.watch(shoppingListsProvider);
    final firebaseAuthVM = ref.watch(firebaseAuthProvider);
    final toolsVM = ref.watch(toolsProvider);
    shoppingListsVM.currentListIndex = index;
    if (shoppingListsVM.shoppingLists[index].ownerId ==
        firebaseAuthVM.currentUser.userId) {
      String title = AppLocalizations.of(context)!
          .removeListTitle(shoppingListsVM.shoppingLists[index].name);
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
          shoppingListsVM.shoppingLists[index].importance;
      toolsVM.setNewListNameControllerText(
          shoppingListsVM.shoppingLists[index].name);
    }
  }

  void _onTapShoppingListButton(
      BuildContext context, int index, WidgetRef ref) {
    final shoppingListsVM = ref.watch(shoppingListsProvider);
    shoppingListsVM.currentListIndex = index;
    shoppingListsVM.sortShoppingListItemsDisplay();
    _navigateToShoppingList(context);
  }

  Widget shoppingLists(BuildContext context, WidgetRef ref) {
    final shoppingListsVM = ref.watch(shoppingListsProvider);
    return ListView.builder(
        itemCount: shoppingListsVM.shoppingLists.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: EdgeInsets.only(
                left: 8.0,
                right: 8.0,
                bottom:
                    index == shoppingListsVM.shoppingLists.length - 1 ? 50 : 0),
            child: ShoppingListButton(
              () => _onTapShoppingListButton(context, index, ref),
              () => _onLongPressShoppingListButton(context, index, ref),
              index,
            ),
          );
        });
  }
}
