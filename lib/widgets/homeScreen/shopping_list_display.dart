import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';
import 'package:shoqlist/constants/app_colors.dart';
import 'package:shoqlist/l10n/l10n_extension.dart';
import 'package:shoqlist/main.dart';
import 'package:shoqlist/models/shopping_list.dart';
import 'package:shoqlist/widgets/components/edit_item_dialog.dart';
import 'package:shoqlist/widgets/components/forms.dart';
import 'package:shoqlist/widgets/components/manage_access_dialog.dart';
import 'package:shoqlist/widgets/components/native_ad_banner.dart';
import 'package:shoqlist/widgets/components/slidable_actions.dart';

class ShoppingListDisplay extends ConsumerWidget {
  const ShoppingListDisplay({super.key});

  void _addNewItemToCurrentShoppingList(BuildContext context, WidgetRef ref) {
    final toolsVM = ref.read(toolsProvider);
    final firebaseVM = ref.read(firebaseProvider);
    final shoppingListsVM = ref.read(shoppingListsProvider);
    if (toolsVM.newItemNameController.text != "") {
      firebaseVM.addNewItemToShoppingListOnFirebase(
          toolsVM.newItemNameController.text,
          shoppingListsVM
              .shoppingLists[shoppingListsVM.currentListIndex].documentId,
          shoppingListsVM
              .shoppingLists[shoppingListsVM.currentListIndex].ownerId);
      shoppingListsVM.addNewItemToShoppingListLocally(
          toolsVM.newItemNameController.text, false, false);
    }
    toolsVM.clearNewItemTextEditingController();
    FocusManager.instance.primaryFocus?.unfocus();
  }

  void _onRefresh(WidgetRef ref, String documentId, String ownerId) {
    ref.read(firebaseProvider).fetchOneShoppingList(documentId, ownerId);
  }

  Future<void> _copyListToClipboard(
      BuildContext context, WidgetRef ref) async {
    final shoppingListsVM = ref.read(shoppingListsProvider);
    await Clipboard.setData(
      ClipboardData(text: shoppingListsVM.getCurrentShoppingListDataInString()),
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.l10n.copiedToClipboard),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _openManageAccessDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => const ManageAccessDialog(),
    );
  }

  void _openEditItemDialog(
      BuildContext context, WidgetRef ref, int itemIndex) {
    final shoppingListsVM = ref.read(shoppingListsProvider);
    final list = shoppingListsVM.shoppingLists[shoppingListsVM.currentListIndex];
    if (itemIndex < 0 || itemIndex >= list.list.length) return;
    final currentName = list.list[itemIndex].itemName;
    showDialog(
      context: context,
      builder: (_) => EditItemDialog(
        initialName: currentName,
        onSave: (newName) {
          ref.read(firebaseProvider).updateShoppingListItemNameOnFirebase(
                newName,
                itemIndex,
                list.documentId,
                list.ownerId,
              );
          shoppingListsVM.updateShoppingListItemNameLocally(
            shoppingListsVM.currentListIndex,
            itemIndex,
            newName,
          );
        },
      ),
    );
  }

  void _deleteItemInstant(WidgetRef ref, int itemIndex) {
    final shoppingListsVM = ref.read(shoppingListsProvider);
    final firebaseVM = ref.read(firebaseProvider);
    final list = shoppingListsVM.shoppingLists[shoppingListsVM.currentListIndex];
    firebaseVM.deleteShoppingListItemOnFirebase(
      itemIndex,
      list.documentId,
      list.ownerId,
    );
    shoppingListsVM.deleteItemFromShoppingListLocally(itemIndex);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shoppingListsVM = ref.watch(shoppingListsProvider);
    final toolsVM = ref.watch(toolsProvider);
    final firebaseAuthVM = ref.watch(firebaseAuthProvider);
    final currentList =
        shoppingListsVM.shoppingLists[shoppingListsVM.currentListIndex];
    final currentListImportanceColor =
        toolsVM.getImportanceColor(currentList.importance);
    final isOwner = currentList.ownerId == firebaseAuthVM.currentUser.userId;
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 12),
            // Tytuł samotny, max 2 linie, ellipsis — wraca do poprzedniego designu
            Container(
              width: screenSize.width,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                currentList.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context)
                    .primaryTextTheme
                    .headlineMedium!
                    .copyWith(color: currentListImportanceColor),
              ),
            ),
            const SizedBox(height: 4),
            _HeaderActionsRow(
              isOwner: isOwner,
              importanceColor: currentListImportanceColor,
              ownerName: currentList.ownerName,
              onCopy: () => _copyListToClipboard(context, ref),
              onManageAccess: () => _openManageAccessDialog(context),
            ),
            Expanded(
              child: LiquidPullToRefresh(
                backgroundColor: currentListImportanceColor,
                color: Theme.of(context).primaryColor,
                height: 50,
                animSpeedFactor: 5,
                showChildOpacityTransition: false,
                onRefresh: () async {
                  _onRefresh(ref, currentList.documentId, currentList.ownerId);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: shoppingList(context, ref, isOwner),
                ),
              ),
            ),
            _NewItemInput(
              onAdd: () => _addNewItemToCurrentShoppingList(context, ref),
            ),
          ],
        ),
      ),
    );
  }

  Widget shoppingList(BuildContext context, WidgetRef ref, bool isOwner) {
    final shoppingListsVM = ref.watch(shoppingListsProvider);
    final firebaseVM = ref.watch(firebaseProvider);
    ShoppingList shoppingList =
        shoppingListsVM.shoppingLists[shoppingListsVM.currentListIndex];
    // CustomScrollView + SliverList + SliverToBoxAdapter: banner jako sibling
    // (nie lazy item ListView.builder) — SliverToBoxAdapter renderuje widget
    // raz i nie mountuje go ponownie przy scrollu. NativeAdBanner zachowuje
    // state i nie wielokrotnie ładuje reklamy.
    return SlidableAutoCloseBehavior(
      child: CustomScrollView(
        slivers: [
          SliverList.builder(
            itemCount: shoppingList.list.length,
            itemBuilder: (context, index) {
              final item = shoppingList.list[index];
              // Stable key oparty tylko o documentId + index (bez itemName),
              // żeby nie rekonstruować tile przy edycji nazwy.
              return Padding(
                key: ValueKey('${shoppingList.documentId}-item-$index'),
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Slidable(
                  key: ValueKey(
                      '${shoppingList.documentId}-slidable-$index'),
                  startActionPane: SlidableActions.editPane(
                    onEdit: () => _openEditItemDialog(context, ref, index),
                    dismissThreshold: 0.3,
                  ),
                  endActionPane: SlidableActions.deletePane(
                    onDelete: () => _deleteItemInstant(ref, index),
                    dismissThreshold: 0.3,
                  ),
                  child: _ShoppingListItemTile(
                    itemName: item.itemName,
                    gotItem: item.gotItem,
                    isFavorite: item.isFavorite,
                    onToggleGot: () {
                      shoppingListsVM.pickedListItemIndex = index;
                      firebaseVM.toggleStateOfShoppingListItemOnFirebase(
                        shoppingList.documentId,
                        index,
                        shoppingList.ownerId,
                      );
                      shoppingListsVM.toggleItemStateLocally(
                          shoppingListsVM.currentListIndex, index);
                    },
                    onToggleFavorite: () {
                      firebaseVM.toggleFavoriteOfShoppingListItemOnFirebase(
                        shoppingList.documentId,
                        index,
                        shoppingList.ownerId,
                      );
                      shoppingListsVM.toggleItemFavoriteLocally(
                          shoppingListsVM.currentListIndex, index);
                    },
                  ),
                ),
              );
            },
          ),
          // SliverList (a nie SliverToBoxAdapter) szanuje
          // AutomaticKeepAliveClientMixin w NativeAdBanner — dzięki temu
          // banner pozostaje mounted po scroll poza viewport i nie ładuje
          // reklamy ponownie.
          SliverList.list(
            children: [
              Padding(
                key: const ValueKey('__native_ad_banner_tile__'),
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Card(
                  color: Theme.of(context).listTileTheme.tileColor,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const NativeAdBanner(inFeedStyle: true),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderActionsRow extends StatelessWidget {
  const _HeaderActionsRow({
    required this.isOwner,
    required this.importanceColor,
    required this.ownerName,
    required this.onCopy,
    required this.onManageAccess,
  });

  final bool isOwner;
  final Color importanceColor;
  final String ownerName;
  final VoidCallback onCopy;
  final VoidCallback onManageAccess;

  @override
  Widget build(BuildContext context) {
    if (isOwner) {
      // Własna lista — brak info o ownerze (wiadomo że nasza), ikonki po prawej.
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            IconButton(
              icon: const Icon(Icons.copy_outlined),
              color: AppColors.brandPink,
              tooltip: context.l10n.copiedToClipboard,
              onPressed: onCopy,
            ),
            IconButton(
              icon: const Icon(Icons.people_outline),
              color: AppColors.brandPink,
              tooltip: context.l10n.whoHasAccess,
              onPressed: onManageAccess,
            ),
          ],
        ),
      );
    }
    // Shared list — copy po lewej, Owner: X po prawej (spaceBetween).
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.copy_outlined),
            color: AppColors.brandPink,
            tooltip: context.l10n.copiedToClipboard,
            onPressed: onCopy,
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 8, right: 12),
              child: Text(
                "${context.l10n.owner}: $ownerName",
                textAlign: TextAlign.end,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      color: importanceColor,
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShoppingListItemTile extends StatelessWidget {
  const _ShoppingListItemTile({
    required this.itemName,
    required this.gotItem,
    required this.isFavorite,
    required this.onToggleGot,
    required this.onToggleFavorite,
  });

  final String itemName;
  final bool gotItem;
  final bool isFavorite;
  final VoidCallback onToggleGot;
  final VoidCallback onToggleFavorite;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggleGot,
      child: Card(
        color: Theme.of(context).listTileTheme.tileColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        child: Container(
          constraints: const BoxConstraints(minHeight: 50),
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              Icon(
                gotItem ? Icons.radio_button_checked : Icons.radio_button_off,
                color: Theme.of(context).listTileTheme.iconColor,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  itemName,
                  style: TextStyle(
                    color: Colors.black,
                    decoration: gotItem
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                  ),
                ),
              ),
              GestureDetector(
                onTap: onToggleFavorite,
                child: Icon(
                  isFavorite ? Icons.star : Icons.star_border_outlined,
                  color: Theme.of(context).listTileTheme.iconColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NewItemInput extends ConsumerWidget {
  const _NewItemInput({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final toolsVM = ref.watch(toolsProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    return Container(
      color: Theme.of(context).colorScheme.surface,
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
      child: BasicForm(
        key: toolsVM.addNewItemNameFormFieldKey,
        width: screenWidth - 16,
        keyboardType: TextInputType.name,
        controller: toolsVM.newItemNameController,
        focusNode: toolsVM.newItemFocusNode,
        decoration: InputDecoration(
          suffixIcon: GestureDetector(
            onTap: () {
              onAdd();
              toolsVM.clearNewItemTextEditingController();
              toolsVM.newItemFocusNode.requestFocus();
            },
            child: Icon(
              Icons.add,
              color: Theme.of(context).colorScheme.secondary,
            ),
          ),
          fillColor: Colors.grey[600],
          hintText: context.l10n.itemNameHint,
          hintStyle: Theme.of(context).primaryTextTheme.bodyMedium,
          contentPadding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(
              width: 1,
              color: Theme.of(context).primaryColorDark,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(
              width: 1,
              color: Theme.of(context).colorScheme.secondary,
            ),
          ),
        ),
        onSubmitted: (ref, value) {
          onAdd();
          toolsVM.clearNewItemTextEditingController();
          toolsVM.newItemFocusNode.requestFocus();
        },
        style: Theme.of(context).textTheme.bodyLarge!,
      ),
    );
  }
}
