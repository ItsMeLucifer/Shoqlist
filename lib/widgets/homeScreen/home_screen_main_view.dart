import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';
import 'package:nanoid/nanoid.dart';
import 'package:shoqlist/constants/app_colors.dart';
import 'package:shoqlist/main.dart';
import 'package:shoqlist/viewmodels/shopping_lists_view_model.dart';
import 'package:shoqlist/viewmodels/tools.dart';
import 'package:shoqlist/widgets/components/buttons.dart';
import 'package:shoqlist/widgets/components/dialogs.dart';
import 'package:shoqlist/widgets/components/slidable_actions.dart';
import 'package:shoqlist/widgets/homeScreen/shopping_list_display.dart';
import 'package:shoqlist/l10n/l10n_extension.dart';

class HomeScreenMainView extends ConsumerWidget {
  const HomeScreenMainView({super.key});

  void _navigateToShoppingList(BuildContext context) {
    Navigator.push(context,
        MaterialPageRoute(builder: (context) => const ShoppingListDisplay()));
  }

  void _onRefresh(BuildContext context, WidgetRef ref) {
    ref.read(toolsProvider).refreshStatus = RefreshStatus.duringRefresh;
    ref.read(firebaseProvider).getShoppingListsFromFirebase(true);
    ref.read(firebaseAuthProvider).setCurrentUserCredentials();
  }

  void _createNewShoppingList(BuildContext context, WidgetRef ref) {
    final toolsVM = ref.read(toolsProvider);
    final firebaseVM = ref.read(firebaseProvider);
    final shoppingListsVM = ref.read(shoppingListsProvider);
    if (toolsVM.newListNameController.text != "") {
      String id = nanoid();
      firebaseVM.putShoppingListToFirebase(
          toolsVM.newListNameController.text, toolsVM.newListImportance, id);
      shoppingListsVM.saveNewShoppingListLocally(
          toolsVM.newListNameController.text, toolsVM.newListImportance, id);
    }
  }

  void _openCreateListDialog(BuildContext context, WidgetRef ref) {
    ref.read(toolsProvider).resetNewListData();
    showDialog(
      context: context,
      builder: (context) =>
          PutShoppingListData(_createNewShoppingList, context),
    );
  }

  void _openEditListDialog(BuildContext context, WidgetRef ref, int index) {
    final shoppingListsVM = ref.read(shoppingListsProvider);
    final firebaseAuthVM = ref.read(firebaseAuthProvider);
    final toolsVM = ref.read(toolsProvider);
    final list = shoppingListsVM.shoppingLists[index];
    // Tylko owner może edytować listę.
    if (list.ownerId != firebaseAuthVM.currentUser.userId) return;
    shoppingListsVM.currentListIndex = index;
    toolsVM.newListImportance = list.importance;
    toolsVM.setNewListNameControllerText(list.name);
    showDialog(
      context: context,
      builder: (_) => PutShoppingListData(
        (ctx, r) => _updateShoppingList(ctx, r),
        context,
      ),
    );
  }

  void _updateShoppingList(BuildContext context, WidgetRef ref) {
    if (ref.read(toolsProvider).newListNameController.text != "") {
      final firebaseVM = ref.read(firebaseProvider);
      final toolsVM = ref.read(toolsProvider);
      final shoppingListsVM = ref.read(shoppingListsProvider);
      firebaseVM.updateShoppingListToFirebase(
          toolsVM.newListNameController.text,
          toolsVM.newListImportance,
          shoppingListsVM
              .shoppingLists[shoppingListsVM.currentListIndex].documentId);
      shoppingListsVM.updateExistingShoppingListLocally(
          toolsVM.newListNameController.text,
          toolsVM.newListImportance,
          shoppingListsVM.currentListIndex);
    }
  }

  void _deleteShoppingList(WidgetRef ref, int index) {
    final firebaseVM = ref.read(firebaseProvider);
    final shoppingListsVM = ref.read(shoppingListsProvider);
    final list = shoppingListsVM.shoppingLists[index];
    firebaseVM.deleteShoppingListOnFirebase(list.documentId);
    shoppingListsVM.deleteShoppingListLocally(index);
  }

  void _unshareSharedList(WidgetRef ref, int index) {
    final firebaseVM = ref.read(firebaseProvider);
    final shoppingListsVM = ref.read(shoppingListsProvider);
    final list = shoppingListsVM.shoppingLists[index];
    firebaseVM.unshareListFromMe(list);
    shoppingListsVM.removeSharedListLocally(list.documentId);
  }

  void _onTapShoppingListButton(
      BuildContext context, int index, WidgetRef ref) {
    final shoppingListsVM = ref.read(shoppingListsProvider);
    shoppingListsVM.currentListIndex = index;
    shoppingListsVM.sortShoppingListItemsDisplay();
    _navigateToShoppingList(context);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shoppingListsVM = ref.watch(shoppingListsProvider);
    final toolsVM = ref.watch(toolsProvider);
    return SafeArea(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          const SizedBox(height: 5),
          Text(context.l10n.appName,
              style: Theme.of(context).primaryTextTheme.displaySmall),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ShoppingListTypeChangeButton(
                  context.l10n.myLists,
                  ShoppingListType.ownShoppingLists,
                  Icons.list,
                ),
                ShoppingListTypeChangeButton(
                  context.l10n.sharedLists,
                  ShoppingListType.sharedShoppingLists,
                  Icons.people_alt,
                ),
              ],
            ),
          ),
          const SizedBox(height: 5),
          Expanded(
            child: GestureDetector(
              onPanUpdate: (details) {
                if (details.delta.dx > 0) {
                  shoppingListsVM.currentlyDisplayedListType =
                      ShoppingListType.ownShoppingLists;
                }
                if (details.delta.dx < 0) {
                  shoppingListsVM.currentlyDisplayedListType =
                      ShoppingListType.sharedShoppingLists;
                }
              },
              child: toolsVM.fetchStatus == FetchStatus.fetched ||
                      toolsVM.refreshStatus == RefreshStatus.duringRefresh
                  ? LiquidPullToRefresh(
                      backgroundColor: Theme.of(context).colorScheme.secondary,
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
                                const SizedBox(height: 10),
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Center(
                                    child: Text(
                                      shoppingListsVM.currentlyDisplayedListType ==
                                              ShoppingListType.ownShoppingLists
                                          ? context.l10n.noListsMsg
                                          : context.l10n.noSharedListsMsg,
                                      style: Theme.of(context)
                                          .primaryTextTheme
                                          .bodyLarge,
                                    ),
                                  ),
                                ),
                                if (shoppingListsVM.currentlyDisplayedListType ==
                                    ShoppingListType.ownShoppingLists)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8.0, vertical: 8.0),
                                    child: _AddShoppingListTile(
                                      onTap: () =>
                                          _openCreateListDialog(context, ref),
                                    ),
                                  ),
                              ],
                            ),
                    )
                  : const Column(
                      children: [
                        SizedBox(
                            height: 30,
                            width: 30,
                            child: CircularProgressIndicator()),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget shoppingLists(BuildContext context, WidgetRef ref) {
    final shoppingListsVM = ref.watch(shoppingListsProvider);
    final isOwn = shoppingListsVM.currentlyDisplayedListType ==
        ShoppingListType.ownShoppingLists;
    final listLength = shoppingListsVM.shoppingLists.length;
    final itemCount = isOwn ? listLength + 1 : listLength;
    return SlidableAutoCloseBehavior(
      child: ListView.builder(
        itemCount: itemCount,
        itemBuilder: (context, index) {
          if (isOwn && index == listLength) {
            return Padding(
              key: const ValueKey('__add_new_list_tile__'),
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: _AddShoppingListTile(
                onTap: () => _openCreateListDialog(context, ref),
              ),
            );
          }
          final list = shoppingListsVM.shoppingLists[index];
          return Padding(
            key: ValueKey('list-${list.documentId}'),
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Slidable(
              key: ValueKey('slidable-${list.documentId}'),
              startActionPane: isOwn
                  ? SlidableActions.editPane(
                      onEdit: () => _openEditListDialog(context, ref, index),
                    )
                  : null,
              endActionPane: isOwn
                  ? SlidableActions.deletePane(
                      onDelete: () => _deleteShoppingList(ref, index),
                      confirm: () => SlidableActions.confirmDialog(
                        context,
                        context.l10n.removeListTitle(list.name),
                      ),
                    )
                  : SlidableActions.deletePane(
                      icon: Icons.link_off,
                      onDelete: () => _unshareSharedList(ref, index),
                      confirm: () => SlidableActions.confirmDialog(
                        context,
                        context.l10n.unshareListTitle(list.name),
                      ),
                    ),
              child: ShoppingListButton(
                () => _onTapShoppingListButton(context, index, ref),
                index,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _AddShoppingListTile extends StatelessWidget {
  const _AddShoppingListTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Mapuje wysokość + marginesy ShoppingListButton.
    // Radius 12 = Material 3 Card default (używany przez ShoppingListButton).
    return SizedBox(
      height: 60,
      child: Card(
        color: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: AppColors.brandPink, width: 1.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.add, color: AppColors.brandPink, size: 22),
                const SizedBox(width: 8),
                Text(
                  context.l10n.newList,
                  style: const TextStyle(
                    fontFamily: 'Epilogue',
                    color: AppColors.brandPink,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
