import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shoqlist/main.dart';
import 'package:shoqlist/viewmodels/firebase_auth_view_model.dart';
import 'package:shoqlist/widgets/components/buttons.dart';
import 'package:shoqlist/widgets/components/forms.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class Authentication extends ConsumerWidget {
  void _registerUserFirebase(BuildContext context) {
    final toolsVM = context.read(toolsProvider);
    context.read(firebaseAuthProvider).register(
        toolsVM.emailController.text, toolsVM.passwordController.text);
  }

  void _signInUserFirebase(BuildContext context) {
    final toolsVM = context.read(toolsProvider);
    context
        .read(firebaseAuthProvider)
        .signIn(toolsVM.emailController.text, toolsVM.passwordController.text);
  }

  void _resetExceptionMessage(BuildContext context) {
    context.read(firebaseAuthProvider).resetExceptionMessage();
  }

  Widget build(BuildContext context, ScopedReader watch) {
    final toolsVM = watch(toolsProvider);
    final firebaseAuthVM = watch(firebaseAuthProvider);
    final screenSize = MediaQuery.of(context).size;
    Widget _passwordVisibilityWidget = GestureDetector(
      onTap: () {
        context.read(toolsProvider).showPassword =
            !context.read(toolsProvider).showPassword;
      },
      child: Icon(
          !context.read(toolsProvider).showPassword
              ? Icons.visibility_off
              : Icons.visibility,
          color: Colors.grey),
    );
    firebaseAuthVM.exceptionMessages = [
      AppLocalizations.of(context).undefinedExc,
      AppLocalizations.of(context).noUserExc,
      AppLocalizations.of(context).passwordExc,
      AppLocalizations.of(context).emailExc,
      AppLocalizations.of(context).userDisabledExc,
      AppLocalizations.of(context).emptyFieldExc,
      AppLocalizations.of(context).weakPasswordExc,
      AppLocalizations.of(context).emailInUseExc,
      AppLocalizations.of(context).googleSignInExc,
      AppLocalizations.of(context).anonymousSignInExc
    ];
    return Scaffold(
        backgroundColor: Theme.of(context).backgroundColor,
        body: Center(
          child: SingleChildScrollView(
            child: SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'images/icon.png',
                        height: 40,
                      ),
                      SizedBox(width: 5),
                      Text(AppLocalizations.of(context).appName,
                          style: Theme.of(context).primaryTextTheme.headline3),
                    ],
                  ),
                  SizedBox(height: screenSize.height * 0.025),
                  Container(
                      width: 30,
                      height: 30,
                      child: firebaseAuthVM.status == Status.DuringAuthorization
                          ? CircularProgressIndicator()
                          : Container()),
                  Text(
                    firebaseAuthVM.exceptionMessage,
                    style: TextStyle(color: Colors.red, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 5),
                  BasicForm(
                      TextInputType.emailAddress,
                      toolsVM.emailController,
                      AppLocalizations.of(context).email,
                      _resetExceptionMessage,
                      Icons.email,
                      false),
                  SizedBox(height: 5),
                  BasicForm(
                      TextInputType.visiblePassword,
                      toolsVM.passwordController,
                      AppLocalizations.of(context).password,
                      _resetExceptionMessage,
                      Icons.vpn_key,
                      !toolsVM.showPassword,
                      _passwordVisibilityWidget),
                  SizedBox(height: 5),
                  BasicButton(_signInUserFirebase,
                      AppLocalizations.of(context).signIn, 0.6),
                  SizedBox(height: 5),
                  BasicButton(_registerUserFirebase,
                      AppLocalizations.of(context).register, 0.6),
                ],
              ),
            ),
          ),
        ));
  }
}
