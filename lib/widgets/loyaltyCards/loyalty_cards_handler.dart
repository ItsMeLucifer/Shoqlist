import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';
import 'package:nanoid/nanoid.dart';
import 'package:shoqlist/widgets/components/buttons.dart';
import 'package:shoqlist/widgets/components/dialogs.dart';
import 'package:shoqlist/widgets/loyaltyCards/loyalty_card_info.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../main.dart';

class LoyaltyCardsHandler extends ConsumerWidget {
  void _removeLoyaltyCard(BuildContext context, WidgetRef ref) {
    //DELETE LIST ON FIREBASE
    ref.read(firebaseProvider).deleteLoyaltyCardOnFirebase(ref
        .read(loyaltyCardsProvider)
        .loyaltyCardsList[
            ref.read(loyaltyCardsProvider).currentLoyaltyCardsListIndex]
        .documentId);
    //DELETE LIST LOCALLY
    ref.read(loyaltyCardsProvider).deleteLoyaltyCardLocally(
        ref.read(loyaltyCardsProvider).currentLoyaltyCardsListIndex);
    Navigator.of(context).pop();
    Navigator.of(context).pop();
  }

  void _addNewLoyaltyCard(BuildContext context, WidgetRef ref) {
    final toolsVM = ref.read(toolsProvider);
    final firebaseVM = ref.read(firebaseProvider);
    final loyaltyCardsVM = ref.read(loyaltyCardsProvider);
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

  void _updateLoyaltyCardData(BuildContext context, WidgetRef ref) {
    final firebaseVM = ref.read(firebaseProvider);
    final toolsVM = ref.read(toolsProvider);
    final loyaltyCardsVM = ref.read(loyaltyCardsProvider);
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

  void _onRefresh(WidgetRef ref) {
    ref.read(firebaseProvider).getLoyaltyCardsFromFirebase(true);
  }

  Widget build(BuildContext context, WidgetRef ref) {
    final screenSize = MediaQuery.of(context).size;
    final toolsVM = ref.watch(toolsProvider);
    return Scaffold(
      backgroundColor: Theme.of(context).backgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                SizedBox(height: 5),
                Text(AppLocalizations.of(context).loyaltyCards,
                    style: Theme.of(context).primaryTextTheme.headline4),
                Divider(
                  color: Theme.of(context).colorScheme.secondary,
                  indent: 50,
                  endIndent: 50,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 50.0),
                    child: LiquidPullToRefresh(
                        backgroundColor:
                            Theme.of(context).colorScheme.secondary,
                        color: Theme.of(context).primaryColor,
                        height: 50,
                        animSpeedFactor: 5,
                        showChildOpacityTransition: false,
                        onRefresh: () async {
                          _onRefresh(ref);
                        },
                        child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: loyaltyCardsList(ref))),
                  ),
                ),
              ],
            ),
            Positioned(
                bottom: 0,
                child: Container(
                    height: 50,
                    width: screenSize.width,
                    child: !kDebugMode
                        ? AdWidget(ad: toolsVM.adBanner)
                        : Container()))
          ],
        ),
      ),
    );
  }

  Widget loyaltyCardsList(WidgetRef ref) {
    final loyaltyCardsVM = ref.watch(loyaltyCardsProvider);
    final toolsVM = ref.watch(toolsProvider);
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
                          _addNewLoyaltyCard,
                          AppLocalizations.of(context).newCardTitle));
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
                String removeTitle = AppLocalizations.of(context)
                    .removeCardTitle(
                        loyaltyCardsVM.loyaltyCardsList[fixedIndex].name);
                String title = AppLocalizations.of(context).editCardTitle(
                    loyaltyCardsVM.loyaltyCardsList[fixedIndex].name);
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
