import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shoqlist/constants/app_colors.dart';
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
    super.dispose();
  }

  void _fetchData() {
    final firebaseVM = ref.read(firebaseProvider);
    ref.read(firebaseAuthProvider).setCurrentUserCredentials();
    firebaseVM.getShoppingListsFromFirebase(true);
    firebaseVM.getLoyaltyCardsFromFirebase(true);
    firebaseVM.fetchFriendsList();
    firebaseVM.fetchFriendRequestsList();
    _listenForConnectivityRestore();
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
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onTabTapped,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: AppColors.brandPink,
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
    );
  }
}
