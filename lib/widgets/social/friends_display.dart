import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:shoqlist/main.dart';
import 'package:shoqlist/models/user.dart';
import 'package:shoqlist/widgets/social/friend_requests_display.dart';
import 'package:shoqlist/widgets/social/friends_search_display.dart';
import 'package:shoqlist/widgets/social/users_list.dart';

class FriendsDisplay extends ConsumerWidget {
  void _removeUserFromFriendsListAfterTap(BuildContext context) {
    final firebaseVM = context.read(firebaseProvider);
    final friendsServiceVM = context.read(friendsServiceProvider);
    User user = friendsServiceVM.friendsList[friendsServiceVM.currentUserIndex];
    firebaseVM.removeFriendFromFriendsList(user);
    Navigator.of(context).pop();
  }

  void _navigateToFriendsSearchList(BuildContext context) {
    context.read(friendsServiceProvider).clearUsersList();
    Navigator.push(context,
        MaterialPageRoute(builder: (context) => FriendsSearchDisplay()));
  }

  void _navigateToFriendRequestsList(BuildContext context) {
    Navigator.push(context,
        MaterialPageRoute(builder: (context) => FriendRequestsDisplay()));
  }

  Widget build(BuildContext context, ScopedReader watch) {
    final friendsServiceVM = watch(friendsServiceProvider);
    final firebaseVM = watch(firebaseProvider);
    firebaseVM.fetchFriendsList();
    //Make if statement, when loading data, display only progress indicator
    return Scaffold(
        backgroundColor: Theme.of(context).backgroundColor,
        floatingActionButton: SpeedDial(
            overlayOpacity: 0,
            animatedIcon: AnimatedIcons.menu_close,
            backgroundColor:
                Theme.of(context).floatingActionButtonTheme.backgroundColor,
            children: [
              SpeedDialChild(
                  onTap: () {
                    _navigateToFriendsSearchList(context);
                    friendsServiceVM.clearSearchFriendTextController();
                  },
                  label: 'Search Friends',
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
                  onTap: () {
                    _navigateToFriendRequestsList(context);
                  },
                  label: 'Friend Requests',
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
                  SizedBox(height: 5),
                  Text("Friends",
                      style: Theme.of(context).primaryTextTheme.headline4),
                  Divider(
                    color: Theme.of(context).accentColor,
                    indent: 50,
                    endIndent: 50,
                  ),
                  friendsServiceVM.friendsList.isEmpty
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Center(
                                child: Text('You have no Friends',
                                    style: Theme.of(context)
                                        .primaryTextTheme
                                        .bodyText1)),
                          ],
                        )
                      : UsersList(
                          _removeUserFromFriendsListAfterTap,
                          friendsServiceVM.friendsList,
                          "Remove from friends list?")
                ],
              ),
            ],
          ),
        ));
  }
}
