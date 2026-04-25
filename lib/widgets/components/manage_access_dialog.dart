import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shoqlist/constants/app_colors.dart';
import 'package:shoqlist/l10n/l10n_extension.dart';
import 'package:shoqlist/main.dart';
import 'package:shoqlist/models/shopping_list.dart';
import 'package:shoqlist/models/user.dart';

/// Merged grant/revoke dialog. Wyświetla wszystkich friendów; tap na userze
/// z accessem → revoke, tap na bez accessu → grant. Dialog zostaje otwarty —
/// user może toggle'ować wielu i kliknąć Done na koniec.
class ManageAccessDialog extends ConsumerWidget {
  const ManageAccessDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shoppingListsVM = ref.watch(shoppingListsProvider);
    final friendsServiceVM = ref.watch(friendsServiceProvider);
    final currentList =
        shoppingListsVM.shoppingLists[shoppingListsVM.currentListIndex];
    final accessUserIds =
        currentList.usersWithAccess.map((u) => u.userId).toSet();
    final friends = friendsServiceVM.friendsList;

    return AlertDialog(
      backgroundColor: AppColors.surfaceGrayWarm,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        context.l10n.whoHasAccess,
        style: Theme.of(context).primaryTextTheme.headlineSmall,
        textAlign: TextAlign.center,
      ),
      contentPadding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
      content: SizedBox(
        width: double.maxFinite,
        child: friends.isEmpty
            ? Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  context.l10n.chooseUserEmptyMessage,
                  style: Theme.of(context).primaryTextTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              )
            : ListView.builder(
                shrinkWrap: true,
                itemCount: friends.length,
                itemBuilder: (_, index) {
                  final friend = friends[index];
                  final hasAccess = accessUserIds.contains(friend.userId);
                  return _FriendAccessTile(
                    friend: friend,
                    hasAccess: hasAccess,
                    onToggle: () => _toggleAccess(
                      ref,
                      friend,
                      currentList,
                      hasAccess,
                    ),
                  );
                },
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.l10n.ok),
        ),
      ],
    );
  }

  void _toggleAccess(
    WidgetRef ref,
    User friend,
    ShoppingList list,
    bool hasAccess,
  ) {
    final firebaseVM = ref.read(firebaseProvider);
    final shoppingListsVM = ref.read(shoppingListsProvider);
    if (hasAccess) {
      firebaseVM.denyFriendAccessToYourShoppingList(
          friend, list.documentId, list.usersWithAccess);
      shoppingListsVM.removeUserFromUsersWithAccessList(friend);
    } else {
      firebaseVM.giveFriendAccessToYourShoppingList(friend, list.documentId);
      shoppingListsVM.addUserToUsersWithAccessList(friend);
    }
  }
}

class _FriendAccessTile extends StatelessWidget {
  const _FriendAccessTile({
    required this.friend,
    required this.hasAccess,
    required this.onToggle,
  });

  final User friend;
  final bool hasAccess;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
      tileColor: AppColors.surfaceGrayWarm,
      title: Text(
        friend.nickname,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).primaryTextTheme.titleLarge,
      ),
      subtitle: Text(
        friend.email,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).primaryTextTheme.bodyMedium,
      ),
      trailing: Icon(
        hasAccess ? Icons.check_circle : Icons.add_circle_outline,
        color: hasAccess ? AppColors.brandPink : Colors.grey[500],
        size: 28,
      ),
      onTap: onToggle,
    );
  }
}
