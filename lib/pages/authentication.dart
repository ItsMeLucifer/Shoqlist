import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shoqlist/main.dart';

class Authentication extends ConsumerWidget {
  Widget build(BuildContext context, ScopedReader watch) {
    final firebaseVM = watch(firebaseProvider);
    final toolsVM = watch(toolsProvider);
    return Scaffold(
        backgroundColor: Colors.blueGrey,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 200,
                height: 50,
                child: TextFormField(
                    keyboardType: TextInputType.emailAddress,
                    autofocus: false,
                    controller: toolsVM.emailController,
                    onChanged: (value) {
                      firebaseVM.resetExceptionMessage();
                    },
                    style: TextStyle(
                        color: Colors.white,
                        //fontFamily: tools.fontFamily,
                        fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                        hintText: 'E-mail',
                        prefixIcon: Icon(
                          Icons.mail,
                          //color: tools.disabledText,
                        ),
                        focusColor: Colors.white,
                        enabledBorder: OutlineInputBorder(
                            borderSide:
                                BorderSide(width: 1, color: Colors.grey)),
                        focusedBorder: OutlineInputBorder(
                            borderSide:
                                BorderSide(width: 1, color: Colors.white)),
                        hintStyle: TextStyle(
                            //color: tools.disabledText,
                            //fontFamily: tools.fontFamily,
                            fontWeight: FontWeight.bold),
                        contentPadding: EdgeInsets.fromLTRB(20, 10, 20, 10))),
              ),
              SizedBox(height: 5),
              Container(
                  width: 200,
                  height: 50,
                  child: TextFormField(
                      keyboardType: TextInputType.visiblePassword,
                      autofocus: false,
                      autocorrect: false,
                      obscureText: !toolsVM.showPassword,
                      onChanged: (value) {
                        firebaseVM.resetExceptionMessage();
                      },
                      controller: toolsVM.passwordController,
                      style: TextStyle(
                          //color: tools.textColor,
                          //fontFamily: tools.fontFamily,
                          fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                          hintText: 'Password',
                          prefixIcon: Icon(
                            Icons.vpn_key,
                            //color: toolsVM.disabledText,
                          ),
                          suffixIcon: GestureDetector(
                            onTap: () {
                              toolsVM.showPassword = !toolsVM.showPassword;
                            },
                            child: Icon(
                                !toolsVM.showPassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: Colors.grey),
                          ),
                          hintStyle: TextStyle(
                              //color: tools.disabledText,
                              //fontFamily: tools.fontFamily,
                              fontWeight: FontWeight.bold),
                          enabledBorder: OutlineInputBorder(
                              borderSide:
                                  BorderSide(width: 1, color: Colors.grey)),
                          focusedBorder: OutlineInputBorder(
                              borderSide:
                                  BorderSide(width: 1, color: Colors.white)),
                          contentPadding:
                              EdgeInsets.fromLTRB(20, 10, 20, 10)))),
              SizedBox(height: 5),
              GestureDetector(
                onTap: () {
                  firebaseVM.signIn(toolsVM.emailController.text,
                      toolsVM.passwordController.text);
                },
                child: Container(
                    width: 250,
                    height: 40,
                    decoration: BoxDecoration(
                      //color: buttonColor,
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Center(
                      child: Text(
                        'Sign-in',
                        style: TextStyle(
                            //color: tools.textColor,
                            //fontFamily: tools.fontFamily,
                            fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    )),
              ),
              SizedBox(height: 5),
              GestureDetector(
                onTap: () {
                  firebaseVM.register(toolsVM.emailController.text,
                      toolsVM.passwordController.text);
                },
                child: Container(
                    width: 250,
                    height: 40,
                    decoration: BoxDecoration(
                      //color: buttonColor,
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Center(
                      child: Text(
                        'Register',
                        style: TextStyle(
                            //color: tools.textColor,
                            //fontFamily: tools.fontFamily,
                            fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    )),
              ),
            ],
          ),
        ));
  }
}
