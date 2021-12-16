import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shoqlist/widgets/social/users_list.dart';

class FriendsDisplay extends ConsumerWidget {
  void _removeUserFromFriendsListAfterTap() {
    //Delete notification etc.
  }
  Widget build(BuildContext context, ScopedReader watch) {
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
              UsersList(_removeUserFromFriendsListAfterTap)
            ],
          ),
        ],
      ),
    ));
  }
}
