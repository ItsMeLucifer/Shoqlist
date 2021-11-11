import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shoqlist/main.dart';
import 'package:syncfusion_flutter_barcodes/barcodes.dart';

class LoyaltyCardInfo extends ConsumerWidget {
  Widget build(BuildContext context, ScopedReader watch) {
    final shoppingListsVM = watch(shoppingListsProvider);
    return AlertDialog(
      contentPadding: EdgeInsets.fromLTRB(6, 6, 6, 6),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            shoppingListsVM
                .loyaltyCardsList[shoppingListsVM.currentLoyaltyCardsListIndex]
                .cardName,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 10),
          Container(
            height: 150,
            width: 300,
            child: SfBarcodeGenerator(
              value: shoppingListsVM
                  .loyaltyCardsList[
                      shoppingListsVM.currentLoyaltyCardsListIndex]
                  .barCode,
              showValue: true,
            ),
          )
        ],
      ),
    );
  }
}
