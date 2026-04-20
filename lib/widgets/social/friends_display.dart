import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';
import 'package:shoqlist/constants/app_colors.dart';
import 'package:shoqlist/main.dart';
import 'package:shoqlist/models/user.dart';
import 'package:shoqlist/widgets/components/native_ad_banner.dart';
import 'package:shoqlist/widgets/components/screen_header.dart';
import 'package:shoqlist/widgets/social/friend_requests_display.dart';
import 'package:shoqlist/widgets/social/friends_search_display.dart';
import 'package:shoqlist/widgets/social/users_list.dart';
import 'package:shoqlist/l10n/l10n_extension.dart';

class FriendsDisplay extends ConsumerWidget {
  const FriendsDisplay({super.key});

  void _removeUserFromFriendsListAfterTap(BuildContext context, WidgetRef ref) {
    final firebaseVM = ref.read(firebaseProvider);
    final friendsServiceVM = ref.read(friendsServiceProvider);
    User user =
        friendsServiceVM.friendsList[friendsServiceVM.currentUserIndex!];
    firebaseVM.removeFriendFromFriendsList(user);
    Navigator.of(context).pop();
  }

  void _navigateToFriendsSearchList(BuildContext context, WidgetRef ref) {
    ref.read(friendsServiceProvider).clearUsersList();
    ref.read(friendsServiceProvider).clearSearchFriendTextController();
    Navigator.push(context,
        MaterialPageRoute(builder: (context) => const FriendsSearchDisplay()));
  }

  void _navigateToFriendRequestsList(BuildContext context) {
    Navigator.push(context,
        MaterialPageRoute(builder: (context) => const FriendRequestsDisplay()));
  }

  void _onRefresh(WidgetRef ref) {
    ref.read(firebaseProvider).fetchFriendsList();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final friendsServiceVM = ref.watch(friendsServiceProvider);
    final pendingRequests = friendsServiceVM.friendRequestsList.length;
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            ScreenHeader(
              title: context.l10n.friends,
              actions: [
                IconButton(
                  icon: const Icon(Icons.person_search_outlined),
                  color: AppColors.brandPink,
                  tooltip: context.l10n.searchFriends,
                  onPressed: () => _navigateToFriendsSearchList(context, ref),
                ),
                _RequestsIconButton(
                  pendingCount: pendingRequests,
                  onPressed: () => _navigateToFriendRequestsList(context),
                  tooltip: context.l10n.friendRequests,
                ),
              ],
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
                child: friendsServiceVM.friendsList.isEmpty
                    ? ListView(
                        children: [
                          const SizedBox(height: 10),
                          Center(
                            child: Text(
                              context.l10n.noFriendsMsg,
                              style: Theme.of(context)
                                  .primaryTextTheme
                                  .bodyLarge,
                            ),
                          )
                        ],
                      )
                    : UsersList(
                        _removeUserFromFriendsListAfterTap,
                        friendsServiceVM.friendsList,
                        context.l10n.removeFriendTitle,
                      ),
              ),
            ),
            const NativeAdBanner(),
          ],
        ),
      ),
    );
  }
}

class _RequestsIconButton extends StatelessWidget {
  const _RequestsIconButton({
    required this.pendingCount,
    required this.onPressed,
    required this.tooltip,
  });

  final int pendingCount;
  final VoidCallback onPressed;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    final icon = IconButton(
      icon: const Icon(Icons.notifications_outlined),
      color: AppColors.brandPink,
      tooltip: tooltip,
      onPressed: onPressed,
    );
    if (pendingCount == 0) return icon;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        icon,
        Positioned(
          right: 6,
          top: 6,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: const BoxDecoration(
              color: AppColors.brandPink,
              shape: BoxShape.circle,
            ),
            constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
            child: Text(
              pendingCount > 9 ? '9+' : '$pendingCount',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                fontFamily: 'Epilogue',
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }
}
