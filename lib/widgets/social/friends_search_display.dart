import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shoqlist/models/user.dart';
import 'package:shoqlist/widgets/components/forms.dart';
import 'package:shoqlist/widgets/social/users_list.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../main.dart';
import '../../viewmodels/tools.dart';

class FriendsSearchDisplay extends ConsumerWidget {
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

  Widget build(BuildContext context, WidgetRef ref) {
    final toolsVM = ref.watch(toolsProvider);
    final friendsServiceVM = ref.watch(friendsServiceProvider);
    final screenSize = MediaQuery.of(context).size;
    return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.background,
        body: SafeArea(
          child: Stack(
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20.0),
                    width: screenSize.width,
                    child: Text(AppLocalizations.of(context)!.searchFriends,
                        style: Theme.of(context).primaryTextTheme.headlineMedium),
                  ),
                  BasicForm(
                    keyboardType: TextInputType.emailAddress,
                    controller: friendsServiceVM.searchFriendTextController,
                    hintText: AppLocalizations.of(context)!.email,
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
                                  AppLocalizations.of(context)!.cantFindUserMsg,
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
                            AppLocalizations.of(context)!
                                .sendFriendRequestTitle,
                          ),
                  )
                ],
              ),
            ],
          ),
        ));
  }
}
