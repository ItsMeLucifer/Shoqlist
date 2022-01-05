import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shoqlist/viewmodels/firebase_auth_view_model.dart';
import 'package:shoqlist/viewmodels/firebase_view_model.dart';
import 'package:shoqlist/viewmodels/friends_service_view_model.dart';
import 'package:shoqlist/viewmodels/loyalty_cards_view_model.dart';
import 'package:shoqlist/viewmodels/shopping_lists_view_model.dart';
import 'package:shoqlist/viewmodels/tools.dart';
import 'package:shoqlist/widgets/wrapper.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/services.dart';
import 'package:shoqlist/l10n/l10n.dart';
import 'models/shopping_list.dart';
import 'models/shopping_list_item.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:device_info/device_info.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';

final ChangeNotifierProvider<ShoppingListsViewModel> shoppingListsProvider =
    ChangeNotifierProvider((_) => ShoppingListsViewModel());
final loyaltyCardsProvider =
    ChangeNotifierProvider((_) => LoyaltyCardsViewModel());
final toolsProvider = ChangeNotifierProvider((_) => Tools());
final firebaseAuthProvider =
    ChangeNotifierProvider((_) => FirebaseAuthViewModel());
// final firebaseAuthDataProvider =
//     ChangeNotifierProvider((_) => FirebaseAuthViewModel.instance());
final friendsServiceProvider =
    ChangeNotifierProvider((_) => FriendsServiceViewModel());
final ChangeNotifierProvider<FirebaseViewModel> firebaseProvider =
    ChangeNotifierProvider((_) {
  final shoppingLists = _.watch(shoppingListsProvider);
  final loyaltyCards = _.watch(loyaltyCardsProvider);
  final tools = _.watch(toolsProvider);
  final auth = _.watch(firebaseAuthProvider);
  final friends = _.watch(friendsServiceProvider);
  return FirebaseViewModel(shoppingLists, loyaltyCards, tools, auth, friends);
});

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  //Firebase - NoSQL cloud database
  await Firebase.initializeApp();

  //HIVE - Local NoSQL database
  await Hive.initFlutter();
  Hive.registerAdapter(ShoppingListAdapter());
  Hive.registerAdapter(ImportanceAdapter());
  Hive.registerAdapter(ShoppingListItemAdapter());
  await Hive.openBox<ShoppingList>('shopping_lists');
  await Hive.openBox<int>('data_variables');

  //Admob
  MobileAds.instance.initialize();

  //PlatformViewLink
  if (Platform.isAndroid) {
    var androidInfo = await DeviceInfoPlugin().androidInfo;
    var isAndroidOld = (androidInfo.version.sdkInt ?? 0) < 29; //Android 10
    // var useHybridComposition = remoteConfig.getBool(
    //   isAndroidOld
    //       ? RemoteConfigKey.useHybridCompositionOlderOS
    //       : RemoteConfigKey.useHybridCompositionNewerOS,
    // );
    if (isAndroidOld) {
      await PlatformViewsService.synchronizeToNativeViewHierarchy(false);
    }
  }

  //Orientation
  SystemChrome.setPreferredOrientations(
      [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);

  runApp(ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Shoqlist',
      debugShowCheckedModeBanner: false,
      darkTheme: ThemeData(
          backgroundColor: Colors.grey[900],
          textTheme: ThemeData.dark().textTheme,
          primaryTextTheme: TextTheme(
              bodyText2: TextStyle(
                  color: Colors.grey[500], fontWeight: FontWeight.bold),
              headline3: TextStyle(
                  color: Colors.white,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.bold)),
          primaryColor: Colors.black,
          colorScheme: ColorScheme.fromSwatch(
              primarySwatch: Colors.grey, accentColor: Colors.white),
          buttonTheme: ButtonThemeData(
              colorScheme: ColorScheme.fromSwatch(
                  primarySwatch: Colors.grey,
                  backgroundColor: Colors.grey[800])),
          disabledColor: Colors.grey[400],
          primaryColorDark: Colors.grey[600],
          primarySwatch: Colors.grey,
          floatingActionButtonTheme: FloatingActionButtonThemeData(
              backgroundColor: Colors.grey[850],
              foregroundColor: Colors.white)),
      themeMode: ThemeMode.dark,
      supportedLocales: L10n.all,
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate
      ],
      home: Wrapper(),
    );
  }
}
