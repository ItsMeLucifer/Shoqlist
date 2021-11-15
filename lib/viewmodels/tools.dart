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

  Importance getImportanceValueFromLabel(String label) {
    for (int i = 0; i < Importance.values.length; i++) {
      if (getImportanceLabel(Importance.values[i]) == label)
        return Importance.values[i];
    }
  }

  //Add new List
  Importance _newListImportance = Importance.normal;
  Importance get newListImportance => _newListImportance;
  set newListImportance(Importance value) {
    _newListImportance = value;
    notifyListeners();
  }

  TextEditingController newListNameController = TextEditingController();
  Key newListNameFormFieldKey;
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

  //Authentication
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  bool _indicator = false;
  bool get indicator => _indicator;
  set indicator(bool value) {
    _indicator = value;
    notifyListeners();
  }

  bool _showPassword = false;
  bool get showPassword => _showPassword;
  set showPassword(bool value) {
    _showPassword = value;
    notifyListeners();
  }
}
