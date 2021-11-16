import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shoqlist/main.dart';
import 'package:shoqlist/widgets/homeScreen/shopping_list_display.dart';

class HomeScreenMainView extends ConsumerWidget {
  void _navigateToShoppingList(BuildContext context) {
    Navigator.push(context,
        MaterialPageRoute(builder: (context) => ShoppingListDisplay()));
  }

  Widget build(BuildContext context, ScopedReader watch) {
    final shoppingListsVM = watch(shoppingListsProvider);
    final toolsVM = watch(toolsProvider);
    final firebaseVM = watch(firebaseProvider);
    return SafeArea(
      child: Stack(
        children: [
          Column(
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
                      padding: const EdgeInsets.only(
                          left: 8.0, right: 8.0, top: 8.0),
                      child: Container(
                        height: 60,
                        child: GestureDetector(
                          onTap: () {
                            shoppingListsVM.currentListIndex = index;
                            _navigateToShoppingList(context);
                          },
                          onLongPress: () {
                            showDialog(
                                context: context,
                                builder: (context) {
                                  return AlertDialog(
                                    content: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Container(
                                          child: Text(
                                              "Delete the '" +
                                                  shoppingListsVM
                                                      .shoppingList[index]
                                                      .name +
                                                  "' list?",
                                              style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold),
                                              textAlign: TextAlign.center)),
                                    ),
                                    actions: [
                                      FlatButton(
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                          //DELETE LIST ON FIREBASE
                                          firebaseVM
                                              .deleteShoppingListOnFirebase(
                                                  shoppingListsVM
                                                      .shoppingList[index]
                                                      .documentId);
                                          //DELETE LIST LOCALLY
                                          shoppingListsVM
                                              .deleteListLocally(index);
                                        },
                                        child: Text('Yes'),
                                      ),
                                      FlatButton(
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                        },
                                        child: Text('No'),
                                      )
                                    ],
                                  );
                                });
                          },
                          child: Card(
                              color: toolsVM.getImportanceColor(shoppingListsVM
                                  .shoppingList[index].importance),
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      shoppingListsVM.shoppingList[index].name,
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 20),
                                    ),
                                    Row(
                                      children: [
                                        shoppingListsVM.shoppingList[index].list
                                                    .length !=
                                                0
                                            ? Container(
                                                width: 100,
                                                child: Text(
                                                  shoppingListsVM
                                                          .shoppingList[index]
                                                          .list[0]
                                                          .itemName +
                                                      "${shoppingListsVM.shoppingList[index].list.length > 1 ? ', ...' : ''}",
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  maxLines: 1,
                                                  style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.normal,
                                                      fontSize: 15),
                                                  textAlign: TextAlign.end,
                                                ),
                                              )
                                            : Container(),
                                        Text(
                                          "   [" +
                                              shoppingListsVM
                                                  .shoppingList[index]
                                                  .list
                                                  .length
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
                      ),
                    );
                  })
            ],
          ),
        ],
      ),
    );
  }
}
