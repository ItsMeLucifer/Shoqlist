import 'package:flutter/material.dart';
import 'package:shoqlist/models/shopping_list.dart';

class Tools extends ChangeNotifier {
  Color getImportanceColor(Importance importance) {
    switch (importance) {
      case Importance.important:
        return Colors.orange[200];
      case Importance.urgent:
        return Colors.red[300];
      case Importance.low:
        return Colors.blue[200];
      case Importance.normal:
        return Colors.green[200];
      // default:
      //   return Colors.green[200];
    }
  }

  String getImportanceLabel(Importance importance) {
    String temp = importance.toString().split(".")[1];
    return temp[0].toUpperCase() + temp.substring(1);
  }

  //Add new Item
  Importance _newItemImportance = Importance.normal;
  Importance get newItemImportance => _newItemImportance;
  set newItemImportance(Importance value) {
    _newItemImportance = value;
    notifyListeners();
  }

  TextEditingController nameController = TextEditingController();
  Key addNewItemNameFormFieldKey;

  //Add new Card
  Key addNewCardNameFormFieldKey;
  Key addNewCardBarCodeFormFieldKey;
}
