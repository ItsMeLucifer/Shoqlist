import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shoqlist/main.dart';

class ShoppingListDisplay extends ConsumerWidget {
  Widget build(BuildContext context, ScopedReader watch) {
    final shoppingListsVM = watch(shoppingListsProvider);
    return SizedBox(
      height: 500,
      child: Column(
        children: [
          Text(
              shoppingListsVM
                  .shoppingList[shoppingListsVM.currentListIndex].name,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 30)),
          Expanded(
            child: SizedBox(
              height: 500,
              width: 200,
              child: ListView.builder(
                  shrinkWrap: false,
                  itemCount: shoppingListsVM
                      .shoppingList[shoppingListsVM.currentListIndex]
                      .list
                      .length,
                  itemBuilder: (context, index) {
                    return Container(
                      height: 50,
                      child: Row(
                        children: [
                          Icon(Icons.crop_square),
                          Text(shoppingListsVM
                              .shoppingList[shoppingListsVM.currentListIndex]
                              .list[index]),
                        ],
                      ),
                    );
                  }),
            ),
          ),
        ],
      ),
    );
  }
}
