import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shoqlist/main.dart';
import 'package:shoqlist/widgets/components/notifications.dart';
import 'package:shoqlist/widgets/homeScreen/shopping_list_display.dart';

class HomeScreenMainView extends ConsumerWidget {
  void _navigateToShoppingList(BuildContext context) {
    Navigator.push(context,
        MaterialPageRoute(builder: (context) => ShoppingListDisplay()));
  }

  void _onLongPressShoppingList(BuildContext context) {
    Navigator.of(context).pop();
    //DELETE LIST ON FIREBASE
    context.read(firebaseProvider).deleteShoppingListOnFirebase(context
        .read(shoppingListsProvider)
        .shoppingLists[context.read(shoppingListsProvider).currentListIndex]
        .documentId);
    //DELETE LIST LOCALLY
    context.read(shoppingListsProvider).deleteShoppingListLocally(
        context.read(shoppingListsProvider).currentListIndex);
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
              SizedBox(height: 5),
              Text("Shoqlist",
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 40,
                      fontStyle: FontStyle.italic)),
              Divider(
                color: Theme.of(context).accentColor,
                indent: 50,
                endIndent: 50,
              ),
              ListView.builder(
                  shrinkWrap: true,
                  itemCount: shoppingListsVM.shoppingLists.length,
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
                            shoppingListsVM.currentListIndex = index;
                            showDialog(
                                context: context,
                                builder: (context) {
                                  String title = "the '" +
                                      shoppingListsVM
                                          .shoppingLists[index].name +
                                      "' list?";
                                  return DeleteNotification(
                                      _onLongPressShoppingList, title, context);
                                });
                          },
                          child: Card(
                              color: toolsVM.getImportanceColor(shoppingListsVM
                                  .shoppingLists[index].importance),
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      shoppingListsVM.shoppingLists[index].name,
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 20),
                                    ),
                                    Row(
                                      children: [
                                        shoppingListsVM.shoppingLists[index]
                                                    .list.length !=
                                                0
                                            ? Container(
                                                width: 100,
                                                child: Text(
                                                  shoppingListsVM
                                                          .shoppingLists[index]
                                                          .list[0]
                                                          .itemName +
                                                      "${shoppingListsVM.shoppingLists[index].list.length > 1 ? ', ...' : ''}",
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
                                                  .shoppingLists[index]
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
