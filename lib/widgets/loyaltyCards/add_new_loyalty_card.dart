import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nanoid/nanoid.dart';
import 'package:shoqlist/main.dart';

import '../color_picker.dart';

class AddNewLoyaltyCard extends ConsumerWidget {
  Widget build(BuildContext context, ScopedReader watch) {
    final loyaltyCardsVM = watch(loyaltyCardsProvider);
    final toolsVM = watch(toolsProvider);
    final firebaseVM = watch(firebaseProvider);
    const double _alertDialogWidth = 250;
    const double _dividerHeight = 10;
    return SimpleDialog(
        backgroundColor: Theme.of(context).backgroundColor,
        children: [
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Container(
                height: 310,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Add new Loyalty Card",
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: _dividerHeight),
                    TextFormField(
                      key: toolsVM.addNewCardNameFormFieldKey,
                      keyboardType: TextInputType.name,
                      autofocus: false,
                      autocorrect: false,
                      obscureText: false,
                      controller: toolsVM.loyaltyCardNameController,
                      style: TextStyle(fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        hintText: "Card name",
                        hintStyle: Theme.of(context).primaryTextTheme.bodyText2,
                        contentPadding: EdgeInsets.fromLTRB(20, 10, 20, 10),
                        enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                                width: 1,
                                color: Theme.of(context).primaryColorDark)),
                        focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                                width: 1,
                                color: Theme.of(context).accentColor)),
                      ),
                    ),
                    SizedBox(height: _dividerHeight),
                    ColorPicker(_alertDialogWidth, 100),
                    SizedBox(height: _dividerHeight),
                    TextFormField(
                      key: toolsVM.addNewCardBarCodeFormFieldKey,
                      keyboardType: TextInputType.name,
                      autofocus: false,
                      autocorrect: false,
                      obscureText: false,
                      controller: toolsVM.loyaltyCardBarCodeController,
                      style: TextStyle(fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        hintText: "Card code",
                        suffixIcon: GestureDetector(
                          onTap: () async {
                            toolsVM.loyaltyCardBarCodeController.text =
                                await FlutterBarcodeScanner.scanBarcode(
                                    "#ff6666",
                                    "Cancel",
                                    true,
                                    ScanMode.DEFAULT);
                            if (toolsVM.loyaltyCardBarCodeController.text ==
                                '-1')
                              toolsVM.loyaltyCardBarCodeController.text = '';
                          },
                          child: Icon(Icons.qr_code,
                              color: Theme.of(context).accentColor),
                        ),
                        hintStyle: Theme.of(context).primaryTextTheme.bodyText2,
                        contentPadding: EdgeInsets.fromLTRB(20, 10, 20, 10),
                        enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                                width: 1,
                                color: Theme.of(context).primaryColorDark)),
                        focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                                width: 1,
                                color: Theme.of(context).accentColor)),
                      ),
                    ),
                    SizedBox(height: _dividerHeight),
                    FlatButton(
                        color: Theme.of(context).buttonColor,
                        onPressed: () {
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
                        },
                        child: Text(
                          'Add',
                          style: Theme.of(context).primaryTextTheme.bodyText1,
                        )),
                  ],
                )),
          ),
        ]);
  }
}
