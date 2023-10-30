import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shoqlist/main.dart';
import 'package:shoqlist/widgets/components/buttons.dart';
import 'package:shoqlist/widgets/components/dialogs.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class Settings extends ConsumerWidget {
  void _signOut(BuildContext context, WidgetRef ref) {
    final firebaseAuthVM = ref.read(firebaseAuthProvider);
    ref.read(shoppingListsProvider).clearDisplayedData();
    firebaseAuthVM.signOut();
    Navigator.pop(context);
  }

  void _changeNickname(BuildContext context, WidgetRef ref) {
    final firebaseAuthVM = ref.read(firebaseAuthProvider);
    final toolsVM = ref.read(toolsProvider);
    firebaseAuthVM.changeNickname(toolsVM.newNicknameController.text);
    Navigator.of(context).pop();
  }

  void _showDialogWithChangeNickname(BuildContext context, WidgetRef ref) {
    ref.read(toolsProvider).clearNewNicknameController();
    showDialog(
      context: context,
      builder: (context) {
        return ChangeName(_changeNickname, 'Change nickname');
      },
    );
  }

  void _deleteAccount(BuildContext context, WidgetRef ref) {
    ref.read(firebaseProvider).deleteEveryDataRelatedToCurrentUser();
    Navigator.of(context).popUntil((route) => !Navigator.of(context).canPop());
  }

  Widget build(BuildContext context, WidgetRef ref) {
    final firebaseAuthVM = ref.watch(firebaseAuthProvider);
    final screenSize = MediaQuery.of(context).size;
    return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.background,
        body: SingleChildScrollView(
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                SizedBox(height: 20),
                Container(
                  width: screenSize.width,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    AppLocalizations.of(context)!.settings,
                    style: Theme.of(context).primaryTextTheme.displaySmall,
                  ),
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
                                color: Theme.of(context).colorScheme.secondary,
                                indent: screenSize.height * 0.01,
                                endIndent: screenSize.height * 0.01,
                              ),
                              SizedBox(width: screenSize.width * 0.02),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: screenSize.width * 0.4,
                                    child: Text(
                                      firebaseAuthVM.currentUser.nickname,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context)
                                          .primaryTextTheme
                                          .headlineSmall,
                                    ),
                                  ),
                                  Container(
                                    width: screenSize.width * 0.4,
                                    child: Text(
                                      firebaseAuthVM.currentUser.email,
                                      overflow: TextOverflow.fade,
                                      softWrap: false,
                                      maxLines: 1,
                                      style: Theme.of(context)
                                          .primaryTextTheme
                                          .bodyMedium,
                                    ),
                                  )
                                ],
                              ),
                              SizedBox(width: screenSize.width * 0.1),
                              BasicButton(
                                  _showDialogWithChangeNickname,
                                  AppLocalizations.of(context)!
                                      .changeNicknameTitle,
                                  0.1,
                                  Icons.edit)
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: screenSize.height * 0.2),
                      BasicButton(
                          _signOut, AppLocalizations.of(context)!.signOut, 0.6),
                      SizedBox(height: screenSize.height * 0.2),
                      WarningButton(_deleteAccount,
                          AppLocalizations.of(context)!.deleteAccount, 0.6)
                    ],
                  ),
                ),
              ],
            ),
          ),
        ));
  }
}
