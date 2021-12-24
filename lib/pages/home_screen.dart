import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';
import 'package:nanoid/nanoid.dart';
import 'package:shoqlist/main.dart';
import 'package:shoqlist/pages/settings.dart';
import 'package:shoqlist/widgets/components/dialogs.dart';
import 'package:shoqlist/widgets/homeScreen/home_screen_main_view.dart';
import 'package:shoqlist/widgets/loyaltyCards/loyalty_cards_handler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shoqlist/widgets/social/friends_display.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreen createState() => _HomeScreen();
}

class _HomeScreen extends State<HomeScreen> {
  @override
  initState() {
    super.initState();
    fetchData();
  }

  void _whenInternetConnectionIsRestoredCompareDatabasesAgain() {
    Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      if (result == ConnectivityResult.mobile ||
          result == ConnectivityResult.wifi) {
        context.read(firebaseProvider).getShoppingListsFromFirebase(true);
      }
    });
  }

  void fetchData() {
    context.read(shoppingListsProvider).clearDisplayedData();
    context.read(firebaseProvider).getShoppingListsFromFirebase(true);
    context.read(firebaseProvider).getLoyaltyCardsFromFirebase(true);
    context.read(firebaseProvider).fetchFriendsList();
    context.read(firebaseProvider).fetchFriendRequestsList();
    _whenInternetConnectionIsRestoredCompareDatabasesAgain();
  }

  // void _onRefresh() {
  //   context.read(shoppingListsProvider).clearDisplayedData();
  //   context.read(firebaseProvider).getShoppingListsFromFirebase(true);
  // }

  void _navigateToLoyaltyCardsHandler(BuildContext context) {
    Navigator.push(context,
        MaterialPageRoute(builder: (context) => LoyaltyCardsHandler()));
  }

  void _navigateToSettings(BuildContext context) {
    Navigator.push(
        context, MaterialPageRoute(builder: (context) => Settings()));
  }

  void _navigateToFriendsDisplay(BuildContext context) {
    Navigator.push(
        context, MaterialPageRoute(builder: (context) => FriendsDisplay()));
  }

  void _createNewShoppingList(
    BuildContext context,
  ) {
    final toolsVM = context.read(toolsProvider);
    final firebaseVM = context.read(firebaseProvider);
    final shopingListsProviderVM = context.read(shoppingListsProvider);
    if (toolsVM.newListNameController.text != "") {
      String id = nanoid();
      //CREATE LIST ON SERVER
      firebaseVM.putShoppingListToFirebase(
          toolsVM.newListNameController.text, toolsVM.newListImportance, id);
      //CREATE LIST LOCALLY
      shopingListsProviderVM.saveNewShoppingListLocally(
          toolsVM.newListNameController.text, toolsVM.newListImportance, id);
    }
  }

  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Theme.of(context).backgroundColor,
        floatingActionButton: SpeedDial(
            overlayOpacity: 0,
            animatedIcon: AnimatedIcons.menu_close,
            backgroundColor:
                Theme.of(context).floatingActionButtonTheme.backgroundColor,
            children: [
              SpeedDialChild(
                  onTap: () {
                    context.read(toolsProvider).resetNewListData();
                    showDialog(
                        context: context,
                        builder: (context) => PutShoppingListData(
                            _createNewShoppingList, context));
                  },
                  backgroundColor: Theme.of(context)
                      .floatingActionButtonTheme
                      .backgroundColor,
                  child: Icon(Icons.add),
                  label: 'Create new list'),
              SpeedDialChild(
                  onTap: () {
                    _navigateToLoyaltyCardsHandler(context);
                  },
                  backgroundColor: Theme.of(context)
                      .floatingActionButtonTheme
                      .backgroundColor,
                  child: Icon(Icons.card_membership),
                  label: 'Loyalty cards'),

              SpeedDialChild(
                  onTap: () {
                    _navigateToFriendsDisplay(context);
                  },
                  backgroundColor: Theme.of(context)
                      .floatingActionButtonTheme
                      .backgroundColor,
                  child: Icon(Icons.people),
                  label: 'Friends'),
              SpeedDialChild(
                  onTap: () {
                    _navigateToSettings(context);
                  },
                  backgroundColor: Theme.of(context)
                      .floatingActionButtonTheme
                      .backgroundColor,
                  child: Icon(Icons.settings),
                  label: 'Settings'),
              // SpeedDialChild(
              // onTap: () {
              //   //SCAN
              // },
              // backgroundColor: Theme.of(context)
              //     .floatingActionButtonTheme
              //     .backgroundColor,
              // child: Icon(Icons.qr_code_scanner_rounded),
              // label: 'Scan your list'),
            ]),
        body: HomeScreenMainView());
  }
}
