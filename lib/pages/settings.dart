import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:shoqlist/main.dart';
import 'package:shoqlist/models/shopping_list.dart';
import 'package:shoqlist/widgets/components/buttons.dart';
import 'package:shoqlist/widgets/components/dialogs.dart';

class Settings extends ConsumerWidget {
  void _signOut(BuildContext context) {
    final toolsVM = context.read(toolsProvider);
    final firebaseAuthVM = context.read(firebaseAuthProvider);
    Hive.box<ShoppingList>('shopping_lists').clear();
    Hive.box<int>('data_variables').clear();
    toolsVM.clearAuthenticationTextEditingControllers();
    firebaseAuthVM.signOut();
    Navigator.pop(context);
  }

  void _changeNickname(BuildContext context) {
    final firebaseAuthVM = context.read(firebaseAuthProvider);
    final toolsVM = context.read(toolsProvider);
    firebaseAuthVM.changeNickname(toolsVM.newNicknameController.text);
  }

  void _showDialogWithChangeNickname(BuildContext context) {
    context.read(toolsProvider).clearNewNicknameController();
    showDialog(
        context: context,
        builder: (context) {
          return ChangeName(_changeNickname, 'Change nickname');
        });
  }

  Widget build(BuildContext context, ScopedReader watch) {
    final toolsVM = watch(toolsProvider);
    final firebaseVM = watch(firebaseProvider);
    final firebaseAuthVM = watch(firebaseAuthProvider);
    final screenSize = MediaQuery.of(context).size;
    return Scaffold(
        body: SingleChildScrollView(
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            SizedBox(height: 5),
            Text("Settings",
                style: Theme.of(context).primaryTextTheme.headline3),
            Divider(
              color: Theme.of(context).accentColor,
              indent: 50,
              endIndent: 50,
            ),
            Container(
              height: screenSize.height * 0.8,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(height: screenSize.height * 0.02),
                  Container(
                    height: screenSize.height * 0.1,
                    width: screenSize.width,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.person,
                            size: 70,
                          ),
                          SizedBox(width: screenSize.width * 0.02),
                          VerticalDivider(
                            color: Theme.of(context).accentColor,
                            indent: screenSize.height * 0.01,
                            endIndent: screenSize.height * 0.01,
                          ),
                          SizedBox(width: screenSize.width * 0.02),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: screenSize.width * 0.4,
                                child: Text(firebaseAuthVM.currentUser.nickname,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                        .primaryTextTheme
                                        .headline5),
                              ),
                              Container(
                                width: screenSize.width * 0.4,
                                child: Text(firebaseAuthVM.currentUser.email,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                        .primaryTextTheme
                                        .bodyText2),
                              )
                            ],
                          ),
                          SizedBox(width: screenSize.width * 0.1),
                          BasicButton(_showDialogWithChangeNickname,
                              'Change Nickname', 0.1, Icons.edit)
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: screenSize.height * 0.3),
                  BasicButton(_signOut, 'Sign-out', 0.6)
                ],
              ),
            ),
          ],
        ),
      ),
    ));
  }
}
