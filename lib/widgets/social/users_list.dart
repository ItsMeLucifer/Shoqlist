import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shoqlist/models/user.dart';

import '../../main.dart';

class UsersList extends ConsumerWidget {
  Function _tapElementFunction;
  UsersList(this._tapElementFunction);
  Widget build(BuildContext context, ScopedReader watch) {
    final friendsServiceVM = watch(friendsServiceProvider);
    if (friendsServiceVM.currentUsersList.length < 1) {
      return Column(
        children: [
          SizedBox(height: 10),
          Center(
              child: Text('You have no Friends',
                  style: Theme.of(context).primaryTextTheme.bodyText1)),
          SizedBox(height: 10),
          FlatButton(
              onPressed: null,
              child: Card(
                color: Theme.of(context).buttonColor,
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Text('Search for Friends',
                      style: Theme.of(context).primaryTextTheme.button),
                ),
              ))
        ],
      );
    }
    return ListView.builder(
        shrinkWrap: true,
        itemCount: friendsServiceVM.currentUsersList.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: _tapElementFunction,
            child: Card(
              color: Theme.of(context).primaryColor,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        friendsServiceVM.currentUsersList[index].email,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        });
  }
}
