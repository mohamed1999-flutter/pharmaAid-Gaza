import 'package:flutter/material.dart';

import '../../core/service/auth_service.dart';
import '../../widgets/app_bottom_nav.dart';
import '../auth/login_screen.dart';
import '../home_screen/home_screen.dart';
import '../offers/offers_screen.dart';
import 'orders_screen.dart';
import 'pharmacies_screen.dart';

// Standard User Shell with 4 main screens
class UserShellScreen extends StatefulWidget {
  const UserShellScreen({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<UserShellScreen> createState() => _UserShellScreenState();
}

class _UserShellScreenState extends State<UserShellScreen> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: AuthService.authStateChanges(),
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = authSnapshot.data;
        if (user == null) {
          return const LoginScreen();
        }

        return _UserMainScaffold(initialIndex: widget.initialIndex);
      },
    );
  }
}

class _UserMainScaffold extends StatefulWidget {
  const _UserMainScaffold({this.initialIndex = 0});

  final int initialIndex;

  @override
  State<_UserMainScaffold> createState() => _UserMainScaffoldState();
}

class _UserMainScaffoldState extends State<_UserMainScaffold> {
  late int _index = widget.initialIndex;

  final List<Widget> _screens = [
    const HomeScreen(key: PageStorageKey('user_home')),
    const OffersScreen(key: PageStorageKey('user_offers')),
    const PharmaciesScreen(key: PageStorageKey('user_pharmacies')),
    const OrdersScreen(key: PageStorageKey('user_orders')),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF111111) : Colors.white;

    return Scaffold(
      backgroundColor: bg,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: KeyedSubtree(key: ValueKey(_index), child: _screens[_index]),
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        isDark: isDark,
      ),
    );
  }
}
