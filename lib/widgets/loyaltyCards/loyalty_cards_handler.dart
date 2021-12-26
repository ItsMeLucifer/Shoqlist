import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';
import 'package:nanoid/nanoid.dart';
import 'package:shoqlist/widgets/components/buttons.dart';
import 'package:shoqlist/widgets/components/dialogs.dart';
import 'package:shoqlist/widgets/loyaltyCards/loyalty_card_info.dart';

import '../../main.dart';

class LoyaltyCardsHandler extends ConsumerWidget {
  void _removeLoyaltyCard(BuildContext context) {
    //DELETE LIST ON FIREBASE
    context.read(firebaseProvider).deleteLoyaltyCardOnFirebase(context
        .read(loyaltyCardsProvider)
        .loyaltyCardsList[
            context.read(loyaltyCardsProvider).currentLoyaltyCardsListIndex]
        .documentId);
    //DELETE LIST LOCALLY
    context.read(loyaltyCardsProvider).deleteLoyaltyCardLocally(
        context.read(loyaltyCardsProvider).currentLoyaltyCardsListIndex);
    Navigator.of(context).pop();
    Navigator.of(context).pop();
  }

  void _addNewLoyaltyCard(BuildContext context) {
    final toolsVM = context.read(toolsProvider);
    final firebaseVM = context.read(firebaseProvider);
    final loyaltyCardsVM = context.read(loyaltyCardsProvider);
    if (toolsVM.loyaltyCardNameController.text != "" &&
        toolsVM.loyaltyCardBarCodeController.text != "") {
      String id = nanoid();
      //ADD LOYALTY CARD TO FIREBASE
      firebaseVM.addNewLoyaltyCardToFirebase(
          toolsVM.loyaltyCardNameController.text,
          toolsVM.loyaltyCardBarCodeController.text,
          id,
          toolsVM.newLoyaltyCardColor.value);
      //ADD LOYALTY CARD LOCALLY
      loyaltyCardsVM.addNewLoyaltyCardLocally(
          toolsVM.loyaltyCardNameController.text,
          toolsVM.loyaltyCardBarCodeController.text,
          id,
          toolsVM.newLoyaltyCardColor.value);
    }
    Navigator.of(context).pop();
  }

  void _updateLoyaltyCardData(BuildContext context) {
    final firebaseVM = context.read(firebaseProvider);
    final toolsVM = context.read(toolsProvider);
    final loyaltyCardsVM = context.read(loyaltyCardsProvider);
    //Firebase
    firebaseVM.updateLoyaltyCard(
        toolsVM.loyaltyCardNameController.text,
        toolsVM.loyaltyCardBarCodeController.text,
        loyaltyCardsVM
            .loyaltyCardsList[loyaltyCardsVM.currentLoyaltyCardsListIndex]
            .documentId,
        toolsVM.newLoyaltyCardColor.value);
    //View
    loyaltyCardsVM.updateLoyaltyCard(
        toolsVM.loyaltyCardNameController.text,
        toolsVM.loyaltyCardBarCodeController.text,
        toolsVM.newLoyaltyCardColor.value);
    Navigator.of(context).pop();
  }

  void _onRefresh(BuildContext context) {
    context.read(firebaseProvider).getLoyaltyCardsFromFirebase(true);
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
                  child: LiquidPullToRefresh(
                      backgroundColor: Theme.of(context).accentColor,
                      color: Theme.of(context).primaryColor,
                      height: 50,
                      animSpeedFactor: 5,
                      showChildOpacityTransition: false,
                      onRefresh: () async {
                        _onRefresh(context);
                      },
                      child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: loyaltyCardsList(watch))),
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
                      builder: (context) => PutLoyaltyCardsData(
                          _addNewLoyaltyCard, 'Add new Loyalty Card'));
                },
                child: Card(
                  color: Theme.of(context).disabledColor.withOpacity(0.5),
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
                String removeTitle = "Remove the '" +
                    loyaltyCardsVM.loyaltyCardsList[fixedIndex].name +
                    "' card?";
                String title = "Edit " +
                    loyaltyCardsVM.loyaltyCardsList[fixedIndex].name +
                    " card";
                toolsVM.setLoyaltyCardControllers(
                    loyaltyCardsVM.loyaltyCardsList[fixedIndex].name,
                    loyaltyCardsVM.loyaltyCardsList[fixedIndex].barCode);
                toolsVM.newLoyaltyCardColor =
                    loyaltyCardsVM.loyaltyCardsList[fixedIndex].color;
                showDialog(
                    context: context,
                    builder: (context) {
                      return PutLoyaltyCardsData(_updateLoyaltyCardData, title,
                          _removeLoyaltyCard, removeTitle);
                    });
              },
              child: LoyaltyCardButton(
                  loyaltyCardsVM.loyaltyCardsList[fixedIndex].name,
                  loyaltyCardsVM.loyaltyCardsList[fixedIndex].isFavorite,
                  loyaltyCardsVM.loyaltyCardsList[fixedIndex].color));
        });
  }
}
