import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shoqlist/viewmodels/firebase_auth_view_model.dart';
import 'package:shoqlist/viewmodels/firebase_view_model.dart';
import 'package:shoqlist/viewmodels/friends_service_view_model.dart';
import 'package:shoqlist/viewmodels/loyalty_cards_view_model.dart';
import 'package:shoqlist/viewmodels/shopping_lists_view_model.dart';
import 'package:shoqlist/viewmodels/tools.dart';
import 'package:shoqlist/widgets/wrapper.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'models/shopping_list.dart';
import 'models/shopping_list_item.dart';

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

  //Firebase - NoSQL databese in the cloud
  await Firebase.initializeApp();

  //HIVE - Local NoSQL database
  await Hive.initFlutter();
  Hive.registerAdapter(ShoppingListAdapter());
  Hive.registerAdapter(ImportanceAdapter());
  Hive.registerAdapter(ShoppingListItemAdapter());
  await Hive.openBox<ShoppingList>('shopping_lists');
  await Hive.openBox<int>('data_variables');

  runApp(ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  @override
  Widget build(BuildContext context, ScopedReader watch) {
    final toolsVM = watch(toolsProvider);
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
          primaryColor: Colors.black87,
          accentColor: Colors.white,
          disabledColor: Colors.grey[400],
          primarySwatch: Colors.grey,
          buttonColor: Colors.grey[800],
          floatingActionButtonTheme: FloatingActionButtonThemeData(
              backgroundColor: Colors.grey[850],
              foregroundColor: Colors.white)),
      theme: ThemeData(
          primaryTextTheme: TextTheme(
              bodyText2: TextStyle(
                  color: Colors.grey[400], fontWeight: FontWeight.bold),
              headline3: TextStyle(
                  color: Colors.black,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.bold)),
          primarySwatch: Colors.grey,
          primaryColor: Colors.white,
          disabledColor: Colors.grey[400],
          accentColor: Colors.black,
          primaryColorDark: Colors.black38,
          textTheme: Typography.blackCupertino,
          visualDensity: VisualDensity.adaptivePlatformDensity,
          scaffoldBackgroundColor: Color.fromRGBO(237, 246, 249, 1),
          floatingActionButtonTheme: FloatingActionButtonThemeData(
              backgroundColor: Colors.white, foregroundColor: Colors.black)),
      themeMode: toolsVM.darkMode ? ThemeMode.dark : ThemeMode.light,
      home: Wrapper(),
    );
  }
}
