import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shoqlist/models/user.dart';
import 'package:shoqlist/widgets/social/users_list.dart';
import '../../main.dart';

class FriendsSearchDisplay extends ConsumerWidget {
  _sendFriendRequestAfterTap(BuildContext context, User target) {
    final firebaseVM = context.read(firebaseProvider);
    firebaseVM.sendFriendRequest(target);
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
                Container(
                  width: 200,
                  height: 50,
                  child: TextFormField(
                      keyboardType: TextInputType.emailAddress,
                      autofocus: false,
                      controller: friendsServiceVM.searchFriendTextController,
                      onFieldSubmitted: (value) {
                        firebaseVM.searchForUser(value);
                      },
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                          hintText: 'Type in email',
                          prefixIcon: Icon(
                            Icons.mail,
                          ),
                          focusColor: Theme.of(context)
                              .primaryTextTheme
                              .bodyText1
                              .color,
                          enabledBorder: OutlineInputBorder(
                              borderSide:
                                  BorderSide(width: 1, color: Colors.grey)),
                          focusedBorder: OutlineInputBorder(
                              borderSide:
                                  BorderSide(width: 1, color: Colors.white)),
                          hintStyle: TextStyle(fontWeight: FontWeight.bold),
                          contentPadding: EdgeInsets.fromLTRB(20, 10, 20, 10))),
                ),
                // friendsServiceVM.usersList.isEmpty &&
                //         friendsServiceVM.searchFriendTextController.text != ""
                //     ? Column(
                //         mainAxisAlignment: MainAxisAlignment.center,
                //         children: [
                //           Center(
                //               child: Text("Can't find that user, try again",
                //                   style: Theme.of(context)
                //                       .primaryTextTheme
                //                       .bodyText1)),
                //         ],
                //       )
                //     : UsersList(
                //         _sendFriendRequestAfterTap, friendsServiceVM.usersList)
              ],
            ),
          ],
        ),
      ),
    ));
  }
}
