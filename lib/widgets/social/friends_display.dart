import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';
import 'package:shoqlist/main.dart';
import 'package:shoqlist/models/user.dart';
import 'package:shoqlist/widgets/social/friend_requests_display.dart';
import 'package:shoqlist/widgets/social/friends_search_display.dart';
import 'package:shoqlist/widgets/social/users_list.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class FriendsDisplay extends ConsumerWidget {
  void _removeUserFromFriendsListAfterTap(BuildContext context, WidgetRef ref) {
    final firebaseVM = ref.read(firebaseProvider);
    final friendsServiceVM = ref.read(friendsServiceProvider);
    User user = friendsServiceVM.friendsList[friendsServiceVM.currentUserIndex];
    firebaseVM.removeFriendFromFriendsList(user);
    Navigator.of(context).pop();
  }

  void _navigateToFriendsSearchList(BuildContext context, WidgetRef ref) {
    ref.read(friendsServiceProvider).clearUsersList();
    Navigator.push(context,
        MaterialPageRoute(builder: (context) => FriendsSearchDisplay()));
  }

  void _navigateToFriendRequestsList(BuildContext context) {
    Navigator.push(context,
        MaterialPageRoute(builder: (context) => FriendRequestsDisplay()));
  }

  void _onRefresh(WidgetRef ref) {
    ref.read(firebaseProvider).fetchFriendsList();
  }

  Widget build(BuildContext context, WidgetRef ref) {
    final friendsServiceVM = ref.watch(friendsServiceProvider);
    final screenSize = MediaQuery.of(context).size;
    return Scaffold(
        backgroundColor: Theme.of(context).backgroundColor,
        floatingActionButton: SpeedDial(
            overlayOpacity: 0,
            animatedIcon: AnimatedIcons.menu_close,
            foregroundColor:
                Theme.of(context).floatingActionButtonTheme.foregroundColor,
            backgroundColor:
                Theme.of(context).floatingActionButtonTheme.backgroundColor,
            children: [
              SpeedDialChild(
                  labelBackgroundColor: Theme.of(context)
                      .floatingActionButtonTheme
                      .backgroundColor,
                  labelStyle: Theme.of(context)
                      .floatingActionButtonTheme
                      .extendedTextStyle,
                  onTap: () {
                    _navigateToFriendsSearchList(context, ref);
                    friendsServiceVM.clearSearchFriendTextController();
                  },
                  label: AppLocalizations.of(context).searchFriends,
                  backgroundColor: Theme.of(context)
                      .floatingActionButtonTheme
                      .backgroundColor,
                  child: Icon(
                    Icons.search,
                    color: Theme.of(context)
                        .floatingActionButtonTheme
                        .foregroundColor,
                  )),
              SpeedDialChild(
                  labelBackgroundColor: Theme.of(context)
                      .floatingActionButtonTheme
                      .backgroundColor,
                  labelStyle: Theme.of(context)
                      .floatingActionButtonTheme
                      .extendedTextStyle,
                  onTap: () {
                    _navigateToFriendRequestsList(context);
                  },
                  label: AppLocalizations.of(context).friendRequests,
                  backgroundColor: Theme.of(context)
                      .floatingActionButtonTheme
                      .backgroundColor,
                  child: Icon(
                    Icons.people_alt,
                    color: Theme.of(context)
                        .floatingActionButtonTheme
                        .foregroundColor,
                  ))
            ]),
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
                      AppLocalizations.of(context).friends,
                      style: Theme.of(context).primaryTextTheme.headline4,
                    ),
                  ),
                  Expanded(
                    child: LiquidPullToRefresh(
                        backgroundColor:
                            Theme.of(context).colorScheme.secondary,
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
                                  SizedBox(height: 10),
                                  Center(
                                    child: Text(
                                        AppLocalizations.of(context)
                                            .noFriendsMsg,
                                        style: Theme.of(context)
                                            .primaryTextTheme
                                            .bodyText1),
                                  )
                                ],
                              )
                            : UsersList(
                                _removeUserFromFriendsListAfterTap,
                                friendsServiceVM.friendsList,
                                AppLocalizations.of(context)
                                    .removeFriendTitle)),
                  )
                ],
              ),
            ],
          ),
        ));
  }
}
