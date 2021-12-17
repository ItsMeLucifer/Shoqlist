import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shoqlist/models/user.dart';

import '../../main.dart';

class UsersList extends ConsumerWidget {
  final Function _tapElementFunction;
  final List<User> _usersList;
  UsersList(this._tapElementFunction, this._usersList);
  Widget build(BuildContext context, ScopedReader watch) {
    return ListView.builder(
        shrinkWrap: true,
        itemCount: _usersList.length,
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
                        _usersList[index].email,
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
