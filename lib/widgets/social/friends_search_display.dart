import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shoqlist/models/user.dart';
import 'package:shoqlist/widgets/components/empty_state.dart';
import 'package:shoqlist/widgets/components/forms.dart';
import 'package:shoqlist/widgets/components/screen_header.dart';
import 'package:shoqlist/widgets/social/users_list.dart';
import 'package:shoqlist/l10n/l10n_extension.dart';

import '../../main.dart';
import '../../viewmodels/tools.dart';

class FriendsSearchDisplay extends ConsumerWidget {
  const FriendsSearchDisplay({super.key});

  void _sendFriendRequestAfterTap(BuildContext context, WidgetRef ref) {
    final firebaseVM = ref.read(firebaseProvider);
    final friendsServiceVM = ref.read(friendsServiceProvider);
    User user = friendsServiceVM.usersList[friendsServiceVM.currentUserIndex!];
    firebaseVM.sendFriendRequest(user);
    Navigator.of(context).pop();
  }

  void _searchForFriend(WidgetRef ref, String value) {
    if (value.trim().isEmpty) return;
    ref.read(firebaseProvider).searchForUser(value);
  }

  void _onChanged(BuildContext context, WidgetRef ref) {
    ref.read(toolsProvider).friendsFetchStatus = FetchStatus.unfetched;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final toolsVM = ref.watch(toolsProvider);
    final friendsServiceVM = ref.watch(friendsServiceProvider);
    final controller = friendsServiceVM.searchFriendTextController;
    final fetchStatus = toolsVM.friendsFetchStatus;
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            ScreenHeader(
              title: context.l10n.searchFriends,
              showBackButton: true,
            ),
            const SizedBox(height: 12),
            // Pełna szerokość z 16px marginesem po bokach — pasuje do reszty
            // apki (header / itemy / settings cards mają tę samą szerokość).
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: BasicForm(
                width: double.infinity,
                keyboardType: TextInputType.emailAddress,
                controller: controller,
                hintText: context.l10n.email,
                onChanged: _onChanged,
                prefixIcon: Icons.email_outlined,
                onSubmitted: _searchForFriend,
                suffixIcon: _SearchSubmitButton(
                  onTap: () => _searchForFriend(ref, controller.text),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _SearchBody(
                fetchStatus: fetchStatus,
                users: friendsServiceVM.usersList,
                searchedEmail: controller.text.trim(),
                onSendRequest: _sendFriendRequestAfterTap,
                dialogTitle: context.l10n.sendFriendRequestTitle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchSubmitButton extends StatelessWidget {
  const _SearchSubmitButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(right: 8),
        child: Icon(
          Icons.search,
          color: Theme.of(context).colorScheme.secondary,
        ),
      ),
    );
  }
}

/// Empty-state vs loading vs results dispatcher. Każdy stan ma jasną
/// hierarchię wizualną: duża ikona + krótki tekst hint, żeby ekran nie
/// wyglądał na wybrakowany przy pierwszym otwarciu.
///
/// `searchForUser` w FirebaseViewModel filtruje już-friendów i pending
/// requests z usersList — bez różnicowania komunikatu user widziałby
/// "Can't find user" mimo że osoba istnieje. Dispatcher rozpoznaje
/// te przypadki czytając listy z `friendsServiceProvider`.
class _SearchBody extends ConsumerWidget {
  const _SearchBody({
    required this.fetchStatus,
    required this.users,
    required this.searchedEmail,
    required this.onSendRequest,
    required this.dialogTitle,
  });

  final FetchStatus fetchStatus;
  final List<User> users;
  final String searchedEmail;
  final Function onSendRequest;
  final String dialogTitle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (fetchStatus == FetchStatus.duringFetching) {
      return const Center(
        child: SizedBox(
          width: 32,
          height: 32,
          child: CircularProgressIndicator(strokeWidth: 3),
        ),
      );
    }
    if (fetchStatus == FetchStatus.unfetched) {
      // Pierwsze wejście — nic jeszcze nie wpisano. Pokażemy ikonę + hint
      // co user może zrobić. Bez tego ekran wyglądał goły.
      return EmptyState(
        icon: Icons.person_search_outlined,
        message: context.l10n.searchFriends,
      );
    }
    // fetched — wynik lub brak wyniku.
    if (users.isEmpty) {
      final friendsServiceVM = ref.read(friendsServiceProvider);
      final emailLower = searchedEmail.toLowerCase();
      final isAlreadyFriend = emailLower.isNotEmpty &&
          friendsServiceVM.friendsList
              .any((f) => f.email.toLowerCase() == emailLower);
      final isPendingRequest = emailLower.isNotEmpty &&
          friendsServiceVM.friendRequestsList
              .any((r) => r.email.toLowerCase() == emailLower);
      if (isAlreadyFriend) {
        return EmptyState(
          icon: Icons.how_to_reg_outlined,
          message: context.l10n.userAlreadyFriendMsg,
        );
      }
      if (isPendingRequest) {
        return EmptyState(
          icon: Icons.hourglass_empty,
          message: context.l10n.friendRequestAlreadyPendingMsg,
        );
      }
      return EmptyState(
        icon: Icons.search_off,
        message: context.l10n.cantFindUserMsg,
      );
    }
    return UsersList(onSendRequest, users, dialogTitle);
  }
}
