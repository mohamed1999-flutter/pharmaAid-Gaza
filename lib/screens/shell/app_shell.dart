import 'package:flutter/material.dart';

import '../../core/localization/app_keys.dart';
import '../../core/localization/app_texts.dart';
import '../home_screen/home_screen.dart';
import '../offers/offers_screen.dart';

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
      _SimplePage(title: AppTexts.tr(context, AppKeys.pharmacies)),
      _SimplePage(title: AppTexts.tr(context, AppKeys.profile)),
    ];

    return Scaffold(
      backgroundColor: bg,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: KeyedSubtree(key: ValueKey(_index), child: pages[_index]),
      ),
      bottomNavigationBar: _BottomNav(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        isDark: isDark,
        context: context,
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({
    required this.currentIndex,
    required this.onTap,
    required this.isDark,
    required this.context,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final bool isDark;
  final BuildContext context;

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? const Color(0xFF1B1B1B) : Colors.white;
    final inactive = isDark ? Colors.white54 : Colors.black38;
    const active = Color(0xFF16C26F);

    final items = [
      (Icons.home_filled, AppTexts.tr(this.context, AppKeys.home)),
      (Icons.local_offer_outlined, AppTexts.tr(this.context, AppKeys.offers)),
      (
        Icons.local_pharmacy_outlined,
        AppTexts.tr(this.context, AppKeys.pharmacies),
      ),
      (Icons.person_outline, AppTexts.tr(this.context, AppKeys.profile)),
    ];

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.18 : 0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: List.generate(items.length, (index) {
          final item = items[index];
          final selected = currentIndex == index;

          return Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () => onTap(index),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: selected
                          ? active.withOpacity(0.12)
                          : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(item.$1, color: selected ? active : inactive),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.$2,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: selected ? active : inactive,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _SimplePage extends StatelessWidget {
  const _SimplePage({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF111111) : Colors.white,
      body: Center(
        child: Text(
          title,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
      ),
    );
  }
}
