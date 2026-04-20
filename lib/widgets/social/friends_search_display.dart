import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shoqlist/models/user.dart';
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
    ref.read(firebaseProvider).searchForUser(value);
  }

  void _onChanged(BuildContext context, WidgetRef ref) {
    ref.read(toolsProvider).friendsFetchStatus = FetchStatus.unfetched;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final toolsVM = ref.watch(toolsProvider);
    final friendsServiceVM = ref.watch(friendsServiceProvider);
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
              const SizedBox(height: 8),
              BasicForm(
                    keyboardType: TextInputType.emailAddress,
                    controller: friendsServiceVM.searchFriendTextController,
                    hintText: context.l10n.email,
                    onChanged: _onChanged,
                    prefixIcon: Icons.email,
                    onSubmitted: _searchForFriend,
                  ),
                  SizedBox(height: 5),
              Expanded(
                child: friendsServiceVM.usersList.isEmpty &&
                        toolsVM.friendsFetchStatus == FetchStatus.fetched
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Center(
                              child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              context.l10n.cantFindUserMsg,
                              style: Theme.of(context)
                                  .primaryTextTheme
                                  .bodyLarge,
                              textAlign: TextAlign.center,
                            ),
                          )),
                        ],
                      )
                    : UsersList(
                        _sendFriendRequestAfterTap,
                        friendsServiceVM.usersList,
                        context.l10n.sendFriendRequestTitle,
                      ),
              )
            ],
          ),
        ));
  }
}
