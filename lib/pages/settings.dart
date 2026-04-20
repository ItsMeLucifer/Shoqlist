import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shoqlist/main.dart';
import 'package:shoqlist/widgets/components/buttons.dart';
import 'package:shoqlist/widgets/components/dialogs.dart';
import 'package:shoqlist/widgets/components/native_ad_banner.dart';
import 'package:shoqlist/l10n/l10n_extension.dart';

class Settings extends ConsumerWidget {
  const Settings({super.key});

  void _signOut(BuildContext context, WidgetRef ref) {
    final firebaseAuthVM = ref.read(firebaseAuthProvider);
    ref.read(shoppingListsProvider).clearDisplayedData();
    firebaseAuthVM.signOut();
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
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final firebaseAuthVM = ref.watch(firebaseAuthProvider);
    final screenSize = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    Container(
                      width: screenSize.width,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        context.l10n.settings,
                        style: Theme.of(context).primaryTextTheme.displaySmall,
                      ),
                    ),
                    SizedBox(height: screenSize.height * 0.02),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          const Icon(Icons.person, size: 70),
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
                              SizedBox(
                                width: screenSize.width * 0.4,
                                child: Text(
                                  firebaseAuthVM.currentUser.nickname,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context)
                                      .primaryTextTheme
                                      .headlineSmall,
                                ),
                              ),
                              SizedBox(
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
                              context.l10n.changeNicknameTitle,
                              0.1,
                              Icons.edit)
                        ],
                      ),
                    ),
                    SizedBox(height: screenSize.height * 0.15),
                    BasicButton(_signOut, context.l10n.signOut, 0.6),
                    SizedBox(height: screenSize.height * 0.1),
                    WarningButton(
                        _deleteAccount, context.l10n.deleteAccount, 0.6),
                    SizedBox(height: screenSize.height * 0.05),
                  ],
                ),
              ),
            ),
            const NativeAdBanner(),
          ],
        ),
      ),
    );
  }
}
