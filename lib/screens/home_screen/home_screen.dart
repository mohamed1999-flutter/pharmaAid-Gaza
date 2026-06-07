import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app/app_controller.dart';
import '../../core/localization/app_keys.dart';
import '../../core/localization/app_texts.dart';
import '../../core/models/user_models.dart';
import '../../core/providers/cart_provider.dart';
import '../../core/service/auth_service.dart';
import '../../core/service/firestore_service.dart';
import '../auth/login_screen.dart';
import '../chat/chat_list_screen.dart';
import '../user/cart_screen.dart';
import '../user/pharmacies_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PageController _pageController = PageController();
  int _currentBanner = 0;

  bool get _isArabic => Localizations.localeOf(context).languageCode == 'ar';

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  String _t(BuildContext context, String key) {
    return AppTexts.tr(context, key);
  }

  Future<void> _showSwitchDialog() async {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Directionality(
          textDirection: _isArabic ? TextDirection.rtl : TextDirection.ltr,
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            contentPadding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            title: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.swap_horiz_rounded,
                  size: 44,
                  color: colorScheme.primary,
                ),
                const SizedBox(height: 10),
                Text(
                  _t(context, AppKeys.switchSystemTitle),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            content: Text(
              _t(context, AppKeys.switchSystemMessage),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(
                  _t(context, AppKeys.no),
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                onPressed: () async {
                  // Close dialog first.
                  Navigator.of(dialogContext).pop();

                  // Switch app mode to pharmacy in the controller.
                  // Note: We do NOT sign out the customer here.
                  await context.read<AppController>().setAppMode(
                    AppMode.pharmacy,
                  );

                  if (!mounted) return;

                  // Navigate to pharmacy login screen directly as requested.
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const LoginScreen(
                        initialTarget: LoginTarget.pharmacy,
                      ),
                    ),
                  );
                },
                child: Text(
                  _t(context, AppKeys.yes),
                  style: TextStyle(
                    color: colorScheme.onPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _addToCart(_ProductItem item) async {
    final cart = context.read<CartProvider>();
    final isAr = _isArabic;

    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Get first available pharmacy as a fallback for dummy items
      final pharmacies = await FirestoreService.pharmaciesStream().first;
      if (!mounted) return;
      Navigator.pop(context); // Close loading

      if (pharmacies.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isAr ? 'لا توجد صيدليات متاحة حالياً' : 'No pharmacies available',
            ),
          ),
        );
        return;
      }

      final pharmacyDoc = pharmacies.docs.first;
      final pharmacyData = pharmacyDoc.data();
      final pharmacyId = pharmacyDoc.id;
      final pharmacyName =
          pharmacyData['pharmacyName'] ?? pharmacyData['name'] ?? 'Pharmacy';

      await cart.addItem(
        CartItem(
          medicineId: item.id,
          name: item.title,
          price: double.parse(item.price),
          quantity: 1,
          pharmacyId: pharmacyId,
          pharmacyName: pharmacyName,
        ),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isAr ? 'تم الإضافة إلى السلة' : 'Added to cart successfully',
          ),
          action: SnackBarAction(
            label: isAr ? 'عرض السلة' : 'View Cart',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CartScreen()),
              );
            },
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        if (Navigator.canPop(context)) Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isAr ? 'حدث خطأ ما' : 'Something went wrong')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final isDark = theme.brightness == Brightness.dark;
    final direction = _isArabic ? TextDirection.rtl : TextDirection.ltr;

    final bannerItems = <_BannerItem>[
      _BannerItem(
        title: _t(context, AppKeys.banner1Title),
        subtitle: _t(context, AppKeys.banner1Subtitle),
      ),
      _BannerItem(
        title: _t(context, AppKeys.banner2Title),
        subtitle: _t(context, AppKeys.banner2Subtitle),
      ),
      _BannerItem(
        title: _t(context, AppKeys.banner3Title),
        subtitle: _t(context, AppKeys.banner3Subtitle),
      ),
    ];

    final categories = <_CategoryItem>[
      _CategoryItem(
        icon: Icons.local_hospital_outlined,
        label: _t(context, AppKeys.categoryMedicine),
      ),
      _CategoryItem(
        icon: Icons.female_outlined,
        label: _t(context, AppKeys.categoryWomen),
      ),
      _CategoryItem(
        icon: Icons.male_outlined,
        label: _t(context, AppKeys.categoryMen),
      ),
      _CategoryItem(
        icon: Icons.child_care_outlined,
        label: _t(context, AppKeys.categoryChild),
      ),
      _CategoryItem(
        icon: Icons.medical_services_outlined,
        label: _t(context, AppKeys.categoryDental),
      ),
      _CategoryItem(
        icon: Icons.spa_outlined,
        label: _t(context, AppKeys.categorySkin),
      ),
      _CategoryItem(
        icon: Icons.nature_outlined,
        label: _t(context, AppKeys.categoryHerbs),
      ),
      _CategoryItem(
        icon: Icons.broken_image_outlined,
        label: _t(context, AppKeys.categoryWounds),
      ),
    ];

    final pharmacies = <_PharmacyItem>[
      _PharmacyItem(
        title: _t(context, AppKeys.pharmacy1Title),
        subtitle: _t(context, AppKeys.pharmacy1Subtitle),
        rating: '4.9',
      ),
      _PharmacyItem(
        title: _t(context, AppKeys.pharmacy2Title),
        subtitle: _t(context, AppKeys.pharmacy2Subtitle),
        rating: '4.9',
      ),
      _PharmacyItem(
        title: _t(context, AppKeys.pharmacy3Title),
        subtitle: _t(context, AppKeys.pharmacy3Subtitle),
        rating: '4.9',
      ),
    ];

    final bestSellers = [
      _ProductItem(
        id: 'best_1',
        title: _t(context, AppKeys.bestSeller1Title),
        price: '58.50',
        oldPrice: '64.99',
        discount: '10%',
      ),
      _ProductItem(
        id: 'best_2',
        title: _t(context, AppKeys.bestSeller2Title),
        price: '39.90',
        oldPrice: '49.90',
        discount: '20%',
      ),
    ];

    return Directionality(
      textDirection: direction,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          centerTitle: true,
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: theme.scaffoldBackgroundColor,
          surfaceTintColor: Colors.transparent,
          title: Text(
            _t(context, AppKeys.appName),
            style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: colorScheme.onSurface,
            ),
          ),
          leadingWidth: 56,
          leading: IconButton(
            onPressed: _showSwitchDialog,
            icon: Icon(Icons.swap_horiz_rounded, color: colorScheme.onSurface),
          ),
          actions: [
            StreamBuilder<int>(
              stream: FirestoreService.totalUnreadCountStream(
                AuthService.currentUser?.uid ?? '',
                false,
              ),
              builder: (context, snapshot) {
                final count = snapshot.data ?? 0;
                return Badge(
                  label: Text('$count'),
                  isLabelVisible: count > 0,
                  backgroundColor: Colors.red,
                  child: IconButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              const ChatListScreen(isPharmacy: false),
                        ),
                      );
                    },
                    icon: Icon(
                      Icons.chat_bubble_outline_rounded,
                      color: colorScheme.onSurface,
                    ),
                  ),
                );
              },
            ),
            IconButton(
              onPressed: () {},
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    Icons.notifications_none_rounded,
                    color: colorScheme.onSurface,
                  ),
                  Positioned(
                    right: -1,
                    top: -1,
                    child: Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: colorScheme.error,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () {
                Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => const CartScreen()));
              },
              icon: Consumer<CartProvider>(
                builder: (context, cart, _) {
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Icon(
                        Icons.shopping_cart_outlined,
                        color: colorScheme.onSurface,
                      ),
                      if (cart.itemCount > 0)
                        Positioned(
                          right: -1,
                          top: -1,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: colorScheme.error,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: colorScheme.surface,
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SearchField(
                  hint: _t(context, AppKeys.searchHint),
                  fillColor: colorScheme.surfaceContainerHighest,
                  iconColor: colorScheme.onSurfaceVariant,
                  textColor: colorScheme.onSurface,
                  borderColor: colorScheme.outlineVariant,
                ),

                const SizedBox(height: 14),
                _BannerCarousel(
                  controller: _pageController,
                  banners: bannerItems,
                  currentIndex: _currentBanner,
                  isArabic: _isArabic,
                  colorScheme: colorScheme,
                  onPageChanged: (value) {
                    setState(() => _currentBanner = value);
                  },
                ),
                const SizedBox(height: 10),
                _Dots(
                  currentIndex: _currentBanner,
                  count: bannerItems.length,
                  activeColor: colorScheme.primary,
                  inactiveColor: colorScheme.outlineVariant,
                ),
                const SizedBox(height: 24),
                _SectionHeader(
                  title: _t(context, AppKeys.topPharmaciesTitle),
                  actionText: _t(context, AppKeys.viewAll),
                  titleColor: colorScheme.onSurface,
                  actionColor: colorScheme.primary,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PharmaciesScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                ...pharmacies.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _PharmacyCard(
                      title: item.title,
                      subtitle: item.subtitle,
                      rating: item.rating,
                      colorScheme: colorScheme,
                      isDark: isDark,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _SectionHeader(
                  title: _t(context, AppKeys.categories),
                  actionText: _t(context, AppKeys.viewAll),
                  titleColor: colorScheme.onSurface,
                  actionColor: colorScheme.primary,
                  onTap: () {},
                ),
                const SizedBox(height: 12),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: categories.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 10,
                    childAspectRatio: 0.9,
                  ),
                  itemBuilder: (context, index) {
                    final item = categories[index];
                    return _CategoryCircle(
                      icon: item.icon,
                      label: item.label,
                      colorScheme: colorScheme,
                    );
                  },
                ),
                const SizedBox(height: 24),
                _SectionHeader(
                  title: _t(context, AppKeys.brands),
                  actionText: _t(context, AppKeys.viewAllBrands),
                  titleColor: colorScheme.onSurface,
                  actionColor: colorScheme.primary,
                  onTap: () {},
                ),
                const SizedBox(height: 12),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: 8,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.0,
                  ),
                  itemBuilder: (context, index) {
                    const brands = [
                      'VICKS',
                      'Pampers',
                      'Pfizer',
                      'L\'ORÉAL',
                      'NIVEA',
                      'GARNIER',
                      'sanofi',
                      'Dove',
                    ];

                    return _BrandBox(
                      label: brands[index],
                      colorScheme: colorScheme,
                    );
                  },
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: colorScheme.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () {},
                    child: Text(
                      _t(context, AppKeys.viewAllBrands),
                      style: TextStyle(
                        color: colorScheme.primary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _SectionHeader(
                  title: _t(context, AppKeys.bestSellers),
                  actionText: _t(context, AppKeys.seeAll),
                  titleColor: colorScheme.onSurface,
                  actionColor: colorScheme.primary,
                  onTap: () {},
                ),
                const SizedBox(height: 12),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: bestSellers.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.74,
                  ),
                  itemBuilder: (context, index) {
                    final item = bestSellers[index];
                    return _ProductCard(
                      title: item.title,
                      price: item.price,
                      oldPrice: item.oldPrice,
                      discount: item.discount,
                      colorScheme: colorScheme,
                      onAddToCart: () => _addToCart(item),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.hint,
    required this.fillColor,
    required this.iconColor,
    required this.textColor,
    required this.borderColor,
  });

  final String hint;
  final Color fillColor;
  final Color iconColor;
  final Color textColor;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: fillColor,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: borderColor),
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: iconColor),
          prefixIcon: Icon(Icons.search_rounded, color: iconColor),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
        ),
        style: TextStyle(color: textColor),
      ),
    );
  }
}

class _BannerCarousel extends StatelessWidget {
  const _BannerCarousel({
    required this.controller,
    required this.banners,
    required this.currentIndex,
    required this.isArabic,
    required this.colorScheme,
    required this.onPageChanged,
  });

  final PageController controller;
  final List<_BannerItem> banners;
  final int currentIndex;
  final bool isArabic;
  final ColorScheme colorScheme;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 175,
      child: PageView.builder(
        controller: controller,
        itemCount: banners.length,
        onPageChanged: onPageChanged,
        itemBuilder: (context, index) {
          final item = banners[index];

          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: LinearGradient(
                colors: [colorScheme.primary, colorScheme.secondary],
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Opacity(
                      opacity: 0.15,
                      child: CustomPaint(
                        painter: _PromoPainter(
                          baseColor: colorScheme.onPrimary,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Align(
                            alignment: isArabic
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: const _GiftPattern(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: isArabic
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  item.title,
                                  textAlign: TextAlign.end,
                                  style: TextStyle(
                                    color: colorScheme.onPrimary,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    height: 1.15,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  item.subtitle,
                                  textAlign: TextAlign.end,
                                  style: TextStyle(
                                    color: colorScheme.onPrimary.withOpacity(
                                      0.95,
                                    ),
                                    fontSize: 12,
                                    height: 1.3,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    minimumSize: Size.zero,
                                    backgroundColor: colorScheme.onPrimary,
                                    foregroundColor: colorScheme.primary,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 10,
                                    ),
                                  ),
                                  onPressed: () {},
                                  child: Text(
                                    AppTexts.tr(context, AppKeys.shopNow),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({
    required this.currentIndex,
    required this.count,
    required this.activeColor,
    required this.inactiveColor,
  });

  final int currentIndex;
  final int count;
  final Color activeColor;
  final Color inactiveColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final active = index == currentIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: active ? 10 : 8,
          height: active ? 10 : 8,
          decoration: BoxDecoration(
            color: active ? activeColor : inactiveColor,
            shape: BoxShape.circle,
          ),
        );
      }),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.actionText,
    required this.titleColor,
    required this.actionColor,
    required this.onTap,
  });

  final String title;
  final String actionText;
  final Color titleColor;
  final Color actionColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        TextButton(
          onPressed: onTap,
          child: Text(
            actionText,
            style: TextStyle(color: actionColor, fontWeight: FontWeight.w700),
          ),
        ),
        const Spacer(),
        Text(
          title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: titleColor,
          ),
        ),
      ],
    );
  }
}

class _PharmacyCard extends StatelessWidget {
  const _PharmacyCard({
    required this.title,
    required this.subtitle,
    required this.rating,
    required this.colorScheme,
    required this.isDark,
  });

  final String title;
  final String subtitle;
  final String rating;
  final ColorScheme colorScheme;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final cardColor = colorScheme.surface;
    final borderColor = colorScheme.outlineVariant;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.12 : 0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 74,
            height: 74,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: LinearGradient(
                colors: [colorScheme.primary, colorScheme.secondary],
              ),
            ),
            child: Icon(
              Icons.local_pharmacy,
              color: colorScheme.onPrimary,
              size: 36,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      rating,
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.star, color: colorScheme.primary, size: 18),
                    Icon(Icons.star, color: colorScheme.primary, size: 18),
                    Icon(Icons.star, color: colorScheme.primary, size: 18),
                    Icon(Icons.star, color: colorScheme.primary, size: 18),
                    Icon(Icons.star, color: colorScheme.primary, size: 18),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryCircle extends StatelessWidget {
  const _CategoryCircle({
    required this.icon,
    required this.label,
    required this.colorScheme,
  });

  final IconData icon;
  final String label;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: colorScheme.primary.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 30, color: colorScheme.primary),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: colorScheme.onSurface),
        ),
      ],
    );
  }
}

class _BrandBox extends StatelessWidget {
  const _BrandBox({required this.label, required this.colorScheme});

  final String label;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: label == 'sanofi' ? 14 : 15,
          fontWeight: FontWeight.w700,
          color: colorScheme.onSurface,
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.title,
    required this.price,
    required this.oldPrice,
    required this.discount,
    required this.colorScheme,
    required this.onAddToCart,
  });

  final String title;
  final String price;
  final String oldPrice;
  final String discount;
  final ColorScheme colorScheme;
  final VoidCallback onAddToCart;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Stack(
            children: [
              Container(
                height: 145,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    colors: [
                      colorScheme.primary.withOpacity(0.14),
                      colorScheme.secondary.withOpacity(0.08),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.face_retouching_natural,
                      size: 54,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 64,
                      height: 8,
                      decoration: BoxDecoration(
                        color: colorScheme.secondary,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.secondary,
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(12),
                      bottomLeft: Radius.circular(12),
                    ),
                  ),
                  child: Text(
                    '$discount',
                    style: TextStyle(
                      color: colorScheme.onSecondary,
                      fontSize: 10,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w600,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$price ₪',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '$oldPrice ₪',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              decoration: TextDecoration.lineThrough,
              fontSize: 12,
            ),
          ),
          const Spacer(),
          SizedBox(
            height: 42,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              onPressed: onAddToCart,
              child: Text(
                AppTexts.tr(context, AppKeys.addToCart),
                style: TextStyle(
                  color: colorScheme.onPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BannerItem {
  final String title;
  final String subtitle;

  const _BannerItem({required this.title, required this.subtitle});
}

class _CategoryItem {
  final IconData icon;
  final String label;

  const _CategoryItem({required this.icon, required this.label});
}

class _PharmacyItem {
  final String title;
  final String subtitle;
  final String rating;

  const _PharmacyItem({
    required this.title,
    required this.subtitle,
    required this.rating,
  });
}

class _ProductItem {
  final String id;
  final String title;
  final String price;
  final String oldPrice;
  final String discount;

  const _ProductItem({
    required this.id,
    required this.title,
    required this.price,
    required this.oldPrice,
    required this.discount,
  });
}

class _PromoPainter extends CustomPainter {
  _PromoPainter({required this.baseColor});

  final Color baseColor;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = baseColor.withOpacity(0.12);
    canvas.drawCircle(Offset(size.width * 0.18, size.height * 0.2), 24, paint);
    canvas.drawCircle(Offset(size.width * 0.8, size.height * 0.2), 18, paint);
    canvas.drawCircle(Offset(size.width * 0.65, size.height * 0.75), 16, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _GiftPattern extends StatelessWidget {
  const _GiftPattern();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 240,
      height: 140,
      child: Stack(
        children: [
          Positioned(left: 12, top: 6, child: _GiftCard(rotate: -0.55)),
          Positioned(right: 18, top: 0, child: _GiftCard(rotate: 0.45)),
          Positioned(left: 44, bottom: 4, child: _GiftCard(rotate: -0.2)),
          Positioned(right: 8, bottom: 10, child: _GiftCard(rotate: 0.25)),
        ],
      ),
    );
  }
}

class _GiftCard extends StatelessWidget {
  const _GiftCard({required this.rotate});

  final double rotate;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: rotate,
      child: Container(
        width: 56,
        height: 76,
        decoration: BoxDecoration(
          color: Colors.redAccent,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}
