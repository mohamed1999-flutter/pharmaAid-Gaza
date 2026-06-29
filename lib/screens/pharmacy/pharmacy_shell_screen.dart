import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:firebase_auth/firebase_auth.dart';
import '../../core/service/firestore_service.dart';
import '../../main.dart';
import '../auth/login_screen.dart';
import 'pharmacy_categories_screen.dart' as categories_screen;
import 'pharmacy_dashboard_screen.dart';
import 'pharmacy_medicines_screen.dart' as medicines_screen;
import 'pharmacy_orders_screen.dart' as orders_screen;
import 'pharmacy_profile_screen.dart' as profile_screen;

class PharmacyShellScreen extends StatelessWidget {
  const PharmacyShellScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final user = context.watch<User?>();

    if (user == null) {
      return const LoginScreen(initialTarget: LoginTarget.pharmacy);
    }

    return StreamBuilder(
      stream: FirestoreService.pharmacyStream(user.uid),
      builder: (context, pharmacySnapshot) {
        if (pharmacySnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!pharmacySnapshot.hasData ||
            pharmacySnapshot.data?.data() == null) {
          // If profile doesn't exist, we might want to sign out or handle it
          return const Scaffold(
            body: Center(child: Text('Pharmacy profile not found')),
          );
        }

        return _PharmacyMainScaffold(isAr: isAr);
      },
    );
  }
}

class _PharmacyMainScaffold extends StatefulWidget {
  const _PharmacyMainScaffold({required this.isAr});

  final bool isAr;

  @override
  State<_PharmacyMainScaffold> createState() => _PharmacyMainScaffoldState();
}

class _PharmacyMainScaffoldState extends State<_PharmacyMainScaffold> {
  int _index = 0;

  static const double _bottomBarHeight = 92;

  late final List<Widget> _screens = [
    const PharmacyDashboardScreen(key: PageStorageKey('pharmacy_dashboard')),
    const categories_screen.PharmacyCategoriesScreen(
      key: PageStorageKey('pharmacy_categories'),
    ),
    const medicines_screen.PharmacyMedicinesScreen(
      key: PageStorageKey('pharmacy_medicines'),
    ),
    const orders_screen.PharmacyOrdersScreen(
      key: PageStorageKey('pharmacy_orders'),
    ),
    const profile_screen.PharmacyProfileScreen(
      key: PageStorageKey('pharmacy_profile'),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Directionality(
      textDirection: widget.isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        extendBody: false,
        backgroundColor: cs.surface,
        body: IndexedStack(index: _index, children: _screens),
        bottomNavigationBar: SafeArea(
          top: false,
          left: false,
          right: false,
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: cs.surface,
              border: Border(top: BorderSide(color: cs.outlineVariant)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 20,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: NavigationBarTheme(
              data: NavigationBarThemeData(
                backgroundColor: Colors.transparent,
                elevation: 0,
                surfaceTintColor: Colors.transparent,
                indicatorColor: cs.primary.withOpacity(0.12),
                labelTextStyle: WidgetStatePropertyAll(
                  TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: cs.primary,
                  ),
                ),
                iconTheme: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return IconThemeData(color: cs.primary, size: 26);
                  }
                  return IconThemeData(color: cs.onSurfaceVariant, size: 23);
                }),
              ),
              child: NavigationBar(
                selectedIndex: _index,
                onDestinationSelected: (value) {
                  if (value == _index) return;
                  setState(() => _index = value);
                },
                height: _bottomBarHeight,
                labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                destinations: [
                  NavigationDestination(
                    icon: const Icon(Icons.dashboard_outlined),
                    selectedIcon: const Icon(Icons.dashboard_rounded),
                    label: widget.isAr ? 'الرئيسية' : 'Home',
                  ),
                  NavigationDestination(
                    icon: const Icon(Icons.category_outlined),
                    selectedIcon: const Icon(Icons.category_rounded),
                    label: widget.isAr ? 'الكاتجوري' : 'Categories',
                  ),
                  NavigationDestination(
                    icon: const Icon(Icons.medication_outlined),
                    selectedIcon: const Icon(Icons.medication_rounded),
                    label: widget.isAr ? 'الأدوية' : 'Medicines',
                  ),
                  NavigationDestination(
                    icon: const Icon(Icons.receipt_long_outlined),
                    selectedIcon: const Icon(Icons.receipt_long_rounded),
                    label: widget.isAr ? 'الطلبات' : 'Orders',
                  ),
                  NavigationDestination(
                    icon: const Icon(Icons.storefront_outlined),
                    selectedIcon: const Icon(Icons.storefront_rounded),
                    label: widget.isAr ? 'الصيدلية' : 'Pharmacy',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
