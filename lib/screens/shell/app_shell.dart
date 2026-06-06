import 'package:flutter/material.dart';

import '../../widgets/app_bottom_nav.dart';
import '../home_screen/home_screen.dart';
import '../offers/offers_screen.dart';
import '../user/orders_screen.dart';
import '../user/pharmacies_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF111111) : Colors.white;

    final pages = <Widget>[
      const HomeScreen(),
      const OffersScreen(),
      const PharmaciesScreen(),
      const OrdersScreen(),
    ];

    return Scaffold(
      backgroundColor: bg,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: KeyedSubtree(key: ValueKey(_index), child: pages[_index]),
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        isDark: isDark,
      ),
    );
  }
}
