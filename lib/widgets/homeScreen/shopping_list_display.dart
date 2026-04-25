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
import 'package:shoqlist/widgets/components/slidable_actions.dart';

class ShoppingListDisplay extends ConsumerStatefulWidget {
  const ShoppingListDisplay({super.key});

  @override
  ConsumerState<ShoppingListDisplay> createState() =>
      _ShoppingListDisplayState();
}

class _ShoppingListDisplayState extends ConsumerState<ShoppingListDisplay> {
  // Capture'ujemy service / notifier raz w initState. Używanie `ref.read`
  // w dispose() jest podatne na error gdy widget jest unmount'owany
  // w trakcie buildu drzewa rodzica — captured ref jest stabilny przez
  // całe życie widgetu.
  late final _syncService = ref.read(listSyncServiceProvider);
  late final _accentNotifier = ref.read(accentColorProvider.notifier);

  @override
  void initState() {
    super.initState();
    // Real-time sub na aktualnie wyświetlaną listę + ustawienie accent.
    // PostFrame żeby provider tree był gotowy i żeby uniknąć
    // "modify provider during build" — accent state musi być ustawiony
    // PO zakończeniu pierwszego buildu MainScaffolda który go obserwuje.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final vm = ref.read(shoppingListsProvider);
      final toolsVM = ref.read(toolsProvider);
      final idx = vm.currentListIndex;
      if (idx < 0 || idx >= vm.shoppingLists.length) return;
      final list = vm.shoppingLists[idx];
      _syncService.startDetail(list.ownerId, list.documentId);
      _accentNotifier.state = toolsVM.getImportanceColor(list.importance);
    });
  }

  @override
  void dispose() {
    _syncService.stopDetail();
    // Reset accent na default — ALE poza widget tree teardown. Riverpod
    // blokuje modyfikacje providerów w dispose (tak samo jak w initState/build);
    // zmiana state'u w trakcie `_unmount` rzucała StateNotifierListenerError.
    // Microtask odracza to o jeden tick → MainScaffold listener dostanie
    // update'a po zakończeniu cleanup'u.
    final notifier = _accentNotifier;
    Future.microtask(() => notifier.state = AppColors.brandPink);
    super.dispose();
  }

  void _addNewItemToCurrentShoppingList(BuildContext context, WidgetRef ref) {
    final toolsVM = ref.read(toolsProvider);
    final firebaseVM = ref.read(firebaseProvider);
    final shoppingListsVM = ref.read(shoppingListsProvider);
    final text = toolsVM.newItemNameController.text.trim();
    // Clear pola od razu — nawet jeśli którakolwiek z dalszych operacji
    // rzuci wyjątkiem, input jest czysty i user nie musi ręcznie kasować.
    toolsVM.clearNewItemTextEditingController();
    if (text.isEmpty) return;
    final list = shoppingListsVM
        .shoppingLists[shoppingListsVM.currentListIndex];
    final onSyncFail = _captureSyncFailureReporter(context);
    final newItem =
        shoppingListsVM.addNewItemToShoppingListLocally(text, false, false);
    if (newItem == null) return;
    firebaseVM
        .addNewItemToShoppingListOnFirebase(
          item: newItem,
          documentId: list.documentId,
          ownerId: list.ownerId,
        )
        .catchError((_) => onSyncFail());
  }

  Future<void> _onRefresh(
      WidgetRef ref, String documentId, String ownerId) async {
    // Czekamy na rozliczenie pending Firestore transactions PRZED fetch.
    // Bez tego: klikasz szybko 5 itemów → pull-to-refresh → read widzi stan
    // sprzed Twoich transakcji → updateCurrentShoppingList nadpisuje lokalne
    // taps. Tracker zapewnia że refresh zawsze widzi już-skommitowany stan.
    final firebaseVM = ref.read(firebaseProvider);
    await firebaseVM.pendingWritesTracker.flushList(documentId);
    await firebaseVM.fetchOneShoppingList(documentId, ownerId);
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
      BuildContext context, WidgetRef ref, String itemId) {
    final shoppingListsVM = ref.read(shoppingListsProvider);
    final list = shoppingListsVM.shoppingLists[shoppingListsVM.currentListIndex];
    final itemIndex =
        shoppingListsVM.indexOfItemById(shoppingListsVM.currentListIndex, itemId);
    if (itemIndex < 0) return;
    final currentName = list.list[itemIndex].itemName;
    final onSyncFail = _captureSyncFailureReporter(context);
    showDialog(
      context: context,
      builder: (_) => EditItemDialog(
        initialName: currentName,
        onSave: (newName) {
          // Resolve index ponownie — mógł się zmienić podczas otwartego dialogu
          // (inny tap, sort, snapshot). Identity zostaje spójna przez id.
          final idxNow = shoppingListsVM.indexOfItemById(
              shoppingListsVM.currentListIndex, itemId);
          if (idxNow < 0) return;
          shoppingListsVM.updateShoppingListItemNameLocally(
            shoppingListsVM.currentListIndex,
            idxNow,
            newName,
          );
          ref
              .read(firebaseProvider)
              .updateShoppingListItemNameOnFirebase(
                itemId: itemId,
                newName: newName,
                documentId: list.documentId,
                ownerId: list.ownerId,
              )
              .catchError((_) => onSyncFail());
        },
      ),
    );
  }

  void _deleteItemInstant(BuildContext context, WidgetRef ref, String itemId) {
    final shoppingListsVM = ref.read(shoppingListsProvider);
    final firebaseVM = ref.read(firebaseProvider);
    final list = shoppingListsVM.shoppingLists[shoppingListsVM.currentListIndex];
    final itemIndex =
        shoppingListsVM.indexOfItemById(shoppingListsVM.currentListIndex, itemId);
    if (itemIndex < 0) return;
    final onSyncFail = _captureSyncFailureReporter(context);
    shoppingListsVM.deleteItemFromShoppingListLocally(itemIndex);
    firebaseVM
        .deleteShoppingListItemOnFirebase(
          itemId: itemId,
          documentId: list.documentId,
          ownerId: list.ownerId,
        )
        .catchError((_) => onSyncFail());
  }

  void _toggleItemGot(BuildContext context, WidgetRef ref, String itemId) {
    final shoppingListsVM = ref.read(shoppingListsProvider);
    final firebaseVM = ref.read(firebaseProvider);
    final list = shoppingListsVM.shoppingLists[shoppingListsVM.currentListIndex];
    final itemIndex =
        shoppingListsVM.indexOfItemById(shoppingListsVM.currentListIndex, itemId);
    if (itemIndex < 0) return;
    final onSyncFail = _captureSyncFailureReporter(context);
    shoppingListsVM.toggleItemStateLocally(
        shoppingListsVM.currentListIndex, itemIndex);
    // Lokalna mutacja ustawiła już nowy stan — odczyt po id (po sorcie).
    final idxAfter =
        shoppingListsVM.indexOfItemById(shoppingListsVM.currentListIndex, itemId);
    if (idxAfter < 0) return;
    final newState =
        list.list[idxAfter].gotItem;
    firebaseVM
        .toggleStateOfShoppingListItemOnFirebase(
          itemId: itemId,
          newState: newState,
          documentId: list.documentId,
          ownerId: list.ownerId,
        )
        .catchError((_) {
      // Rollback po itemId (po sorcie index mógł się zmienić).
      final idxNow = shoppingListsVM.indexOfItemById(
          shoppingListsVM.currentListIndex, itemId);
      if (idxNow >= 0) {
        shoppingListsVM.toggleItemStateLocally(
            shoppingListsVM.currentListIndex, idxNow);
      }
      onSyncFail();
    });
  }

  void _toggleItemFavorite(BuildContext context, WidgetRef ref, String itemId) {
    final shoppingListsVM = ref.read(shoppingListsProvider);
    final firebaseVM = ref.read(firebaseProvider);
    final list = shoppingListsVM.shoppingLists[shoppingListsVM.currentListIndex];
    final itemIndex =
        shoppingListsVM.indexOfItemById(shoppingListsVM.currentListIndex, itemId);
    if (itemIndex < 0) return;
    final onSyncFail = _captureSyncFailureReporter(context);
    shoppingListsVM.toggleItemFavoriteLocally(
        shoppingListsVM.currentListIndex, itemIndex);
    final idxAfter =
        shoppingListsVM.indexOfItemById(shoppingListsVM.currentListIndex, itemId);
    if (idxAfter < 0) return;
    final newFavorite = list.list[idxAfter].isFavorite;
    firebaseVM
        .toggleFavoriteOfShoppingListItemOnFirebase(
          itemId: itemId,
          newFavorite: newFavorite,
          documentId: list.documentId,
          ownerId: list.ownerId,
        )
        .catchError((_) {
      final idxNow = shoppingListsVM.indexOfItemById(
          shoppingListsVM.currentListIndex, itemId);
      if (idxNow >= 0) {
        shoppingListsVM.toggleItemFavoriteLocally(
            shoppingListsVM.currentListIndex, idxNow);
      }
      onSyncFail();
    });
  }

  // Przed asynchronicznym wywołaniem capture'ujemy ScaffoldMessenger i tekst —
  // po async nie mamy już prawa dotknąć `context`, a analyzer (słusznie)
  // blokuje context-after-await. Messenger jest stabilny nawet gdy tree zmieni.
  VoidCallback _captureSyncFailureReporter(BuildContext context) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    final message = context.l10n.syncFailed;
    return () {
      messenger?.showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    };
  }

  @override
  Widget build(BuildContext context) {
    final shoppingListsVM = ref.watch(shoppingListsProvider);
    final toolsVM = ref.watch(toolsProvider);
    final firebaseAuthVM = ref.watch(firebaseAuthProvider);
    final currentList =
        shoppingListsVM.shoppingLists[shoppingListsVM.currentListIndex];
    final currentListImportanceColor =
        toolsVM.getImportanceColor(currentList.importance);
    final isOwner = currentList.ownerId == firebaseAuthVM.currentUser.userId;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Compact inline header — tytuł + akcje w jednym rzędzie.
            // Wcześniej był osobny rząd (40pt headline 2-line + osobny
            // rząd action ikon + 2 SizedBoxy), co dawało ~96pt+ pustej
            // przestrzeni u góry. Teraz konsoliduje to w 1 rzędzie i daje
            // od razu więcej itemów w viewporcie.
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 8, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          currentList.name,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Epilogue',
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: currentListImportanceColor,
                            height: 1.1,
                          ),
                        ),
                        if (!isOwner && currentList.ownerName.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              "${context.l10n.owner}: ${currentList.ownerName}",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: 'Epilogue',
                                fontSize: 13,
                                color: currentListImportanceColor
                                    .withValues(alpha: 0.75),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  _HeaderActions(
                    isOwner: isOwner,
                    accent: currentListImportanceColor,
                    onCopy: () => _copyListToClipboard(context, ref),
                    onManageAccess: () => _openManageAccessDialog(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: LiquidPullToRefresh(
                backgroundColor: currentListImportanceColor,
                color: Theme.of(context).primaryColor,
                height: 50,
                animSpeedFactor: 5,
                showChildOpacityTransition: false,
                onRefresh: () =>
                    _onRefresh(ref, currentList.documentId, currentList.ownerId),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: shoppingList(context, ref, isOwner),
                ),
              ),
            ),
            _NewItemInput(
              accent: currentListImportanceColor,
              onAdd: () => _addNewItemToCurrentShoppingList(context, ref),
            ),
          ],
        ),
      ),
    );
  }

  Widget shoppingList(BuildContext context, WidgetRef ref, bool isOwner) {
    final shoppingListsVM = ref.watch(shoppingListsProvider);
    ShoppingList shoppingList =
        shoppingListsVM.shoppingLists[shoppingListsVM.currentListIndex];
    return SlidableAutoCloseBehavior(
      child: CustomScrollView(
        slivers: [
          SliverList.builder(
            itemCount: shoppingList.list.length,
            itemBuilder: (context, index) {
              final item = shoppingList.list[index];
              // Key po stabilnym id itemu — po in-place sorcie Flutter
              // zachowuje mapping widget→item, więc gwiazdka/strikethrough
              // faktycznie pojawia się pod palcem a nie "niby nic się nie stało".
              final itemKey = item.id ?? '__noid-$index';
              return Padding(
                key: ValueKey('item-$itemKey'),
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Slidable(
                  key: ValueKey('slidable-$itemKey'),
                  startActionPane: SlidableActions.editPane(
                    onEdit: () => _openEditItemDialog(context, ref, itemKey),
                    dismissThreshold: 0.3,
                  ),
                  endActionPane: SlidableActions.deletePane(
                    onDelete: () => _deleteItemInstant(context, ref, itemKey),
                    dismissThreshold: 0.3,
                  ),
                  child: _ShoppingListItemTile(
                    itemName: item.itemName,
                    gotItem: item.gotItem,
                    isFavorite: item.isFavorite,
                    onToggleGot: () => _toggleItemGot(context, ref, itemKey),
                    onToggleFavorite: () =>
                        _toggleItemFavorite(context, ref, itemKey),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Inline akcje obok tytułu (copy zawsze, manage_access tylko dla ownera).
/// Owner badge dla shared list jest wyświetlany pod tytułem (w build() głównym).
class _HeaderActions extends StatelessWidget {
  const _HeaderActions({
    required this.isOwner,
    required this.accent,
    required this.onCopy,
    required this.onManageAccess,
  });

  final bool isOwner;
  final Color accent;
  final VoidCallback onCopy;
  final VoidCallback onManageAccess;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.copy_outlined),
          color: accent,
          tooltip: context.l10n.copiedToClipboard,
          onPressed: onCopy,
          visualDensity: VisualDensity.compact,
        ),
        if (isOwner)
          IconButton(
            icon: const Icon(Icons.people_outline),
            color: accent,
            tooltip: context.l10n.whoHasAccess,
            onPressed: onManageAccess,
            visualDensity: VisualDensity.compact,
          ),
      ],
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
  const _NewItemInput({required this.onAdd, required this.accent});

  final VoidCallback onAdd;
  final Color accent;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final toolsVM = ref.watch(toolsProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    // Wpisywany tekst też powinien być w accent color — primary palette dla
    // wprowadzania w detail listy. `bodyLarge` z theme jest pinkowy domyślnie;
    // copyWith podmienia kolor na importance accent.
    final inputStyle = Theme.of(context)
        .textTheme
        .bodyLarge!
        .copyWith(color: accent);
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
              toolsVM.newItemFocusNode.requestFocus();
            },
            child: Icon(Icons.add, color: accent),
          ),
          filled: true,
          fillColor: AppColors.inputFill,
          hintText: context.l10n.itemNameHint,
          hintStyle: Theme.of(context).primaryTextTheme.bodyMedium,
          contentPadding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              width: 1,
              color: AppColors.dividerSoft,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(width: 1.5, color: accent),
          ),
        ),
        onSubmitted: (ref, value) {
          onAdd();
          toolsVM.newItemFocusNode.requestFocus();
        },
        style: inputStyle,
      ),
    );
  }
}
