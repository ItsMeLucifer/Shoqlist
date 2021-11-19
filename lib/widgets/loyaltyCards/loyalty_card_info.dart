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
          Align(
            alignment: Alignment.centerRight,
            child: FlatButton(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    loyaltyCardsVM
                            .loyaltyCardsList[
                                loyaltyCardsVM.currentLoyaltyCardsListIndex]
                            .isFavorite
                        ? Icons.star
                        : Icons.star_border_outlined,
                    size: 15,
                  ),
                  SizedBox(width: 5),
                  Text("Favorite", style: TextStyle(fontSize: 15)),
                ],
              ),
              onPressed: () {
                String documentId = loyaltyCardsVM
                    .loyaltyCardsList[
                        loyaltyCardsVM.currentLoyaltyCardsListIndex]
                    .documentId;
                Navigator.of(context).pop();
                //FIREBASE
                context
                    .read(firebaseProvider)
                    .toggleFavoriteOfLoyaltyCardOnFirebase(documentId);
                //LOCALLY
                loyaltyCardsVM.toggleLoyaltyCardFavoriteLocally();
                loyaltyCardsVM.sortLoyaltyCardsListLocally();
              },
            ),
          ),
          Text(
            loyaltyCardsVM
                .loyaltyCardsList[loyaltyCardsVM.currentLoyaltyCardsListIndex]
                .name,
            style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
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
