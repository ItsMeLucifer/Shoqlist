import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';
import 'package:shoqlist/widgets/social/users_list.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../main.dart';

class FriendRequestsDisplay extends ConsumerWidget {
  void _acceptFriendRequestAfterTap(BuildContext context, WidgetRef ref) {
    final firebaseVM = ref.read(firebaseProvider);
    final friendsServiceVM = ref.read(friendsServiceProvider);
    firebaseVM.acceptFriendRequest(friendsServiceVM
        .friendRequestsList[friendsServiceVM.currentUserIndex!]);
    Navigator.of(context).pop();
  }

  void _declineFriendRequestAfterTap(BuildContext context, WidgetRef ref) {
    final firebaseVM = ref.read(firebaseProvider);
    final friendsServiceVM = ref.read(friendsServiceProvider);
    firebaseVM.declineFriendRequest(friendsServiceVM
        .friendRequestsList[friendsServiceVM.currentUserIndex!]);
    Navigator.of(context).pop();
  }

  void _onRefresh(WidgetRef ref) {
    ref.read(firebaseProvider).fetchFriendRequestsList();
  }

  Widget build(BuildContext context, WidgetRef ref) {
    final friendsServiceVM = ref.watch(friendsServiceProvider);
    final screenSize = MediaQuery.of(context).size;
    return Scaffold(
        backgroundColor: Theme.of(context).backgroundColor,
        body: SafeArea(
          child: Stack(
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20.0),
                    width: screenSize.width,
                    child: Text(
                      AppLocalizations.of(context)!.friendRequests,
                      style: Theme.of(context).primaryTextTheme.headline4,
                    ),
                  ),
                  Expanded(
                    child: LiquidPullToRefresh(
                      backgroundColor: Theme.of(context).colorScheme.secondary,
                      color: Theme.of(context).primaryColor,
                      height: 50,
                      animSpeedFactor: 5,
                      showChildOpacityTransition: false,
                      onRefresh: () async {
                        _onRefresh(ref);
                      },
                      child: friendsServiceVM.friendRequestsList.isEmpty
                          ? ListView(
                              children: [
                                SizedBox(height: 10),
                                Center(
                                  child: Text(
                                    AppLocalizations.of(context)!
                                        .noFriendRequestsMsg,
                                    style: Theme.of(context)
                                        .primaryTextTheme
                                        .bodyText1,
                                  ),
                                )
                              ],
                            )
                          : UsersList(
                              _acceptFriendRequestAfterTap,
                              friendsServiceVM.friendRequestsList,
                              AppLocalizations.of(context)!
                                  .acceptFriendRequestTitle,
                              _declineFriendRequestAfterTap,
                            ),
                    ),
                  )
                ],
              ),
            ],
          ),
        ));
  }
}
