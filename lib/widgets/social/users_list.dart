import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shoqlist/models/user.dart';
import 'package:shoqlist/widgets/components/dialogs.dart';

import '../../main.dart';

class UsersList extends ConsumerWidget {
  final Function _tapElementFunction;
  final List<User> _usersList;
  final String _dialogTitle;
  UsersList(this._tapElementFunction, this._usersList, [this._dialogTitle]);
  Widget build(BuildContext context, ScopedReader watch) {
    final friendsServiceVM = watch(friendsServiceProvider);
    return ListView.builder(
        shrinkWrap: true,
        itemCount: _usersList.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(top: 2.0, left: 10, right: 10),
            child: GestureDetector(
              onTap: () {
                friendsServiceVM.currentUserIndex = index;
                if (_dialogTitle == null) {
                  _tapElementFunction(context);
                } else {
                  showDialog(
                      context: context,
                      builder: (context) {
                        return YesNoDialog(_tapElementFunction, _dialogTitle);
                      });
                }
              },
              child: Card(
                color: Theme.of(context).buttonColor,
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Row(
                    children: [
                      Icon(Icons.person),
                      SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          _usersList[index].email,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        });
  }
}
