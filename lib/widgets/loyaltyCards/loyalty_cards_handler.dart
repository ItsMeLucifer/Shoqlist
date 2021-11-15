import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:shoqlist/widgets/loyaltyCards/add_new_loyalty_card.dart';
import 'package:shoqlist/widgets/loyaltyCards/loyalty_card_info.dart';

import '../../main.dart';

class LoyaltyCardsHandler extends ConsumerWidget {
  Widget build(BuildContext context, ScopedReader watch) {
    final toolsVM = watch(toolsProvider);
    return Scaffold(
      floatingActionButton: SpeedDial(
        overlayOpacity: 0,
        animatedIcon: AnimatedIcons.menu_close,
        children: [
          SpeedDialChild(
              onTap: () async {
                showDialog(context: context, child: AddNewLoyaltyCard());
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
    final loyaltyCardsVM = watch(loyaltyCardsProvider);
    final toolsVM = watch(toolsProvider);
    return GridView.builder(
        gridDelegate:
            SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3),
        shrinkWrap: true,
        itemCount: loyaltyCardsVM.loyaltyCardsList.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () {
              loyaltyCardsVM.currentLoyaltyCardsListIndex = index;
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
                          loyaltyCardsVM.loyaltyCardsList[index].cardName))),
            ),
          );
        });
  }
}
