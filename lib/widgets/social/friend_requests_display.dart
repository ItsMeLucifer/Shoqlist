import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';
import 'package:shoqlist/widgets/components/empty_state.dart';
import 'package:shoqlist/widgets/components/screen_header.dart';
import 'package:shoqlist/widgets/social/users_list.dart';
import 'package:shoqlist/l10n/l10n_extension.dart';

import '../../main.dart';

class FriendRequestsDisplay extends ConsumerWidget {
  const FriendRequestsDisplay({super.key});

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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final friendsServiceVM = ref.watch(friendsServiceProvider);
    return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              ScreenHeader(
                title: context.l10n.friendRequests,
                showBackButton: true,
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
                      // ListView opakowuje EmptyState żeby pull-to-refresh
                      // działało nawet przy pustym contencie (gesture
                      // wymaga scrollable child).
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            SizedBox(
                              height:
                                  MediaQuery.of(context).size.height * 0.6,
                              child: EmptyState(
                                icon: Icons.notifications_none_outlined,
                                message: context.l10n.noFriendRequestsMsg,
                              ),
                            ),
                          ],
                        )
                      : UsersList(
                          _acceptFriendRequestAfterTap,
                          friendsServiceVM.friendRequestsList,
                          context.l10n.acceptFriendRequestTitle,
                          _declineFriendRequestAfterTap,
                        ),
                ),
              )
            ],
          ),
        ));
  }
}
