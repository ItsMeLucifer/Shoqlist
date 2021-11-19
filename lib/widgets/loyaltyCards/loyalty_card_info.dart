import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shoqlist/main.dart';
import 'package:syncfusion_flutter_barcodes/barcodes.dart';

class LoyaltyCardInfo extends ConsumerWidget {
  Widget build(BuildContext context, ScopedReader watch) {
    final loyaltyCardsVM = watch(loyaltyCardsProvider);
    return AlertDialog(
      contentPadding: EdgeInsets.fromLTRB(6, 6, 6, 6),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            loyaltyCardsVM
                .loyaltyCardsList[loyaltyCardsVM.currentLoyaltyCardsListIndex]
                .name,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          FlatButton(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(loyaltyCardsVM
                        .loyaltyCardsList[
                            loyaltyCardsVM.currentLoyaltyCardsListIndex]
                        .isFavorite
                    ? Icons.star
                    : Icons.star_outlined),
                SizedBox(width: 5),
                Text("Favorite"),
              ],
            ),
            onPressed: () {
              String documentId = loyaltyCardsVM
                  .loyaltyCardsList[loyaltyCardsVM.currentLoyaltyCardsListIndex]
                  .documentId;
              //FIREBASE
              context
                  .read(firebaseProvider)
                  .toggleFavoriteOfLoyaltyCardOnFirebase(documentId);
              //LOCALLY
              loyaltyCardsVM.toggleLoyaltyCardFavoriteLocally();
            },
          ),
          SizedBox(height: 10),
          Container(
            height: 150,
            width: 300,
            child: SfBarcodeGenerator(
              value: loyaltyCardsVM
                  .loyaltyCardsList[loyaltyCardsVM.currentLoyaltyCardsListIndex]
                  .barCode,
              showValue: true,
            ),
          )
        ],
      ),
    );
  }
}
