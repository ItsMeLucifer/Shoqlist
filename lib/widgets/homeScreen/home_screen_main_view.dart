import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shoqlist/main.dart';

class HomeScreenMainView extends ConsumerWidget {
  Widget build(BuildContext context, ScopedReader watch) {
    final shoppingListsVM = watch(shoppingListsProvider);
    final toolsVM = watch(toolsProvider);
    return SafeArea(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Text("Shoqlist",
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 40,
                  fontStyle: FontStyle.italic)),
          ListView.builder(
              shrinkWrap: true,
              itemCount: shoppingListsVM.shoppingList.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding:
                      const EdgeInsets.only(left: 8.0, right: 8.0, top: 8.0),
                  child: Container(
                    height: 60,
                    child: Card(
                        color: toolsVM.getImportanceColor(
                            shoppingListsVM.shoppingList[index].importance),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                shoppingListsVM.shoppingList[index].name,
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 20),
                              ),
                              Row(
                                children: [
                                  Text(
                                    shoppingListsVM
                                            .shoppingList[index].list[0] +
                                        " ...",
                                    style: TextStyle(
                                        fontWeight: FontWeight.normal,
                                        fontSize: 15),
                                  ),
                                  Text(
                                    " [" +
                                        shoppingListsVM
                                            .shoppingList[index].list.length
                                            .toString() +
                                        "]",
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        )),
                  ),
                );
              })
        ],
      ),
    );
  }
}
