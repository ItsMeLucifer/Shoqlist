import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shoqlist/viewmodels/firebase_auth_view_model.dart';
import 'package:shoqlist/viewmodels/firebase_view_model.dart';
import 'package:shoqlist/viewmodels/loyalty_cards_view_model.dart';
import 'package:shoqlist/viewmodels/shopping_lists_view_model.dart';
import 'package:shoqlist/viewmodels/tools.dart';
import 'package:shoqlist/widgets/wrapper.dart';

final shoppingListsProvider =
    ChangeNotifierProvider((_) => ShoppingListsViewModel());
final loyaltyCardsProvider =
    ChangeNotifierProvider((_) => LoyaltyCardsViewModel());
final toolsProvider = ChangeNotifierProvider((_) => Tools());
final firebaseAuthProvider =
    ChangeNotifierProvider((_) => FirebaseAuthViewModel());
final firebaseProvider = ChangeNotifierProvider((_) {
  final shoppingLists = _.watch(shoppingListsProvider);
  final loyaltyCards = _.watch(loyaltyCardsProvider);
  final tools = _.watch(toolsProvider);
  final auth = _.watch(firebaseAuthProvider);
  return FirebaseViewModel(shoppingLists, loyaltyCards, tools, auth);
});
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Shoqlist',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
          primarySwatch: Colors.grey,
          primaryColor: Colors.white,
          accentColor: Colors.black,
          textTheme: Typography.blackCupertino,
          visualDensity: VisualDensity.adaptivePlatformDensity,
          scaffoldBackgroundColor: Color.fromRGBO(237, 246, 249, 1),
          floatingActionButtonTheme:
              FloatingActionButtonThemeData(backgroundColor: Colors.white)),
      home: Wrapper(),
    );
  }
}
