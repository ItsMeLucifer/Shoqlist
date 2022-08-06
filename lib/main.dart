import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shoqlist/models/user.dart';
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
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

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

  //Firebase
  await Firebase.initializeApp();
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterError;

  //HIVE - Local NoSQL database
  await Hive.initFlutter();
  Hive.registerAdapter(ShoppingListAdapter());
  Hive.registerAdapter(ImportanceAdapter());
  Hive.registerAdapter(ShoppingListItemAdapter());
  Hive.registerAdapter(UserAdapter());
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
      theme: ThemeData(
        listTileTheme: ListTileThemeData(
          tileColor: Color.fromRGBO(237, 236, 242, 1),
          iconColor: Color.fromRGBO(187, 191, 201, 1),
        ),
        backgroundColor: Colors.white,
        textTheme: ThemeData.dark().textTheme.copyWith(
              bodyText2: TextStyle(
                fontFamily: 'Epilogue',
                color: Color.fromRGBO(242, 102, 116, 1),
                fontSize: 18,
              ),
              bodyText1: TextStyle(
                fontFamily: 'Epilogue',
                color: Color.fromRGBO(242, 102, 116, 1),
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
        primaryTextTheme: TextTheme(
            bodyText2: TextStyle(
              color: Colors.grey[500],
              fontWeight: FontWeight.bold,
              fontFamily: 'Epilogue',
            ),
            headline3: TextStyle(
              color: Color.fromRGBO(242, 102, 116, 1),
              fontWeight: FontWeight.bold,
              fontSize: 50,
              fontFamily: 'Epilogue',
            ),
            headline4: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 40,
              color: Color.fromRGBO(242, 102, 116, 1),
              fontFamily: 'Epilogue',
            ),
            headline5: TextStyle(
              fontFamily: 'Epilogue',
              color: Colors.black,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
            headline6: TextStyle(
              fontFamily: 'Epilogue',
              color: Colors.black,
              fontSize: 18,
            ),
            button: TextStyle(
              fontFamily: 'Epilogue',
              color: Colors.black,
              fontSize: 18,
            )),
        primaryColor: Colors.white,
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: Colors.grey,
          accentColor: Color.fromRGBO(242, 102, 116, 1),
        ),
        buttonTheme: ButtonThemeData(
          colorScheme: ColorScheme.fromSwatch(
            primarySwatch: Colors.grey,
            backgroundColor: Color.fromRGBO(237, 236, 242, 1),
          ),
        ),
        disabledColor: Colors.grey[400],
        primaryColorDark: Colors.grey[600],
        primarySwatch: Colors.grey,
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: Color.fromRGBO(242, 102, 116, 1),
          foregroundColor: Colors.white,
          extendedTextStyle: TextStyle(
            fontFamily: 'Epilogue',
            color: Colors.white,
            fontSize: 15,
          ),
        ),
      ),
      themeMode: ThemeMode.light,
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
