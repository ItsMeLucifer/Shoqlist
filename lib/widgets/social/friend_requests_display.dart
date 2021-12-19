import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shoqlist/widgets/social/users_list.dart';

import '../../main.dart';

class FriendRequestsDisplay extends ConsumerWidget {
  void _acceptFriendRequestAfterTap(BuildContext context) {
    final firebaseVM = context.read(firebaseProvider);
    final friendsServiceVM = context.read(friendsServiceProvider);
    firebaseVM.acceptFriendRequest(
        friendsServiceVM.friendRequestsList[friendsServiceVM.currentUserIndex]);
    Navigator.of(context).pop();
  }

  void _declineFriendRequestAfterTap(BuildContext context) {
    final firebaseVM = context.read(firebaseProvider);
    final friendsServiceVM = context.read(friendsServiceProvider);
    firebaseVM.declineFriendRequest(
        friendsServiceVM.friendRequestsList[friendsServiceVM.currentUserIndex]);
    Navigator.of(context).pop();
  }

  Widget build(BuildContext context, ScopedReader watch) {
    final firebaseVM = watch(firebaseProvider);
    final friendsServiceVM = watch(friendsServiceProvider);
    return Scaffold(
        body: SingleChildScrollView(
      child: SafeArea(
        child: Stack(
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                SizedBox(height: 5),
                Text("Friend Requests",
                    style: Theme.of(context).primaryTextTheme.headline4),
                Divider(
                  color: Theme.of(context).accentColor,
                  indent: 50,
                  endIndent: 50,
                ),
                friendsServiceVM.friendRequestsList.isEmpty
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Center(
                              child: Text("You don't have any friend requests",
                                  style: Theme.of(context)
                                      .primaryTextTheme
                                      .bodyText1)),
                        ],
                      )
                    : UsersList(
                        _acceptFriendRequestAfterTap,
                        friendsServiceVM.friendRequestsList,
                        'Accept friend request?',
                        _declineFriendRequestAfterTap)
              ],
            ),
          ],
        ),
      ),
    ));
  }
}
