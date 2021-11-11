import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:shoqlist/widgets/loyaltyCards/loyalty_card_info.dart';

import '../../main.dart';

class LoyaltyCardsHandler extends ConsumerWidget {
  Widget build(BuildContext context, ScopedReader watch) {
    String barCode;
    return Scaffold(
      floatingActionButton: SpeedDial(
        overlayOpacity: 0,
        animatedIcon: AnimatedIcons.menu_close,
        children: [
          SpeedDialChild(
              onTap: () async {
                barCode = await FlutterBarcodeScanner.scanBarcode(
                    "#ff6666", "Cancel", false, ScanMode.DEFAULT);
              },
              child: Icon(Icons.add),
              label: "Add new card"),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                SizedBox(height: 5),
                Text("Loyalty Cards",
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 30)),
                Expanded(
                  child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: loyaltyCardsList(watch)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget loyaltyCardsList(ScopedReader watch) {
    final shoppingListsVM = watch(shoppingListsProvider);
    final toolsVM = watch(toolsProvider);
    return GridView.builder(
        gridDelegate:
            SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3),
        shrinkWrap: true,
        itemCount: shoppingListsVM.loyaltyCardsList.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () {
              shoppingListsVM.toggleItemActivation(
                  shoppingListsVM.currentListIndex, index);
            },
            child: GestureDetector(
              onTap: () {
                showDialog(
                    context: context,
                    builder: (context) {
                      return LoyaltyCardInfo();
                    });
              },
              child: Card(
                color: Colors.grey,
                child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Center(
                        child: Text(
                            shoppingListsVM.loyaltyCardsList[index].cardName))),
              ),
            ),
          );
        });
  }
}
