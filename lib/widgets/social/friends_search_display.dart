import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shoqlist/models/user.dart';
import 'package:shoqlist/widgets/components/forms.dart';
import 'package:shoqlist/widgets/social/users_list.dart';
import '../../main.dart';

class FriendsSearchDisplay extends ConsumerWidget {
  void _sendFriendRequestAfterTap(BuildContext context) {
    final firebaseVM = context.read(firebaseProvider);
    final friendsServiceVM = context.read(friendsServiceProvider);
    User user = friendsServiceVM.usersList[friendsServiceVM.currentUserIndex];
    firebaseVM.sendFriendRequest(user);
    Navigator.of(context).pop();
  }

  void _searchForFriend(BuildContext context, String value) {
    context.read(firebaseProvider).searchForUser(value);
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
                Text("Search for Friends",
                    style: Theme.of(context).primaryTextTheme.headline4),
                Divider(
                  color: Theme.of(context).accentColor,
                  indent: 50,
                  endIndent: 50,
                ),
                BasicForm(
                    TextInputType.emailAddress,
                    friendsServiceVM.searchFriendTextController,
                    'Type in email',
                    () => {},
                    Icons.email,
                    false,
                    null,
                    _searchForFriend),
                SizedBox(height: 5),
                friendsServiceVM.usersList.isEmpty &&
                        friendsServiceVM.searchFriendTextController.text != ""
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Center(
                              child: Text("Can't find that user, try again",
                                  style: Theme.of(context)
                                      .primaryTextTheme
                                      .bodyText1)),
                        ],
                      )
                    : UsersList(_sendFriendRequestAfterTap,
                        friendsServiceVM.usersList, 'Send friend request?')
              ],
            ),
          ],
        ),
      ),
    ));
  }
}
