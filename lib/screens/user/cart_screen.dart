import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/models/user_models.dart';
import '../../core/providers/cart_provider.dart';
import 'checkout_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  bool get _isArabic => Localizations.localeOf(context).languageCode == 'ar';

  static const Color _primaryGreen = Color(0xFF10D17A);
  static const Color _borderColor = Color(0xFFEAEAEA);
  static const Color _mutedText = Color(0xFF8A8A8A);

  String _deliveryAddress = '780 شارع النصر';

  Future<void> _changeAddress() async {
    final selected = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => AddressSelectionScreen(
          currentAddress: _deliveryAddress,
          isArabic: _isArabic,
        ),
      ),
    );

    if (selected != null && mounted) {
      setState(() => _deliveryAddress = selected);
    }
  }

  Future<void> _openCheckoutForPharmacy(List<CartItem> pharmacyItems) async {
    if (pharmacyItems.isEmpty) return;

    final pharmacyId = pharmacyItems.first.pharmacyId;

    final success = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => CheckoutScreen(pharmacyId: pharmacyId)),
    );

    if (!mounted) return;

    if (success == true) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OrderSuccessScreen(isArabic: _isArabic),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          centerTitle: true,
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_forward_rounded, color: Colors.black),
          ),
          title: Text(
            _isArabic ? 'عربة التسوق' : 'Shopping Cart',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Colors.black,
            ),
          ),
        ),
        body: Consumer<CartProvider>(
          builder: (context, cartProvider, child) {
            if (cartProvider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (cartProvider.items.isEmpty) {
              return _EmptyCartView(isArabic: _isArabic);
            }

            final groupedItems = cartProvider.itemsByPharmacy.entries.toList();

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    _isArabic ? 'الطلبات' : 'Orders',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF4A4A4A),
                      height: 1.1,
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                ...groupedItems.map((entry) {
                  final pharmacyItems = entry.value;
                  final pharmacyName = pharmacyItems.first.pharmacyName;
                  final subtotal = pharmacyItems.fold<double>(
                    0,
                    (sum, item) => sum + (item.price * item.quantity),
                  );

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _PharmacySectionCard(
                      pharmacyName: pharmacyName,
                      items: pharmacyItems,
                      subtotal: subtotal,
                      onQuantityChange: (item, quantity) {
                        cartProvider.updateQuantity(item.medicineId, quantity);
                      },
                      onRemove: (item) {
                        cartProvider.removeItem(item.medicineId);
                      },
                      onOrderPressed: () =>
                          _openCheckoutForPharmacy(pharmacyItems),
                    ),
                  );
                }),

                const SizedBox(height: 8),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 8,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _PharmacySectionCard extends StatelessWidget {
  const _PharmacySectionCard({
    required this.pharmacyName,
    required this.items,
    required this.subtotal,
    required this.onQuantityChange,
    required this.onRemove,
    required this.onOrderPressed,
  });

  final String pharmacyName;
  final List<CartItem> items;
  final double subtotal;
  final void Function(CartItem item, int quantity) onQuantityChange;
  final void Function(CartItem item) onRemove;
  final VoidCallback onOrderPressed;

  static const Color _borderColor = Color(0xFFEAEAEA);
  static const Color _primaryGreen = Color(0xFF10D17A);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _borderColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: _primaryGreen.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.local_pharmacy_outlined,
                    color: _primaryGreen,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        pharmacyName,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF404040),
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'طلب مستقل لهذه الصيدلية',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF9A9A9A),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = items[index];
                return _CartItemCard(
                  item: item,
                  onQuantityChange: (quantity) =>
                      onQuantityChange(item, quantity),
                  onRemove: () => onRemove(item),
                );
              },
            ),
          ),

          const Divider(height: 1),

          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'الإجمالي',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF8A8A8A),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${subtotal.toStringAsFixed(1)} ₪',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF404040),
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryGreen,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    minimumSize: const Size(0, 44),
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: onOrderPressed,
                  child: const Text(
                    'اطلب من هذه الصيدلية',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
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

class _CartItemCard extends StatelessWidget {
  const _CartItemCard({
    required this.item,
    required this.onQuantityChange,
    required this.onRemove,
  });

  final CartItem item;
  final ValueChanged<int> onQuantityChange;
  final VoidCallback onRemove;

  static const Color _borderColor = Color(0xFFEAEAEA);
  static const Color _purpleBadge = Color(0xFFDB3ED4);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _borderColor, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: onRemove,
            child: const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Icon(
                Icons.delete_outline,
                size: 24,
                color: Color(0xFF2E2E2E),
              ),
            ),
          ),
          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  item.name,
                  textAlign: TextAlign.right,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.35,
                    color: Color(0xFF4A4A4A),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _QuantityControl(
                      quantity: item.quantity,
                      onAdd: () => onQuantityChange(item.quantity + 1),
                      onRemove: item.quantity > 1
                          ? () => onQuantityChange(item.quantity - 1)
                          : null,
                    ),
                    const Spacer(),
                    Text(
                      '${item.price.toStringAsFixed(2)} ₪',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF4A4A4A),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          _ProductImage(imageUrl: item.imageUrl),
        ],
      ),
    );
  }
}

class _ProductImage extends StatelessWidget {
  const _ProductImage({required this.imageUrl});

  final String? imageUrl;

  static const Color _purpleBadge = Color(0xFFDB3ED4);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 54,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 54,
            height: 74,
            decoration: BoxDecoration(
              color: const Color(0xFFF6F6F6),
              borderRadius: BorderRadius.circular(10),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: imageUrl != null && imageUrl!.isNotEmpty
                  ? Image.network(
                      imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.image_not_supported_outlined,
                        color: Colors.grey,
                      ),
                    )
                  : const Icon(Icons.image_outlined, color: Colors.grey),
            ),
          ),
          Positioned(
            bottom: -7,
            right: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: _purpleBadge,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'خصم %10',
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuantityControl extends StatelessWidget {
  const _QuantityControl({
    required this.quantity,
    required this.onAdd,
    required this.onRemove,
  });

  final int quantity;
  final VoidCallback onAdd;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: onAdd,
          child: Container(
            width: 22,
            height: 22,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.fromBorderSide(
                BorderSide(color: Color(0xFF12D27B), width: 1.5),
              ),
            ),
            child: const Icon(Icons.add, size: 14, color: Color(0xFF12D27B)),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          '$quantity',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Color(0xFF444444),
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: onRemove,
          child: Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: onRemove == null
                  ? const Color(0xFFF0F0F0)
                  : const Color(0xFFF1F1F1),
            ),
            child: const Icon(Icons.remove, size: 14, color: Color(0xFFC8C8C8)),
          ),
        ),
      ],
    );
  }
}

class _EmptyCartView extends StatelessWidget {
  const _EmptyCartView({required this.isArabic});

  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        isArabic ? 'السلة فارغة' : 'Your cart is empty',
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: Color(0xFF7A7A7A),
        ),
      ),
    );
  }
}

class OrderSuccessScreen extends StatelessWidget {
  const OrderSuccessScreen({super.key, required this.isArabic});

  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          centerTitle: true,
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_forward_rounded, color: Colors.black),
          ),
          title: Text(
            isArabic ? 'تم الطلب بنجاح' : 'Order completed',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Colors.black,
            ),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5C400),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: const Center(
                    child: Text(
                      '?',
                      style: TextStyle(
                        fontSize: 96,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        height: 1,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 34),
                Text(
                  isArabic
                      ? 'تم تنفيذ طلبك بنجاح'
                      : 'Your order has been placed successfully',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF404040),
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  isArabic
                      ? 'تم إنشاء الطلب الخاص بك بنجاح وسيتم توصيله إليك في أقرب وقت ممكن'
                      : 'Your order has been created successfully and will be delivered soon',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFFB5B5B5),
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10D17A),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pushNamed(context, '/orders');
                    },
                    child: Text(
                      isArabic ? 'ذهب الي قائمة الطلبات' : 'Go to orders list',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF10D17A),
                      side: const BorderSide(
                        color: Color(0xFF10D17A),
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      isArabic ? 'ارجع لل cart' : 'Back to cart',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AddressSelectionScreen extends StatelessWidget {
  AddressSelectionScreen({
    super.key,
    required this.currentAddress,
    required this.isArabic,
  });

  final String currentAddress;
  final bool isArabic;

  final List<String> _addresses = const [
    '780 شارع النصر',
    '15 شارع الجامعة',
    'مدينة نصر - مكرم عبيد',
    'المعادي - شارع 9',
  ];

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          centerTitle: true,
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_forward_rounded, color: Colors.black),
          ),
          title: Text(
            isArabic ? 'اختيار عنوان التوصيل' : 'Choose delivery address',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Colors.black,
            ),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ..._addresses.map(
              (address) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  onTap: () => Navigator.pop(context, address),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: address == currentAddress
                            ? const Color(0xFF10D17A)
                            : const Color(0xFFEAEAEA),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          address == currentAddress
                              ? Icons.radio_button_checked
                              : Icons.radio_button_off,
                          color: const Color(0xFF10D17A),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            address,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF404040),
                            ),
                          ),
                        ),
                      ],
                    ),
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
