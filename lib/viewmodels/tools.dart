import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:shoqlist/constants/app_colors.dart';
import 'package:shoqlist/models/shopping_list.dart';
import 'package:shoqlist/l10n/l10n_extension.dart';

enum FetchStatus { unfetched, fetched, duringFetching }

enum RefreshStatus { duringRefresh, refreshed }

class Tools extends ChangeNotifier {
  Color getImportanceColor(Importance importance) {
    switch (importance) {
      case Importance.important:
        return AppColors.importanceImportant;
      case Importance.urgent:
        return AppColors.importanceUrgent;
      case Importance.low:
        return AppColors.importanceLow;
      default: //Importance.normal
        return AppColors.importanceNormal;
    }
  }

  String getImportanceLabel(Importance importance) {
    String temp = importance.toString().split(".")[1];
    return temp[0].toUpperCase() + temp.substring(1);
  }

  String getTranslatedImportanceLabel(
      BuildContext context, Importance importance) {
    List<String> importances = [
      context.l10n.low,
      context.l10n.normal,
      context.l10n.important,
      context.l10n.urgent
    ];
    return importances[importance.index];
  }

  Importance getImportanceValueFromLabel(String label) {
    for (int i = 0; i < Importance.values.length; i++) {
      if (getImportanceLabel(Importance.values[i]) == label) {
        return Importance.values[i];
      }
    }
    return Importance.normal;
  }

  String getFirstCapitalLetter(String text) {
    return text[0].toUpperCase() + text.substring(1);
  }

  String deleteAllWhitespacesFromString(String input) {
    return input.replaceAll(' ', '');
  }

  void printWarning(String text) {
    // `developer.log` jest niezawodne na iOS (debugPrint czasem nie dochodzi
    // do VSCode debug console na fizycznym device / niektórych symulatorach).
    // Level 900 = WARNING — pokazuje się żółty w VSCode.
    developer.log(text, name: 'shoqlist', level: 900);
  }

  //Home Page
  FetchStatus _fetchStatus = FetchStatus.duringFetching;
  FetchStatus get fetchStatus => _fetchStatus;
  set fetchStatus(FetchStatus status) {
    _fetchStatus = status;
    notifyListeners();
  }

  //New nickname
  TextEditingController newNicknameController = TextEditingController();
  void clearNewNicknameController() {
    newNicknameController.clear();
    notifyListeners();
  }

  //Add new List
  Importance _newListImportance = Importance.normal;
  Importance get newListImportance => _newListImportance;
  set newListImportance(Importance value) {
    _newListImportance = value;
    notifyListeners();
  }

  TextEditingController newListNameController = TextEditingController();
  void setNewListNameControllerText(String newListName) {
    newListNameController.text = newListName;
    notifyListeners();
  }

  void resetNewListData() {
    _newListImportance = Importance.normal;
    newListNameController.text = "";
    notifyListeners();
  }

  Key? newListNameFormFieldKey;
  //Add new Item
  FocusNode newItemFocusNode = FocusNode();
  TextEditingController newItemNameController = TextEditingController();
  Key? addNewItemNameFormFieldKey;
  void clearNewItemTextEditingController() {
    newItemNameController.clear();
    notifyListeners();
  }

  //Add new Card
  Key? addNewCardNameFormFieldKey;
  Key? addNewCardBarCodeFormFieldKey;

  TextEditingController loyaltyCardNameController = TextEditingController();
  TextEditingController loyaltyCardBarCodeController = TextEditingController();
  void setLoyaltyCardControllers(String name, String barCode) {
    loyaltyCardNameController.text = name;
    loyaltyCardBarCodeController.text = barCode;
    notifyListeners();
  }

  void clearLoyaltyCardTextEditingControllers() {
    loyaltyCardNameController.clear();
    loyaltyCardBarCodeController.clear();
    notifyListeners();
  }

  //Authentication
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  void clearAuthenticationTextEditingControllers() {
    emailController.clear();
    passwordController.clear();
    notifyListeners();
  }

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

  //Add new Loyalty Card
  Color _newLoyaltyCardColor = Colors.white;
  Color get newLoyaltyCardColor => _newLoyaltyCardColor;
  set newLoyaltyCardColor(Color value) {
    _newLoyaltyCardColor = value;
    notifyListeners();
  }

  //Friends
  FetchStatus _friendsFetchStatus = FetchStatus.unfetched;
  FetchStatus get friendsFetchStatus => _friendsFetchStatus;
  set friendsFetchStatus(FetchStatus status) {
    _friendsFetchStatus = status;
    notifyListeners();
  }

  //Refresh
  RefreshStatus _refreshStatus = RefreshStatus.refreshed;
  RefreshStatus get refreshStatus => _refreshStatus;
  set refreshStatus(RefreshStatus newStatus) {
    _refreshStatus = newStatus;
    notifyListeners();
  }

  @override
  void dispose() {
    newNicknameController.dispose();
    newListNameController.dispose();
    newItemFocusNode.dispose();
    newItemNameController.dispose();
    loyaltyCardNameController.dispose();
    loyaltyCardBarCodeController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}
