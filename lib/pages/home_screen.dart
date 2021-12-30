import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:nanoid/nanoid.dart';
import 'package:shoqlist/main.dart';
import 'package:shoqlist/pages/settings.dart';
import 'package:shoqlist/viewmodels/tools.dart';
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
  final BannerAd adBanner = BannerAd(
      adUnitId: 'ca-app-pub-6556175768591042/6145501750',
      size: AdSize.banner,
      request: AdRequest(),
      listener: AdListener());

  @override
  initState() {
    super.initState();
    if (ref.read(firebaseAuthProvider).auth.currentUser != null) {
      fetchData(ref);
    }
    if (!kDebugMode) adBanner.load();
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
    ref.read(firebaseProvider).getShoppingListsFromFirebase(true);
    ref.read(firebaseProvider).getLoyaltyCardsFromFirebase(true);
    ref.read(firebaseProvider).fetchFriendsList();
    ref.read(firebaseProvider).fetchFriendRequestsList();
    _whenInternetConnectionIsRestoredCompareDatabasesAgain(ref);
  }

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

  void _createNewShoppingList(WidgetRef ref) {
    final toolsVM = ref.read(toolsProvider);
    final firebaseVM = ref.read(firebaseProvider);
    final shopingListsProviderVM = ref.read(shoppingListsProvider);
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
    final screenSize = MediaQuery.of(context).size;
    return Scaffold(
        backgroundColor: Theme.of(context).backgroundColor,
        floatingActionButton: Padding(
          padding: const EdgeInsets.only(bottom: 35.0),
          child: SpeedDial(
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
                    labelStyle: Theme.of(context).textTheme.bodyText2,
                    onTap: () {
                      ref.read(toolsProvider).resetNewListData();
                      showDialog(
                          context: context,
                          builder: (context) => PutShoppingListData(
                              _createNewShoppingList, context));
                    },
                    backgroundColor: Theme.of(context)
                        .floatingActionButtonTheme
                        .backgroundColor,
                    child: Icon(
                      Icons.add,
                      color: Theme.of(context)
                          .floatingActionButtonTheme
                          .foregroundColor,
                    ),
                    label: AppLocalizations.of(context).newList),
                SpeedDialChild(
                    labelBackgroundColor: Theme.of(context)
                        .floatingActionButtonTheme
                        .backgroundColor,
                    labelStyle: Theme.of(context).textTheme.bodyText2,
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
                    labelStyle: Theme.of(context).textTheme.bodyText2,
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
                    labelStyle: Theme.of(context).textTheme.bodyText2,
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
        ),
        body: Stack(
          children: [
            HomeScreenMainView(),
            Positioned(
                bottom: 0,
                child: Container(
                    height: 50,
                    width: screenSize.width,
                    child: !kDebugMode ? AdWidget(ad: adBanner) : Container())),
            // child: Container()))
          ],
        ));
  }
}
