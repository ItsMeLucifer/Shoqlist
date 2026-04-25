import 'dart:developer' as developer;

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
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
import 'package:shoqlist/viewmodels/sync/firestore_migrator.dart';
import 'package:shoqlist/viewmodels/sync/list_sync_service.dart';
import 'package:shoqlist/viewmodels/sync/list_writer.dart';
import 'package:shoqlist/viewmodels/sync/pending_writes_tracker.dart';
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
final pendingWritesTrackerProvider =
    Provider((_) => PendingWritesTracker());

/// Globalny accent color używany jako podświetlenie navbara (i opcjonalnie
/// innych elementów cross-screen). Default = `AppColors.brandPink`.
/// `_ShoppingListDisplayState` nadpisuje go w `initState` na importance
/// color aktualnej listy i resetuje w `dispose`. Dzięki temu cała apka
/// chwilowo "ubiera się" w kolor otwartej listy.
final accentColorProvider =
    StateProvider<Color>((_) => AppColors.brandPink);
// Shadow-write v1 mirrors: ON przez jedno okno release, żeby stare wersje
// apki shared userów nie wysypały się przy czytaniu cudzej (zmigrowanej)
// listy. Flipnij na false po upgrade wszystkich klientów.
final listWriterProvider =
    Provider((_) => ListWriter(shadowWriteV1Mirrors: true));
final firestoreMigratorProvider =
    Provider((_) => FirestoreMigrator(shadowWriteV1Mirrors: true));
final ChangeNotifierProvider<FirebaseViewModel> firebaseProvider =
    ChangeNotifierProvider((ref) {
  final shoppingLists = ref.watch(shoppingListsProvider);
  final loyaltyCards = ref.watch(loyaltyCardsProvider);
  final tools = ref.watch(toolsProvider);
  final auth = ref.watch(firebaseAuthProvider);
  final friends = ref.watch(friendsServiceProvider);
  final tracker = ref.watch(pendingWritesTrackerProvider);
  final writer = ref.watch(listWriterProvider);
  final migrator = ref.watch(firestoreMigratorProvider);
  return FirebaseViewModel(shoppingLists, loyaltyCards, tools, auth, friends,
      tracker, writer, migrator);
});
final listSyncServiceProvider = Provider<ListSyncService>((ref) {
  final firebaseVM = ref.watch(firebaseProvider);
  final auth = ref.watch(firebaseAuthProvider);
  final shoppingLists = ref.watch(shoppingListsProvider);
  return ListSyncService(firebaseVM, auth, shoppingLists);
});

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  //Firebase
  await Firebase.initializeApp();
  // W debug chcemy widzieć błędy zarówno w VSCode debug console (czerwony
  // dump z Flutter) jak i w Crashlytics. Bezpośrednie podstawienie handlera
  // pożerało wszystko do Crashlytics i konsola była głucha. iOS dodatkowo
  // czasem filtruje `print` — `developer.log` jest niezawodny.
  FlutterError.onError = (FlutterErrorDetails details) {
    if (kDebugMode) {
      FlutterError.presentError(details);
      developer.log(
        'FlutterError: ${details.exceptionAsString()}',
        name: 'shoqlist',
        error: details.exception,
        stackTrace: details.stack,
      );
    }
    FirebaseCrashlytics.instance.recordFlutterError(details);
  };
  // Errors poza Flutter framework (np. async leak'i, Future bez catch).
  PlatformDispatcher.instance.onError = (error, stack) {
    if (kDebugMode) {
      developer.log(
        'PlatformError: $error',
        name: 'shoqlist',
        error: error,
        stackTrace: stack,
      );
    }
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: false);
    return true;
  };

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
