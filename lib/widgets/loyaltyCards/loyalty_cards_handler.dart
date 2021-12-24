import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shoqlist/widgets/components/buttons.dart';
import 'package:shoqlist/widgets/components/dialogs.dart';
import 'package:shoqlist/widgets/loyaltyCards/add_new_loyalty_card.dart';
import 'package:shoqlist/widgets/loyaltyCards/loyalty_card_info.dart';

import '../../main.dart';

class LoyaltyCardsHandler extends ConsumerWidget {
  void _onLongPressedLoyaltyCard(BuildContext context) {
    Navigator.of(context).pop();
    //DELETE LIST ON FIREBASE
    context.read(firebaseProvider).deleteLoyaltyCardOnFirebase(context
        .read(loyaltyCardsProvider)
        .loyaltyCardsList[
            context.read(loyaltyCardsProvider).currentLoyaltyCardsListIndex]
        .documentId);
    //DELETE LIST LOCALLY
    context.read(loyaltyCardsProvider).deleteLoyaltyCardLocally(
        context.read(loyaltyCardsProvider).currentLoyaltyCardsListIndex);
  }

  Widget build(BuildContext context, ScopedReader watch) {
    return Scaffold(
      backgroundColor: Theme.of(context).backgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                SizedBox(height: 5),
                Text("Loyalty Cards",
                    style: Theme.of(context).primaryTextTheme.headline4),
                Divider(
                  color: Theme.of(context).accentColor,
                  indent: 50,
                  endIndent: 50,
                ),
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
        itemCount: loyaltyCardsVM.loyaltyCardsList.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return GestureDetector(
                onTap: () {
                  toolsVM.clearLoyaltyCardTextEditingControllers();
                  showDialog(
                      context: context,
                      builder: (context) => AddNewLoyaltyCard());
                },
                child: Card(
                  color: Colors.grey[400],
                  child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Center(
                          child:
                              Icon(Icons.add, size: 50, color: Colors.white))),
                ));
          }
          int fixedIndex = index - 1;
          return GestureDetector(
              onTap: () {
                loyaltyCardsVM.currentLoyaltyCardsListIndex = fixedIndex;
                showDialog(
                    context: context,
                    builder: (context) {
                      return LoyaltyCardInfo();
                    });
              },
              onLongPress: () {
                loyaltyCardsVM.currentLoyaltyCardsListIndex = fixedIndex;
                showDialog(
                    context: context,
                    builder: (context) {
                      String title = "Remove the '" +
                          loyaltyCardsVM.loyaltyCardsList[fixedIndex].name +
                          "' card?";
                      return YesNoDialog(_onLongPressedLoyaltyCard, title);
                    });
              },
              child: LoyaltyCardButton(
                  loyaltyCardsVM.loyaltyCardsList[fixedIndex].name,
                  loyaltyCardsVM.loyaltyCardsList[fixedIndex].isFavorite,
                  loyaltyCardsVM.loyaltyCardsList[fixedIndex].color));
        });
  }
}
