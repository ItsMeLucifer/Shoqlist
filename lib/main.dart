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
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:flutter/services.dart';
import 'package:shoqlist/l10n/l10n.dart';
import 'package:shoqlist/models/shopping_list.dart';
import 'package:shoqlist/models/shopping_list_item.dart';
import 'package:shoqlist/l10n/app_localizations.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:shoqlist/constants/app_colors.dart';

final ChangeNotifierProvider<ShoppingListsViewModel> shoppingListsProvider =
    ChangeNotifierProvider((_) => ShoppingListsViewModel());
final loyaltyCardsProvider =
    ChangeNotifierProvider((_) => LoyaltyCardsViewModel());
final toolsProvider = ChangeNotifierProvider((_) => Tools());
final firebaseAuthProvider =
    ChangeNotifierProvider((_) => FirebaseAuthViewModel());
final friendsServiceProvider =
    ChangeNotifierProvider((_) => FriendsServiceViewModel());
final ChangeNotifierProvider<FirebaseViewModel> firebaseProvider =
    ChangeNotifierProvider((ref) {
  final shoppingLists = ref.watch(shoppingListsProvider);
  final loyaltyCards = ref.watch(loyaltyCardsProvider);
  final tools = ref.watch(toolsProvider);
  final auth = ref.watch(firebaseAuthProvider);
  final friends = ref.watch(friendsServiceProvider);
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
  await MobileAds.instance.initialize();

  //Orientation
  SystemChrome.setPreferredOrientations(
      [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);

  runApp(ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Shoqlist',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        listTileTheme: ListTileThemeData(
          tileColor: AppColors.surfaceGray,
          iconColor: AppColors.neutralIcon,
        ),
        textTheme: ThemeData.dark().textTheme.copyWith(
              bodyMedium: TextStyle(
                fontFamily: 'Epilogue',
                color: AppColors.brandPink,
                fontSize: 18,
              ),
              bodyLarge: TextStyle(
                fontFamily: 'Epilogue',
                color: AppColors.brandPink,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
        primaryTextTheme: TextTheme(
            bodyMedium: TextStyle(
              color: Colors.grey[500],
              fontWeight: FontWeight.bold,
              fontFamily: 'Epilogue',
            ),
            displaySmall: TextStyle(
              color: AppColors.brandPink,
              fontWeight: FontWeight.bold,
              fontSize: 50,
              fontFamily: 'Epilogue',
            ),
            headlineMedium: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 40,
              color: AppColors.brandPink,
              fontFamily: 'Epilogue',
            ),
            headlineSmall: TextStyle(
              fontFamily: 'Epilogue',
              color: Colors.black,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
            titleLarge: TextStyle(
              fontFamily: 'Epilogue',
              color: Colors.black,
              fontSize: 18,
            ),
            labelLarge: TextStyle(
              fontFamily: 'Epilogue',
              color: Colors.black,
              fontSize: 18,
            )),
        primaryColor: Colors.white,
        buttonTheme: ButtonThemeData(
          colorScheme: ColorScheme.fromSwatch(
            primarySwatch: Colors.grey,
            backgroundColor: AppColors.surfaceGray,
          ),
        ),
        disabledColor: Colors.grey[400],
        primaryColorDark: Colors.grey[600],
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: AppColors.brandPink,
          foregroundColor: Colors.white,
          extendedTextStyle: TextStyle(
            fontFamily: 'Epilogue',
            color: Colors.white,
            fontSize: 15,
          ),
        ),
        colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.grey).copyWith(
          primary: Colors.grey,
          secondary: AppColors.brandPink,
          surface: Colors.white,
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
