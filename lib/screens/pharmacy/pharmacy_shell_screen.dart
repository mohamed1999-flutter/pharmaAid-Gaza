import 'package:flutter/material.dart';

import '../../core/service/auth_service.dart';
import '../../core/service/firestore_service.dart';
import '../auth/login_screen.dart';
import 'pharmacy_categories_screen.dart' as categories_screen;
import 'pharmacy_dashboard_screen.dart';
import 'pharmacy_medicines_screen.dart' as medicines_screen;
import 'pharmacy_orders_screen.dart' as orders_screen;
import 'pharmacy_profile_screen.dart' as profile_screen;

class PharmacyShellScreen extends StatefulWidget {
  const PharmacyShellScreen({super.key});

  @override
  State<PharmacyShellScreen> createState() => _PharmacyShellScreenState();
}

class _PharmacyShellScreenState extends State<PharmacyShellScreen> {
  int _index = 0;

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
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

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
              AuthService.signOut();
              return const LoginScreen();
            }

            return Directionality(
              textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
              child: Scaffold(
                body: IndexedStack(index: _index, children: _screens),
                bottomNavigationBar: NavigationBar(
                  selectedIndex: _index,
                  onDestinationSelected: (value) {
                    if (value == _index) return;
                    setState(() => _index = value);
                  },
                  height: 70,
                  labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                  destinations: [
                    NavigationDestination(
                      icon: const Icon(Icons.dashboard_outlined),
                      selectedIcon: const Icon(Icons.dashboard_rounded),
                      label: isAr ? 'الرئيسية' : 'Home',
                    ),
                    NavigationDestination(
                      icon: const Icon(Icons.category_outlined),
                      selectedIcon: const Icon(Icons.category_rounded),
                      label: isAr ? 'الكاتجوري' : 'Categories',
                    ),
                    NavigationDestination(
                      icon: const Icon(Icons.medication_outlined),
                      selectedIcon: const Icon(Icons.medication_rounded),
                      label: isAr ? 'الأدوية' : 'Medicines',
                    ),
                    NavigationDestination(
                      icon: const Icon(Icons.receipt_long_outlined),
                      selectedIcon: const Icon(Icons.receipt_long_rounded),
                      label: isAr ? 'الطلبات' : 'Orders',
                    ),
                    NavigationDestination(
                      icon: const Icon(Icons.storefront_outlined),
                      selectedIcon: const Icon(Icons.storefront_rounded),
                      label: isAr ? 'الصيدلية' : 'Pharmacy',
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
