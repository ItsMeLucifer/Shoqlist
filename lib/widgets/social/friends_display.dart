import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shoqlist/main.dart';
import 'package:shoqlist/widgets/social/friends_search_display.dart';
import 'package:shoqlist/widgets/social/users_list.dart';

class FriendsDisplay extends ConsumerWidget {
  void _removeUserFromFriendsListAfterTap() {
    //Delete notification etc.
  }
  void _navigateToFriendsSearchList(BuildContext context) {
    Navigator.push(context,
        MaterialPageRoute(builder: (context) => FriendsSearchDisplay()));
  }

  Widget build(BuildContext context, ScopedReader watch) {
    final friendsServiceVM = watch(friendsServiceProvider);
    final firebaseVM = watch(firebaseProvider);
    firebaseVM.fetchFriendsList();
    //Make if statement, when loading data, display only
    return Scaffold(
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
                      children: [
                        SizedBox(height: 10),
                        Center(
                            child: Text('You have no Friends',
                                style: Theme.of(context)
                                    .primaryTextTheme
                                    .bodyText1)),
                        SizedBox(height: 10),
                        FlatButton(
                            onPressed: () {
                              _navigateToFriendsSearchList(context);
                            },
                            child: Card(
                              color: Theme.of(context).buttonColor,
                              child: Padding(
                                padding: const EdgeInsets.all(10.0),
                                child: Text('Search for Friends',
                                    style: Theme.of(context)
                                        .primaryTextTheme
                                        .button),
                              ),
                            ))
                      ],
                    )
                  : UsersList(_removeUserFromFriendsListAfterTap,
                      friendsServiceVM.friendsList)
            ],
          ),
        ],
      ),
    ));
  }
}
