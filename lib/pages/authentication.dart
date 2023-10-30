import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shoqlist/main.dart';
import 'package:shoqlist/viewmodels/firebase_auth_view_model.dart';
import 'package:shoqlist/widgets/components/buttons.dart';
import 'package:shoqlist/widgets/components/forms.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class Authentication extends ConsumerWidget {
  void _registerUserFirebase(BuildContext context, WidgetRef ref) {
    final toolsVM = ref.read(toolsProvider);
    ref
        .read(firebaseAuthProvider)
        .register(toolsVM.emailController.text, toolsVM.passwordController.text)
        .then((_) => toolsVM.clearAuthenticationTextEditingControllers());
  }

  void _signInUserFirebase(BuildContext context, WidgetRef ref) {
    final toolsVM = ref.read(toolsProvider);
    ref
        .read(firebaseAuthProvider)
        .signIn(toolsVM.emailController.text, toolsVM.passwordController.text)
        .then((_) => toolsVM.clearAuthenticationTextEditingControllers());
  }

  void _resetExceptionMessage(BuildContext context, WidgetRef ref) {
    ref.read(firebaseAuthProvider).resetExceptionMessage();
  }

  Widget build(BuildContext context, WidgetRef ref) {
    final toolsVM = ref.watch(toolsProvider);
    final firebaseAuthVM = ref.watch(firebaseAuthProvider);
    final screenSize = MediaQuery.of(context).size;
    List<String> _exceptionMessages = [
      AppLocalizations.of(context)!.undefinedExc,
      AppLocalizations.of(context)!.noUserExc,
      AppLocalizations.of(context)!.passwordExc,
      AppLocalizations.of(context)!.emailExc,
      AppLocalizations.of(context)!.userDisabledExc,
      AppLocalizations.of(context)!.emptyFieldExc,
      AppLocalizations.of(context)!.weakPasswordExc,
      AppLocalizations.of(context)!.emailInUseExc,
      AppLocalizations.of(context)!.googleSignInExc,
      AppLocalizations.of(context)!.anonymousSignInExc,
      ''
    ];
    Widget _passwordVisibilityWidget = GestureDetector(
      onTap: () {
        ref.read(toolsProvider).showPassword =
            !ref.read(toolsProvider).showPassword;
      },
      child: Icon(
          !ref.read(toolsProvider).showPassword
              ? Icons.visibility_off
              : Icons.visibility,
          color: Colors.grey),
    );
    return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.background,
        body: Center(
          child: SingleChildScrollView(
            child: SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Image.asset(
                        'images/icon.png',
                        height: 50,
                      ),
                      SizedBox(width: 5),
                      Text(
                        AppLocalizations.of(context)!.appName,
                        style: Theme.of(context).primaryTextTheme.displaySmall,
                      ),
                    ],
                  ),
                  SizedBox(height: screenSize.height * 0.020),
                  Container(
                      width: 30,
                      height: 30,
                      child: firebaseAuthVM.status == Status.DuringAuthorization
                          ? CircularProgressIndicator()
                          : Container()),
                  SizedBox(height: screenSize.height * 0.005),
                  Text(
                    _exceptionMessages[firebaseAuthVM.exceptionMessageIndex],
                    style: TextStyle(color: Colors.red, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 5),
                  BasicForm(
                    keyboardType: TextInputType.emailAddress,
                    controller: toolsVM.emailController,
                    hintText: AppLocalizations.of(context)!.email,
                    onChanged: _resetExceptionMessage,
                    prefixIcon: Icons.email,
                    focusedBorder: false,
                    enableBorder: false,
                    width: screenSize.width * 0.7,
                  ),
                  SizedBox(height: 5),
                  BasicForm(
                    keyboardType: TextInputType.visiblePassword,
                    controller: toolsVM.passwordController,
                    hintText: AppLocalizations.of(context)!.password,
                    onChanged: _resetExceptionMessage,
                    prefixIcon: Icons.vpn_key,
                    obscureText: !toolsVM.showPassword,
                    suffixIcon: _passwordVisibilityWidget,
                    focusedBorder: false,
                    enableBorder: false,
                    width: screenSize.width * 0.7,
                  ),
                  SizedBox(height: 25),
                  BasicButton(
                    _signInUserFirebase,
                    AppLocalizations.of(context)!.signIn,
                    0.7,
                  ),
                  SizedBox(height: 5),
                  BasicButton(
                    _registerUserFirebase,
                    AppLocalizations.of(context)!.register,
                    0.7,
                  ),
                ],
              ),
            ),
          ),
        ));
  }
}
