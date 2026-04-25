import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shoqlist/l10n/l10n_extension.dart';
import 'package:shoqlist/main.dart';
import 'package:shoqlist/pages/settings.dart';
import 'package:shoqlist/widgets/homeScreen/home_screen_main_view.dart';
import 'package:shoqlist/widgets/loyaltyCards/loyalty_cards_handler.dart';
import 'package:shoqlist/widgets/social/friends_display.dart';

/// Root widget po autoryzacji. Hostuje 4 taby (Lists / Loyalty / Friends /
/// Settings) z osobnym stosem Navigator per tab — subscreens pushowane przez
/// dany tab nie przykrywają BottomNav, a po zmianie taba stos jest zachowany.
class MainScaffold extends ConsumerStatefulWidget {
  const MainScaffold({super.key});

  @override
  ConsumerState<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends ConsumerState<MainScaffold> {
  int _currentIndex = 0;

  final List<GlobalKey<NavigatorState>> _navigatorKeys =
      List.generate(4, (_) => GlobalKey<NavigatorState>());

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  // Captured service ref — używanie ref.read w dispose() podczas teardown
  // drzewa może rzucić "modify provider while widget tree was building".
  late final _syncService = ref.read(listSyncServiceProvider);

  @override
  void initState() {
    super.initState();
    if (ref.read(firebaseAuthProvider).auth.currentUser != null) {
      _fetchData();
    }
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    // Teardown realtime subscriptions — bez tego StreamSubscriptions zostają
    // i dalej firują applyMergedSnapshot na wyautoryzowanym VM.
    _syncService.shutdown();
    super.dispose();
  }

  void _fetchData() {
    // Cała inicjalizacja odpalana w mikrotasku — wywołania na providers
    // w środku initState lecą podczas buildu drzewa, a nasze hydrate /
    // fetch'e robią notifyListeners (Riverpod by then panicuje). Future
    // odracza wszystko o jeden tick poza lifecycle.
    Future.microtask(() {
      if (!mounted) return;
      final firebaseVM = ref.read(firebaseProvider);
      final shoppingListsVM = ref.read(shoppingListsProvider);
      final uid = ref.read(firebaseAuthProvider).auth.currentUser?.uid;
      ref.read(firebaseAuthProvider).setCurrentUserCredentials();
      // Hydrate-from-cache: ładujemy Hive lokalnie (+ setujemy currentUserId),
      // żeby przy cold start user zobaczył listy natychmiast, zanim dojdzie
      // pierwszy snapshot / fetch z Firestore. Merge potem łączy per-field.
      if (uid != null) {
        shoppingListsVM.displayLocalShoppingLists(uid);
      }
      firebaseVM.getShoppingListsFromFirebase(true);
      firebaseVM.getLoyaltyCardsFromFirebase(true);
      firebaseVM.fetchFriendsList();
      firebaseVM.fetchFriendRequestsList();
      // Włącz realtime listenery — startHome to idempotent, więc bezpieczne
      // nawet przy rekonnekcji z connectivity listener.
      ref.read(listSyncServiceProvider).startHome();
      _listenForConnectivityRestore();
    });
  }

  void _listenForConnectivityRestore() {
    _connectivitySubscription?.cancel();
    _connectivitySubscription =
        Connectivity().onConnectivityChanged.listen((results) {
      if (!mounted) return;
      final online = results.contains(ConnectivityResult.mobile) ||
          results.contains(ConnectivityResult.wifi);
      if (online) {
        ref.read(firebaseProvider).getShoppingListsFromFirebase(true);
      }
    });
  }

  void _onTabTapped(int index) {
    if (index == _currentIndex) {
      // ponowne klikniecie aktywnego taba → pop do korzenia tego taba
      _navigatorKeys[index].currentState?.popUntil((r) => r.isFirst);
    } else {
      setState(() => _currentIndex = index);
    }
  }

  Widget _buildTabNavigator(int index, Widget rootPage) {
    return Navigator(
      key: _navigatorKeys[index],
      onGenerateRoute: (settings) => MaterialPageRoute(
        settings: settings,
        builder: (_) => rootPage,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Dynamic accent — w detail listy dostaje importance color tej listy,
    // poza detail wraca do brandPink. `TweenAnimationBuilder` interpoluje
    // RGB między starą a nową wartością przez 320ms easeOutCubic — dzięki
    // temu push/pop detail nie skacze, tylko płynnie cross-fade'uje navbar.
    final accent = ref.watch(accentColorProvider);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final navigator = _navigatorKeys[_currentIndex].currentState;
        if (navigator != null && navigator.canPop()) {
          navigator.pop();
        }
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: IndexedStack(
          index: _currentIndex,
          children: [
            _buildTabNavigator(0, const HomeScreenMainView()),
            _buildTabNavigator(1, const LoyaltyCardsHandler()),
            _buildTabNavigator(2, const FriendsDisplay()),
            _buildTabNavigator(3, const Settings()),
          ],
        ),
        bottomNavigationBar: TweenAnimationBuilder<Color?>(
          tween: ColorTween(end: accent),
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutCubic,
          builder: (context, animatedAccent, _) => BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: _onTabTapped,
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            selectedItemColor: animatedAccent ?? accent,
            unselectedItemColor: Colors.grey[500],
            selectedLabelStyle: const TextStyle(
              fontFamily: 'Epilogue',
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
            unselectedLabelStyle: const TextStyle(
              fontFamily: 'Epilogue',
              fontSize: 12,
            ),
            elevation: 8,
            items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.list_alt_outlined),
              activeIcon: const Icon(Icons.list_alt),
              label: context.l10n.myLists,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.card_membership_outlined),
              activeIcon: const Icon(Icons.card_membership),
              label: context.l10n.loyaltyCards,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.people_outline),
              activeIcon: const Icon(Icons.people),
              label: context.l10n.friends,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.settings_outlined),
              activeIcon: const Icon(Icons.settings),
              label: context.l10n.settings,
            ),
          ],
          ),
        ),
      ),
    );
  }
}
