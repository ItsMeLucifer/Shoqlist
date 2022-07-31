import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shoqlist/models/shopping_list.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

enum FetchStatus { unfetched, fetched, duringFetching }
enum RefreshStatus { duringRefresh, refreshed }

class Tools extends ChangeNotifier {
  Color getImportanceColor(Importance importance) {
    switch (importance) {
      case Importance.important:
        return Color.fromRGBO(253, 202, 64, 1);
      case Importance.urgent:
        return Color.fromRGBO(242, 102, 116, 1);
      case Importance.low:
        return Color.fromRGBO(66, 129, 164, 1);
      default: //Importance.normal
        return Color.fromRGBO(67, 197, 158, 1);
    }
  }

  String getImportanceLabel(Importance importance) {
    String temp = importance.toString().split(".")[1];
    return temp[0].toUpperCase() + temp.substring(1);
  }

  String getTranslatedImportanceLabel(
      BuildContext context, Importance importance) {
    List<String> _importances = [
      AppLocalizations.of(context).low,
      AppLocalizations.of(context).normal,
      AppLocalizations.of(context).important,
      AppLocalizations.of(context).urgent
    ];
    return _importances[importance.index];
  }

  Importance getImportanceValueFromLabel(String label) {
    for (int i = 0; i < Importance.values.length; i++) {
      if (getImportanceLabel(Importance.values[i]) == label)
        return Importance.values[i];
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
    print('\x1B[33m$text\x1B[0m');
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

  Key newListNameFormFieldKey;
  //Add new Item
  FocusNode newItemFocusNode = FocusNode();
  TextEditingController newItemNameController = TextEditingController();
  Key addNewItemNameFormFieldKey;
  void clearNewItemTextEditingController() {
    newItemNameController.clear();
    notifyListeners();
  }

  //Add new Card
  Key addNewCardNameFormFieldKey;
  Key addNewCardBarCodeFormFieldKey;

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

  //Ad
  final BannerAd adBanner = BannerAd(
      adUnitId: 'ca-app-pub-6556175768591042/6145501750',
      size: AdSize.banner,
      request: AdRequest(),
      listener: AdListener());
}
