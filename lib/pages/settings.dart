import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shoqlist/main.dart';

class Settings extends ConsumerWidget {
  Widget build(BuildContext context, ScopedReader watch) {
    final firebaseAuthVM = watch(firebaseAuthProvider);
    return Scaffold(
        body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: () {
              firebaseAuthVM.signOut();
              Navigator.pop(context);
            },
            child: Container(height: 50, width: 200, child: Text("Sign out")),
          )
        ],
      ),
    ));
  }
}
