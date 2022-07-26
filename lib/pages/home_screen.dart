import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:nanoid/nanoid.dart';
import 'package:shoqlist/main.dart';
import 'package:shoqlist/pages/settings.dart';
import 'package:shoqlist/widgets/components/dialogs.dart';
import 'package:shoqlist/widgets/homeScreen/home_screen_main_view.dart';
import 'package:shoqlist/widgets/loyaltyCards/loyalty_cards_handler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shoqlist/widgets/social/friends_display.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class HomeScreen extends StatefulWidget {
  final WidgetRef ref;
  HomeScreen(this.ref);
  State<HomeScreen> createState() => _HomeScreen(ref);
}

class _HomeScreen extends State<HomeScreen> {
  final WidgetRef ref;
  _HomeScreen(this.ref);

  @override
  initState() {
    super.initState();
    if (ref.read(firebaseAuthProvider).auth.currentUser != null) {
      fetchData(ref);
    }
  }

  void _whenInternetConnectionIsRestoredCompareDatabasesAgain(WidgetRef ref) {
    Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      if (result == ConnectivityResult.mobile ||
          result == ConnectivityResult.wifi) {
        ref.read(firebaseProvider).getShoppingListsFromFirebase(true);
      }
    });
  }

  void fetchData(WidgetRef ref) {
    final firebaseVM = ref.read(firebaseProvider);
    ref.read(firebaseAuthProvider).setCurrentUserCredentials();
    firebaseVM.getShoppingListsFromFirebase(true);
    firebaseVM.getLoyaltyCardsFromFirebase(true);
    firebaseVM.fetchFriendsList();
    firebaseVM.fetchFriendRequestsList();
    _whenInternetConnectionIsRestoredCompareDatabasesAgain(ref);
  }

  void _navigateToLoyaltyCardsHandler(BuildContext context) async {
    if (!await ref.read(toolsProvider).adBanner.isLoaded()) {
      ref.read(toolsProvider).adBanner.load();
      ref.read(toolsProvider).printWarning('Ad loaded');
    }
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

  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Theme.of(context).backgroundColor,
        floatingActionButton: SpeedDial(
            foregroundColor:
                Theme.of(context).floatingActionButtonTheme.foregroundColor,
            overlayOpacity: 0,
            animatedIcon: AnimatedIcons.menu_close,
            backgroundColor:
                Theme.of(context).floatingActionButtonTheme.backgroundColor,
            children: [
              SpeedDialChild(
                  labelBackgroundColor: Theme.of(context)
                      .floatingActionButtonTheme
                      .backgroundColor,
                  labelStyle: Theme.of(context)
                      .floatingActionButtonTheme
                      .extendedTextStyle,
                  onTap: () {
                    _navigateToLoyaltyCardsHandler(context);
                  },
                  backgroundColor: Theme.of(context)
                      .floatingActionButtonTheme
                      .backgroundColor,
                  child: Icon(
                    Icons.card_membership,
                    color: Theme.of(context)
                        .floatingActionButtonTheme
                        .foregroundColor,
                  ),
                  label: AppLocalizations.of(context).loyaltyCards),
              SpeedDialChild(
                  labelBackgroundColor: Theme.of(context)
                      .floatingActionButtonTheme
                      .backgroundColor,
                  labelStyle: Theme.of(context)
                      .floatingActionButtonTheme
                      .extendedTextStyle,
                  onTap: () {
                    _navigateToFriendsDisplay(context);
                  },
                  backgroundColor: Theme.of(context)
                      .floatingActionButtonTheme
                      .backgroundColor,
                  child: Icon(
                    Icons.people,
                    color: Theme.of(context)
                        .floatingActionButtonTheme
                        .foregroundColor,
                  ),
                  label: AppLocalizations.of(context).friends),
              SpeedDialChild(
                  labelBackgroundColor: Theme.of(context)
                      .floatingActionButtonTheme
                      .backgroundColor,
                  labelStyle: Theme.of(context)
                      .floatingActionButtonTheme
                      .extendedTextStyle,
                  onTap: () {
                    _navigateToSettings(context);
                  },
                  backgroundColor: Theme.of(context)
                      .floatingActionButtonTheme
                      .backgroundColor,
                  child: Icon(
                    Icons.settings,
                    color: Theme.of(context)
                        .floatingActionButtonTheme
                        .foregroundColor,
                  ),
                  label: AppLocalizations.of(context).settings),
            ]),
        body: HomeScreenMainView());
  }
}
