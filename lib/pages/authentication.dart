import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shoqlist/main.dart';
import 'package:shoqlist/viewmodels/firebase_auth_view_model.dart';
import 'package:shoqlist/widgets/components/buttons.dart';
import 'package:shoqlist/widgets/components/forms.dart';
import 'package:shoqlist/l10n/l10n_extension.dart';

class Authentication extends ConsumerWidget {
  const Authentication({super.key});

  void _registerUserFirebase(BuildContext context, WidgetRef ref) {
    final toolsVM = ref.read(toolsProvider);
    final authVM = ref.read(firebaseAuthProvider);
    authVM
        .register(toolsVM.emailController.text, toolsVM.passwordController.text)
        .then(
      (_) {
        if (authVM.status == Status.authenticated) {
          toolsVM.clearAuthenticationTextEditingControllers();
        }
      },
    );
  }

  void _signInUserFirebase(BuildContext context, WidgetRef ref) {
    final toolsVM = ref.read(toolsProvider);
    final authVM = ref.read(firebaseAuthProvider);
    authVM
        .signIn(toolsVM.emailController.text, toolsVM.passwordController.text)
        .then(
      (_) {
        if (authVM.status == Status.authenticated) {
          toolsVM.clearAuthenticationTextEditingControllers();
        }
      },
    );
  }

  void _resetExceptionMessage(BuildContext context, WidgetRef ref) {
    ref.read(firebaseAuthProvider).resetExceptionMessage();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final toolsVM = ref.watch(toolsProvider);
    final firebaseAuthVM = ref.watch(firebaseAuthProvider);
    final screenSize = MediaQuery.of(context).size;
    List<String> exceptionMessages = [
      context.l10n.undefinedExc,
      context.l10n.noUserExc,
      context.l10n.passwordExc,
      context.l10n.emailExc,
      context.l10n.userDisabledExc,
      context.l10n.emptyFieldExc,
      context.l10n.weakPasswordExc,
      context.l10n.emailInUseExc,
      context.l10n.googleSignInExc,
      context.l10n.anonymousSignInExc,
      ''
    ];
    Widget passwordVisibilityWidget = GestureDetector(
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
        backgroundColor: Theme.of(context).colorScheme.surface,
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
                        context.l10n.appName,
                        style: Theme.of(context).primaryTextTheme.displaySmall,
                      ),
                    ],
                  ),
                  SizedBox(height: screenSize.height * 0.020),
                  SizedBox(
                      width: 30,
                      height: 30,
                      child: firebaseAuthVM.status == Status.duringAuthorization
                          ? CircularProgressIndicator()
                          : Container()),
                  SizedBox(height: screenSize.height * 0.005),
                  Text(
                    exceptionMessages[firebaseAuthVM.exceptionMessageIndex],
                    style: TextStyle(color: Colors.red, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 5),
                  BasicForm(
                    keyboardType: TextInputType.emailAddress,
                    controller: toolsVM.emailController,
                    hintText: context.l10n.email,
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
                    hintText: context.l10n.password,
                    onChanged: _resetExceptionMessage,
                    prefixIcon: Icons.vpn_key,
                    obscureText: !toolsVM.showPassword,
                    suffixIcon: passwordVisibilityWidget,
                    focusedBorder: false,
                    enableBorder: false,
                    width: screenSize.width * 0.7,
                  ),
                  SizedBox(height: 25),
                  BasicButton(
                    _signInUserFirebase,
                    context.l10n.signIn,
                    0.7,
                  ),
                  SizedBox(height: 5),
                  BasicButton(
                    _registerUserFirebase,
                    context.l10n.register,
                    0.7,
                  ),
                ],
              ),
            ),
          ),
        ));
  }
}
