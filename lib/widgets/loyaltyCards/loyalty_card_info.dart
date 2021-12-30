import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shoqlist/main.dart';
import 'package:syncfusion_flutter_barcodes/barcodes.dart';

class LoyaltyCardInfo extends ConsumerWidget {
  Widget build(BuildContext context, WidgetRef ref) {
    final loyaltyCardsVM = ref.watch(loyaltyCardsProvider);
    return AlertDialog(
      backgroundColor: Colors.white,
      contentPadding: EdgeInsets.fromLTRB(6, 6, 6, 6),
      content: Column(
        mainAxisAlignment: MainAxisAlignment.start,
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
                    color: Colors.black,
                    size: 15,
                  ),
                  SizedBox(width: 5),
                  Text("Favorite",
                      style: TextStyle(fontSize: 15, color: Colors.black)),
                ],
              ),
              onPressed: () {
                String documentId = loyaltyCardsVM
                    .loyaltyCardsList[
                        loyaltyCardsVM.currentLoyaltyCardsListIndex]
                    .documentId;
                Navigator.of(context).pop();
                //FIREBASE
                ref
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
            style: TextStyle(
                fontSize: 25, fontWeight: FontWeight.bold, color: Colors.black),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 10),
          Container(
            height: 150,
            width: 300,
            child: SfBarcodeGenerator(
              textStyle: TextStyle(color: Colors.black),
              backgroundColor: Colors.white,
              barColor: Colors.black,
              value: loyaltyCardsVM
                  .loyaltyCardsList[loyaltyCardsVM.currentLoyaltyCardsListIndex]
                  .barCode,
              showValue: true,
            ),
          ),
          SizedBox(height: 20),
        ],
      ),
    );
  }
}
