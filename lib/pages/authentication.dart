import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shoqlist/main.dart';
import 'package:shoqlist/viewmodels/firebase_auth_view_model.dart';
import 'package:shoqlist/widgets/components/buttons.dart';
import 'package:shoqlist/widgets/components/forms.dart';

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
    return Scaffold(
        backgroundColor: Theme.of(context).backgroundColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text('Shoqlist',
                  style: Theme.of(context).primaryTextTheme.headline3),
              SizedBox(height: screenSize.height * 0.08),
              Text(
                firebaseAuthVM.exceptionMessage,
                style: TextStyle(color: Colors.red, fontSize: 12),
                textAlign: TextAlign.center,
              ),
              AuthenticationPageForm(
                  TextInputType.emailAddress,
                  toolsVM.emailController,
                  'E-mail',
                  _resetExceptionMessage,
                  Icons.email,
                  false),
              SizedBox(height: 5),
              AuthenticationPageForm(
                  TextInputType.visiblePassword,
                  toolsVM.passwordController,
                  'Password',
                  _resetExceptionMessage,
                  Icons.vpn_key,
                  !toolsVM.showPassword,
                  _passwordVisibilityWidget),
              SizedBox(height: 5),
              AuthenticationPageButton(_signInUserFirebase, 'Sign-in'),
              SizedBox(height: 5),
              AuthenticationPageButton(_registerUserFirebase, 'Register'),
            ],
          ),
        ));
  }
}
