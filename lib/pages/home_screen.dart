import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:shoqlist/main.dart';
import 'package:shoqlist/pages/settings.dart';
import 'package:shoqlist/widgets/homeScreen/home_screen_main_view.dart';
import 'package:shoqlist/widgets/loyaltyCards/loyalty_cards_handler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreen createState() => _HomeScreen();
}

class _HomeScreen extends State<HomeScreen> {
  @override
  initState() {
    super.initState();
    context.read(firebaseProvider).getShoppingListsFromFirebase();
  }

  void _navigateToLoyaltyCardsHandler(BuildContext context) {
    Navigator.push(context,
        MaterialPageRoute(builder: (context) => LoyaltyCardsHandler()));
  }

  void _navigateToSettings(BuildContext context) {
    Navigator.push(
        context, MaterialPageRoute(builder: (context) => Settings()));
  }

  Widget build(BuildContext context) {
    return Scaffold(
        floatingActionButton: SpeedDial(
            overlayOpacity: 0,
            animatedIcon: AnimatedIcons.menu_close,
            children: [
              SpeedDialChild(
                  onTap: () {
                    _navigateToSettings(context);
                  },
                  child: Icon(Icons.settings),
                  label: 'Settings'),
              SpeedDialChild(
                  onTap: () {
                    //SCAN
                  },
                  child: Icon(Icons.qr_code_scanner_rounded),
                  label: 'Scan your list'),
              SpeedDialChild(
                  onTap: () {
                    _navigateToLoyaltyCardsHandler(context);
                  },
                  child: Icon(Icons.card_membership),
                  label: 'Loyalty cards'),
            ]),
        body: HomeScreenMainView());
  }
}
