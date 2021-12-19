import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:shoqlist/main.dart';
import 'package:shoqlist/models/shopping_list.dart';

class Settings extends ConsumerWidget {
  Widget build(BuildContext context, ScopedReader watch) {
    final firebaseAuthVM = watch(firebaseAuthProvider);
    final toolsVM = watch(toolsProvider);
    return Scaffold(
        body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: () {
              Hive.box<ShoppingList>('shopping_lists').clear();
              Hive.box<int>('data_variables').clear();
              toolsVM.clearAuthenticationTextEditingControllers();
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
