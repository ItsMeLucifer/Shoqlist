import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nanoid/nanoid.dart';
import 'package:shoqlist/main.dart';

class AddNewLoyaltyCard extends ConsumerWidget {
  Widget build(BuildContext context, ScopedReader watch) {
    final loyaltyCardsVM = watch(loyaltyCardsProvider);
    final toolsVM = watch(toolsProvider);
    final firebaseVM = watch(firebaseProvider);

    return AlertDialog(
      content: Container(
          height: 300,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Add new Loyalty Card",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              Container(
                height: 200,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
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
                        hintStyle: TextStyle(
                            color: Color.fromRGBO(
                              0,
                              0,
                              0,
                              0.3,
                            ),
                            fontWeight: FontWeight.bold),
                        contentPadding: EdgeInsets.fromLTRB(20, 10, 20, 10),
                        enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                                width: 1,
                                color: Color.fromRGBO(
                                  0,
                                  0,
                                  0,
                                  0.3,
                                ))),
                        focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                                width: 1,
                                color: Color.fromRGBO(
                                  0,
                                  0,
                                  0,
                                  1,
                                ))),
                      ),
                    ),
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
                          },
                          child: Icon(Icons.qr_code),
                        ),
                        hintStyle: TextStyle(
                            color: Color.fromRGBO(
                              0,
                              0,
                              0,
                              0.3,
                            ),
                            fontWeight: FontWeight.bold),
                        contentPadding: EdgeInsets.fromLTRB(20, 10, 20, 10),
                        enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                                width: 1,
                                color: Color.fromRGBO(
                                  0,
                                  0,
                                  0,
                                  0.3,
                                ))),
                        focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                                width: 1,
                                color: Color.fromRGBO(
                                  0,
                                  0,
                                  0,
                                  1,
                                ))),
                      ),
                    ),
                  ],
                ),
              ),
              FlatButton(
                  color: Color.fromRGBO(0, 0, 0, 0.2),
                  onPressed: () {
                    if (toolsVM.loyaltyCardNameController.text != "" &&
                        toolsVM.loyaltyCardBarCodeController.text != "") {
                      String id = nanoid();
                      //ADD LOYALTY CARD TO FIREBASE
                      firebaseVM.addNewLoyaltyCardToFirebase(
                          toolsVM.loyaltyCardNameController.text,
                          toolsVM.loyaltyCardBarCodeController.text,
                          id);
                      //ADD LOYALTY CARD LOCALLY
                      loyaltyCardsVM.addNewLoyaltyCardLocally(
                          toolsVM.loyaltyCardNameController.text,
                          toolsVM.loyaltyCardBarCodeController.text,
                          id);
                    }
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    'Add',
                  )),
            ],
          )),
    );
  }
}
