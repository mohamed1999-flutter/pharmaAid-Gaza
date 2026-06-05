import 'package:flutter/material.dart';

import 'pharmacy_categories_screen.dart';
import 'pharmacy_dashboard_screen.dart';
import 'pharmacy_medicines_screen.dart';
import 'pharmacy_orders_screen.dart';
import 'pharmacy_profile_screen.dart';

/// Main shell for the pharmacy system.
class PharmacyShellScreen extends StatefulWidget {
  const PharmacyShellScreen({super.key});

  @override
  State<PharmacyShellScreen> createState() => _PharmacyShellScreenState();
}

class _PharmacyShellScreenState extends State<PharmacyShellScreen> {
  int _index = 0;

  late final List<Widget> _screens = [
    const PharmacyDashboardScreen(),
    const PharmacyCategoriesScreen(),
    const PharmacyMedicinesScreen(),
    const PharmacyOrdersScreen(),
    const PharmacyProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final direction = isAr ? TextDirection.rtl : TextDirection.ltr;

    return Directionality(
      textDirection: direction,
      child: Scaffold(
        body: IndexedStack(index: _index, children: _screens),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _index,
          onTap: (value) => setState(() => _index = value),
          type: BottomNavigationBarType.fixed,
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.home_outlined),
              label: isAr ? 'الرئيسية' : 'Home',
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.category_outlined),
              label: isAr ? 'الكاتجوري' : 'Categories',
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.medical_services_outlined),
              label: isAr ? 'الأدوية' : 'Medicines',
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.receipt_long_outlined),
              label: isAr ? 'الطلبات' : 'Orders',
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.local_pharmacy_outlined),
              label: isAr ? 'الصيدلية' : 'Pharmacy',
            ),
          ],
        ),
      ),
    );
  }
}
