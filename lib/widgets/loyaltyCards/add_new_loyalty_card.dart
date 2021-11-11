import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shoqlist/main.dart';

class AddNewLoyaltyCard extends ConsumerWidget {
  Widget build(BuildContext context, ScopedReader watch) {
    final shoppingListsVM = watch(shoppingListsProvider);
    final toolsVM = watch(toolsProvider);
    TextEditingController nameController = TextEditingController();
    TextEditingController barCodeController = TextEditingController();
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
                      controller: nameController,
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
                      controller: barCodeController,
                      style: TextStyle(fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        hintText: "Card code",
                        suffixIcon: GestureDetector(
                          onTap: () async {
                            barCodeController.text =
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
                    if (nameController.text != "" &&
                        barCodeController.text != "")
                      shoppingListsVM.addNewLoyaltyCard(
                          nameController.text, barCodeController.text);
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
