import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:hive/hive.dart';
import 'package:nanoid/nanoid.dart';
import 'package:shoqlist/main.dart';
import 'package:shoqlist/pages/settings.dart';
import 'package:shoqlist/widgets/components/dialogs.dart';
import 'package:shoqlist/widgets/homeScreen/home_screen_main_view.dart';
import 'package:shoqlist/widgets/loyaltyCards/loyalty_cards_handler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreen createState() => _HomeScreen();
}

class _HomeScreen extends State<HomeScreen> {
  @override
  void dispose() {
    Hive.box('shopping_lists').close();
    super.dispose();
  }

  @override
  initState() {
    super.initState();
    context.read(firebaseProvider).getShoppingListsFromFirebase(true);
    context.read(firebaseProvider).getLoyaltyCardsFromFirebase(true);
    whenInternetConnectionIsRestoredCompareDatabasesAgain();
  }

  void whenInternetConnectionIsRestoredCompareDatabasesAgain() {
    Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      if (result == ConnectivityResult.mobile ||
          result == ConnectivityResult.wifi) {
        context.read(firebaseProvider).getShoppingListsFromFirebase(true);
      }
    });
  }

  void _navigateToLoyaltyCardsHandler(BuildContext context) {
    Navigator.push(context,
        MaterialPageRoute(builder: (context) => LoyaltyCardsHandler()));
  }

  void _navigateToSettings(BuildContext context) {
    Navigator.push(
        context, MaterialPageRoute(builder: (context) => Settings()));
  }

  void _createNewShoppingList(
    BuildContext context,
  ) {
    if (context.read(toolsProvider).newListNameController.text != "") {
      String id = nanoid();
      //CREATE LIST ON SERVER
      context.read(firebaseProvider).putShoppingListToFirebase(
          context.read(toolsProvider).newListNameController.text,
          context.read(toolsProvider).newListImportance,
          id);
      //CREATE LIST LOCALLY
      context.read(shoppingListsProvider).saveNewShoppingListLocally(
          context.read(toolsProvider).newListNameController.text,
          context.read(toolsProvider).newListImportance,
          id);
    }
  }

  Widget build(BuildContext context) {
    return Scaffold(
        floatingActionButton: SpeedDial(
            overlayOpacity: 0,
            animatedIcon: AnimatedIcons.menu_close,
            backgroundColor:
                Theme.of(context).floatingActionButtonTheme.backgroundColor,
            children: [
              SpeedDialChild(
                  onTap: () {
                    _navigateToSettings(context);
                  },
                  backgroundColor: Theme.of(context)
                      .floatingActionButtonTheme
                      .backgroundColor,
                  child: Icon(Icons.settings),
                  label: 'Settings'),
              SpeedDialChild(
                  onTap: () {
                    //SCAN
                  },
                  backgroundColor: Theme.of(context)
                      .floatingActionButtonTheme
                      .backgroundColor,
                  child: Icon(Icons.qr_code_scanner_rounded),
                  label: 'Scan your list'),
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
            ]),
        body: HomeScreenMainView());
  }
}
