import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/localization/app_keys.dart';
import '../../core/localization/app_texts.dart';
import '../../core/models/user_models.dart';
import '../../core/providers/cart_provider.dart';
import '../../core/service/firestore_service.dart';
import '../user/cart_screen.dart';

class OffersScreen extends StatefulWidget {
  const OffersScreen({super.key});

  @override
  State<OffersScreen> createState() => _OffersScreenState();
}

class _OffersScreenState extends State<OffersScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  String _selectedCategory = 'all';

  final List<_BannerData> _banners = const [
    _BannerData(
      titleAr: 'احتفل بالموسم معنا!',
      titleEn: 'Celebrate The Season With Us!',
      subtitleAr: 'خصومات تصل إلى 75% على مستلزمات المنزل والديكور',
      subtitleEn: 'Get discounts up to 75% for furniture & decoration',
    ),
    _BannerData(
      titleAr: 'تخفيضات حصرية',
      titleEn: 'Exclusive discounts',
      subtitleAr: 'أفضل العروض على منتجات العناية والمستلزمات',
      subtitleEn: 'Best deals on care products and essentials',
    ),
    _BannerData(
      titleAr: 'عروض اليوم',
      titleEn: 'Today’s offers',
      subtitleAr: 'وفر أكثر على المنتجات الأكثر طلبًا',
      subtitleEn: 'Save more on the most requested products',
    ),
  ];

  final List<_CategoryData> _categories = const [
    _CategoryData(key: 'all', ar: 'عروض مميزة', en: 'Featured offers'),
    _CategoryData(key: 'firstAid', ar: 'اسعافات أولية', en: 'First aid'),
    _CategoryData(key: 'supplies', ar: 'المستلزمات', en: 'Supplies'),
    _CategoryData(key: 'babyCare', ar: 'عناية بالرضع', en: 'Baby care'),
    _CategoryData(key: 'personalCare', ar: 'عناية شخصية', en: 'Personal care'),
  ];

  final List<_ProductData> _products = const [
    _ProductData(
      id: 'off_1',
      categoryKey: 'firstAid',
      titleAr: 'شاش طبي معقم',
      titleEn: 'Sterile medical gauze',
      subtitleAr: 'عبوة 10 قطع',
      subtitleEn: 'Pack of 10 pieces',
      price: '18.00',
      discount: 'خصم %12',
      accent: Color(0xFF2B73FF),
      warm: false,
    ),
    _ProductData(
      id: 'off_2',
      categoryKey: 'firstAid',
      titleAr: 'لاصق جروح',
      titleEn: 'Wound plaster',
      subtitleAr: 'مقاس صغير ومناسب للأطفال',
      subtitleEn: 'Small size for daily use',
      price: '12.50',
      discount: 'خصم %8',
      accent: Color(0xFFEBC23F),
      warm: true,
    ),
    _ProductData(
      id: 'off_3',
      categoryKey: 'firstAid',
      titleAr: 'مطهر طبي',
      titleEn: 'Medical antiseptic',
      subtitleAr: 'عبوة آمنة للاستعمال اليومي',
      subtitleEn: 'Safe daily-use bottle',
      price: '24.00',
      discount: 'خصم %15',
      accent: Color(0xFF15B8A6),
      warm: false,
    ),
    _ProductData(
      id: 'off_4',
      categoryKey: 'supplies',
      titleAr: 'قفازات طبية',
      titleEn: 'Medical gloves',
      subtitleAr: 'مقاس متوسط - 50 قطعة',
      subtitleEn: 'Medium size - 50 pcs',
      price: '35.00',
      discount: 'خصم %10',
      accent: Color(0xFF7A5CFF),
      warm: false,
    ),
    _ProductData(
      id: 'off_5',
      categoryKey: 'supplies',
      titleAr: 'كمامة واقية',
      titleEn: 'Protective mask',
      subtitleAr: 'عبوة اقتصادية',
      subtitleEn: 'Economical pack',
      price: '16.50',
      discount: 'خصم %7',
      accent: Color(0xFFFF7A59),
      warm: true,
    ),
    _ProductData(
      id: 'off_6',
      categoryKey: 'supplies',
      titleAr: 'مناديل معقمة',
      titleEn: 'Antiseptic wipes',
      subtitleAr: '30 قطعة مبللة',
      subtitleEn: '30 wet wipes',
      price: '22.00',
      discount: 'خصم %9',
      accent: Color(0xFF00A7B5),
      warm: false,
    ),
    _ProductData(
      id: 'off_7',
      categoryKey: 'babyCare',
      titleAr: 'كريم أطفال',
      titleEn: 'Baby cream',
      subtitleAr: 'لطيف على البشرة',
      subtitleEn: 'Gentle on skin',
      price: '39.00',
      discount: 'خصم %14',
      accent: Color(0xFFFFB84D),
      warm: true,
    ),
    _ProductData(
      id: 'off_8',
      categoryKey: 'babyCare',
      titleAr: 'شامبو أطفال',
      titleEn: 'Baby shampoo',
      subtitleAr: 'بدون دموع',
      subtitleEn: 'Tear-free formula',
      price: '41.50',
      discount: 'خصم %11',
      accent: Color(0xFF4DC3FF),
      warm: false,
    ),
    _ProductData(
      id: 'off_9',
      categoryKey: 'personalCare',
      titleAr: 'غسول يدين',
      titleEn: 'Hand wash',
      subtitleAr: 'رائحة منعشة',
      subtitleEn: 'Fresh fragrance',
      price: '27.00',
      discount: 'خصم %13',
      accent: Color(0xFF18C97E),
      warm: false,
    ),
    _ProductData(
      id: 'off_10',
      categoryKey: 'personalCare',
      titleAr: 'مرطب بشرة',
      titleEn: 'Skin moisturizer',
      subtitleAr: 'ترطيب يومي خفيف',
      subtitleEn: 'Daily light moisturizer',
      price: '48.00',
      discount: 'خصم %16',
      accent: Color(0xFFCF3CFF),
      warm: true,
    ),
    _ProductData(
      id: 'off_11',
      categoryKey: 'personalCare',
      titleAr: 'مزيل عرق',
      titleEn: 'Deodorant',
      subtitleAr: 'حماية تدوم طويلاً',
      subtitleEn: 'Long lasting protection',
      price: '33.00',
      discount: 'خصم %9',
      accent: Color(0xFF1F45D6),
      warm: false,
    ),
    _ProductData(
      id: 'off_12',
      categoryKey: 'supplies',
      titleAr: 'شريط لاصق طبي',
      titleEn: 'Medical adhesive tape',
      subtitleAr: 'قوي وسهل الاستخدام',
      subtitleEn: 'Strong and easy to use',
      price: '14.50',
      discount: 'خصم %6',
      accent: Color(0xFFFF5A5F),
      warm: true,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  List<_ProductData> get _filteredProducts {
    if (_selectedCategory == 'all') {
      return _products;
    }
    return _products
        .where((product) => product.categoryKey == _selectedCategory)
        .toList();
  }

  Future<void> _addToCart(_ProductData item) async {
    final cart = context.read<CartProvider>();
    final code = Localizations.localeOf(context).languageCode;
    final isAr = code == 'ar';

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
          name: isAr ? item.titleAr : item.titleEn,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final code = Localizations.localeOf(context).languageCode;
    final isArabic = code == 'ar';

    final bg = Theme.of(context).scaffoldBackgroundColor;
    final surface = Theme.of(context).colorScheme.surface;
    final textColor = isDark ? Colors.white : const Color(0xFF151515);
    final subText = isDark ? Colors.white70 : const Color(0xFF666666);
    final border = isDark ? const Color(0xFF2A2F3A) : const Color(0xFFE7E7E7);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Center(
                  child: Text(
                    AppTexts.tr(context, AppKeys.appName),
                    style: TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                child: _BannerCarousel(
                  pageController: _pageController,
                  banners: _banners,
                  onPageChanged: (value) =>
                      setState(() => _currentPage = value),
                  isDark: isDark,
                  isArabic: isArabic,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_banners.length, (index) {
                    final active = _currentPage == index;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: active ? 9 : 7,
                      height: active ? 9 : 7,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: active
                            ? const Color(0xFF17D47A)
                            : (isDark
                                  ? Colors.white30
                                  : const Color(0xFFD5D5D5)),
                      ),
                    );
                  }),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
                child: SizedBox(
                  height: 42,
                  child: ListView.separated(
                    reverse: isArabic,
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (context, index) {
                      final item = _categories[index];
                      final selected = _selectedCategory == item.key;

                      return InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          setState(() {
                            _selectedCategory = item.key;
                          });
                        },
                        child: _CategoryChip(
                          label: isArabic ? item.ar : item.en,
                          selected: selected,
                          textColor: textColor,
                          borderColor: border,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              sliver: _filteredProducts.isEmpty
                  ? SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 40),
                        child: Center(
                          child: Text(
                            isArabic
                                ? 'لا توجد منتجات هنا'
                                : 'No products found',
                            style: TextStyle(
                              color: subText,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    )
                  : SliverGrid(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final item = _filteredProducts[index];
                        return _OfferCard(
                          product: item,
                          isArabic: isArabic,
                          isDark: isDark,
                          textColor: textColor,
                          subText: subText,
                          borderColor: border,
                          surfaceColor: surface,
                          onAddToCart: () => _addToCart(item),
                        );
                      }, childCount: _filteredProducts.length),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 0.67,
                          ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BannerCarousel extends StatelessWidget {
  const _BannerCarousel({
    required this.pageController,
    required this.banners,
    required this.onPageChanged,
    required this.isDark,
    required this.isArabic,
  });

  final PageController pageController;
  final List<_BannerData> banners;
  final ValueChanged<int> onPageChanged;
  final bool isDark;
  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 175,
      child: PageView.builder(
        controller: pageController,
        onPageChanged: onPageChanged,
        itemCount: banners.length,
        itemBuilder: (context, index) {
          final item = banners[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF0F6B5A),
                  Color(0xFF176F5D),
                  Color(0xFF1A5B4C),
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.20 : 0.08),
                  blurRadius: 14,
                  offset: const Offset(0, 7),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: Stack(
                children: [
                  Positioned(
                    right: -18,
                    top: 0,
                    bottom: 0,
                    child: Opacity(
                      opacity: 0.22,
                      child: _SeasonTree(isArabic: isArabic),
                    ),
                  ),
                  Positioned(
                    left: -30,
                    bottom: -18,
                    child: Opacity(
                      opacity: 0.10,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 22, 18, 18),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 6,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isArabic ? item.titleAr : item.titleEn,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 23,
                                  fontWeight: FontWeight.w800,
                                  height: 1.08,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                isArabic ? item.subtitleAr : item.subtitleEn,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w400,
                                  height: 1.3,
                                ),
                              ),
                              const SizedBox(height: 14),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(22),
                                ),
                                child: Text(
                                  AppTexts.tr(context, AppKeys.shopNow),
                                  style: const TextStyle(
                                    color: Color(0xFF184B43),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        Expanded(
                          flex: 4,
                          child: Align(
                            alignment: Alignment.center,
                            child: _GiftScene(index: index),
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

class _GiftScene extends StatelessWidget {
  const _GiftScene({required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      height: 120,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: 10,
            right: 12,
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Color(0xFFFF5A5F),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            top: 22,
            left: 20,
            child: Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: Color(0xFFFFD166),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: 20,
            left: 10,
            child: Container(
              width: 18,
              height: 18,
              decoration: const BoxDecoration(
                color: Color(0xFFF94144),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: 6,
            right: 8,
            child: Container(
              width: 20,
              height: 20,
              decoration: const BoxDecoration(
                color: Color(0xFFFF8FAB),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Container(
            width: 90,
            height: 95,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(0.20)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: index.isEven
                          ? [const Color(0xFF9EF7C7), const Color(0xFF2EAA7B)]
                          : [const Color(0xFFF7E7A9), const Color(0xFFE0B44C)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 50,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.55),
                    borderRadius: BorderRadius.circular(99),
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

class _SeasonTree extends StatelessWidget {
  const _SeasonTree({required this.isArabic});

  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      height: 190,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: const LinearGradient(
          colors: [Color(0xFF125B4F), Color(0xFF1D6C59)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: 12,
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.green.shade900.withOpacity(0.3),
              ),
            ),
          ),
          Positioned(
            top: 28,
            child: Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.green.shade700.withOpacity(0.35),
              ),
            ),
          ),
          Positioned(
            top: 44,
            child: Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.green.shade500.withOpacity(0.4),
              ),
            ),
          ),
          Positioned(
            bottom: 28,
            child: Container(
              width: 26,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFF7A4E2A).withOpacity(0.7),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.textColor,
    required this.borderColor,
  });

  final String label;
  final bool selected;
  final Color textColor;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFFE8FFF3) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: selected ? const Color(0xFF17D47A) : borderColor,
          width: 1,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: TextStyle(
          color: selected ? const Color(0xFF0A8C4C) : textColor,
          fontSize: 13.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _OfferCard extends StatelessWidget {
  const _OfferCard({
    required this.product,
    required this.isArabic,
    required this.isDark,
    required this.textColor,
    required this.subText,
    required this.borderColor,
    required this.surfaceColor,
    required this.onAddToCart,
  });

  final _ProductData product;
  final bool isArabic;
  final bool isDark;
  final Color textColor;
  final Color subText;
  final Color borderColor;
  final Color surfaceColor;
  final VoidCallback onAddToCart;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.18 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFCF3CFF),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  product.discount,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Center(
                child: _ProductVisual(
                  accent: product.accent,
                  warm: product.warm,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isArabic ? product.titleAr : product.titleEn,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: textColor,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              isArabic ? product.subtitleAr : product.subtitleEn,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: subText,
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${product.price} ₪',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: textColor,
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 38,
              child: ElevatedButton(
                onPressed: onAddToCart,
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: const Color(0xFF16D37A),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  AppTexts.tr(context, AppKeys.addToCart),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductVisual extends StatelessWidget {
  const _ProductVisual({required this.accent, required this.warm});

  final Color accent;
  final bool warm;

  @override
  Widget build(BuildContext context) {
    final top = warm ? const Color(0xFFFFD8A8) : const Color(0xFFD8ECFF);
    final bottom = warm ? const Color(0xFFE5FFBA) : const Color(0xFFCBDEFF);

    return Container(
      width: 120,
      height: 135,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          colors: [top, bottom],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: 10,
            child: Container(
              width: 70,
              height: 14,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.52),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          Positioned(
            top: 30,
            child: Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accent.withOpacity(0.12),
              ),
            ),
          ),
          Positioned(
            bottom: 16,
            child: Container(
              width: 72,
              height: 46,
              decoration: BoxDecoration(
                color: accent,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: accent.withOpacity(0.35),
                    blurRadius: 14,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 46,
            child: Container(
              width: 60,
              height: 18,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.80),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          Positioned(
            top: 48,
            child: Container(
              width: 58,
              height: 46,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Colors.white.withOpacity(0.92),
              ),
              child: Center(
                child: Text(
                  'CREAM',
                  style: TextStyle(
                    color: accent,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BannerData {
  final String titleAr;
  final String titleEn;
  final String subtitleAr;
  final String subtitleEn;

  const _BannerData({
    required this.titleAr,
    required this.titleEn,
    required this.subtitleAr,
    required this.subtitleEn,
  });
}

class _CategoryData {
  final String key;
  final String ar;
  final String en;

  const _CategoryData({required this.key, required this.ar, required this.en});
}

class _ProductData {
  final String id;
  final String categoryKey;
  final String titleAr;
  final String titleEn;
  final String subtitleAr;
  final String subtitleEn;
  final String price;
  final String discount;
  final Color accent;
  final bool warm;

  const _ProductData({
    required this.id,
    required this.categoryKey,
    required this.titleAr,
    required this.titleEn,
    required this.subtitleAr,
    required this.subtitleEn,
    required this.price,
    required this.discount,
    required this.accent,
    required this.warm,
  });
}
