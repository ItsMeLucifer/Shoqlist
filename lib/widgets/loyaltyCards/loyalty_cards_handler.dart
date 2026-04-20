import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';
import 'package:nanoid/nanoid.dart';
import 'package:shoqlist/widgets/components/buttons.dart';
import 'package:shoqlist/widgets/components/dialogs.dart';
import 'package:shoqlist/widgets/components/native_ad_banner.dart';
import 'package:shoqlist/widgets/loyaltyCards/loyalty_card_info.dart';
import 'package:shoqlist/l10n/l10n_extension.dart';

import '../../main.dart';

class LoyaltyCardsHandler extends ConsumerWidget {
  const LoyaltyCardsHandler({super.key});

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
          toolsVM.newLoyaltyCardColor.toARGB32());
      //ADD LOYALTY CARD LOCALLY
      loyaltyCardsVM.addNewLoyaltyCardLocally(
          toolsVM.loyaltyCardNameController.text,
          toolsVM.loyaltyCardBarCodeController.text,
          id,
          toolsVM.newLoyaltyCardColor.toARGB32());
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
        toolsVM.newLoyaltyCardColor.toARGB32());
    //View
    loyaltyCardsVM.updateLoyaltyCard(
        toolsVM.loyaltyCardNameController.text,
        toolsVM.loyaltyCardBarCodeController.text,
        toolsVM.newLoyaltyCardColor.toARGB32());
    Navigator.of(context).pop();
  }

  void _onRefresh(WidgetRef ref) {
    ref.read(firebaseProvider).getLoyaltyCardsFromFirebase(true);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenSize = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20.0),
              width: screenSize.width,
              child: Text(
                context.l10n.loyaltyCards,
                style: Theme.of(context).primaryTextTheme.headlineMedium,
              ),
            ),
            Expanded(
              child: LiquidPullToRefresh(
                  backgroundColor: Theme.of(context).colorScheme.secondary,
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
            const NativeAdBanner(),
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
        shrinkWrap: false,
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
                    context.l10n.newCardTitle,
                  ),
                );
              },
              child: Card(
                color: Theme.of(context).disabledColor.withValues(alpha: 0.5),
                child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Center(
                        child: Icon(Icons.add, size: 50, color: Colors.white))),
              ),
            );
          }
          int fixedIndex = index - 1;
          return GestureDetector(
              onTap: () {
                loyaltyCardsVM.currentLoyaltyCardsListIndex = fixedIndex;
                showDialog(
                  context: context,
                  builder: (context) {
                    return LoyaltyCardInfo();
                  },
                );
              },
              onLongPress: () {
                loyaltyCardsVM.currentLoyaltyCardsListIndex = fixedIndex;
                String removeTitle = context.l10n
                    .removeCardTitle(
                        loyaltyCardsVM.loyaltyCardsList[fixedIndex].name);
                String title = context.l10n.editCardTitle(
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
