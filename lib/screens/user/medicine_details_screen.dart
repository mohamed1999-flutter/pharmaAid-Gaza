import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/models/pharmacy_models.dart';
import '../../core/models/user_models.dart';
import '../../core/providers/cart_provider.dart';
import '../../core/service/auth_service.dart';
import '../../core/service/firestore_service.dart';

enum _AccessState { loading, customer, pharmacy, signedOut, error }

class MedicineDetailsScreen extends StatefulWidget {
  final MedicineModel medicine;
  final String pharmacyId;
  final String pharmacyName;
  final String? pharmacyImageUrl;

  const MedicineDetailsScreen({
    super.key,
    required this.medicine,
    required this.pharmacyId,
    required this.pharmacyName,
    this.pharmacyImageUrl,
  });

  @override
  State<MedicineDetailsScreen> createState() => _MedicineDetailsScreenState();
}

class _MedicineDetailsScreenState extends State<MedicineDetailsScreen> {
  int _quantity = 1;
  late Future<_AccessState> _accessFuture;

  bool get _isArabic => Localizations.localeOf(context).languageCode == 'ar';

  @override
  void initState() {
    super.initState();
    _accessFuture = _resolveAccess();
  }

  Future<_AccessState> _resolveAccess() async {
    final user = AuthService.currentUser;
    if (user == null) return _AccessState.signedOut;

    try {
      final snapshot = await FirestoreService.getUserProfile(user.uid);

      if (!snapshot.exists) {
        return _AccessState.signedOut;
      }

      final data = snapshot.data() ?? {};
      final role = (data['role'] ?? 'user').toString().trim().toLowerCase();

      if (role == 'pharmacy') {
        return _AccessState.pharmacy;
      }

      return _AccessState.customer;
    } catch (_) {
      return _AccessState.error;
    }
  }

  Future<bool> _ensureCustomerAccess(BuildContext context) async {
    final result = await _resolveAccess();

    if (!mounted) return false;

    if (result == _AccessState.customer) {
      return true;
    }

    final cs = Theme.of(context).colorScheme;

    String message;
    if (result == _AccessState.pharmacy) {
      message = _isArabic
          ? 'هذا الحساب حساب صيدلية، ولا يمكن إضافة منتجات إلى السلة.'
          : 'This is a pharmacy account. Please use a customer account to add items to cart.';
    } else if (result == _AccessState.signedOut) {
      message = _isArabic
          ? 'يجب تسجيل الدخول كـ مستخدم أولًا.'
          : 'Please sign in as a customer first.';
    } else {
      message = _isArabic
          ? 'تعذر التحقق من نوع الحساب.'
          : 'Could not verify account type.';
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: cs.error,
        behavior: SnackBarBehavior.floating,
      ),
    );

    return false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final direction = _isArabic ? TextDirection.rtl : TextDirection.ltr;

    final name = _isArabic ? widget.medicine.nameAr : widget.medicine.nameEn;
    final description = _isArabic
        ? widget.medicine.descriptionAr
        : widget.medicine.descriptionEn;

    return Directionality(
      textDirection: direction,
      child: FutureBuilder<_AccessState>(
        future: _accessFuture,
        builder: (context, accessSnapshot) {
          final access = accessSnapshot.data ?? _AccessState.loading;
          final canAddToCart =
              access == _AccessState.customer && widget.medicine.stock > 0;

          return Scaffold(
            backgroundColor: theme.scaffoldBackgroundColor,
            appBar: AppBar(
              centerTitle: true,
              elevation: 0,
              scrolledUnderElevation: 0,
              backgroundColor: theme.scaffoldBackgroundColor,
              surfaceTintColor: Colors.transparent,
              title: Text(
                _isArabic ? 'تفاصيل الدواء' : 'Medicine Details',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: colorScheme.onSurface,
                ),
              ),
              leading: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
              ),
            ),
            body: SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: double.infinity,
                            height: 250,
                            decoration: BoxDecoration(
                              color: colorScheme.primary.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: widget.medicine.imageUrl != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(20),
                                    child: Image.network(
                                      widget.medicine.imageUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                            return Center(
                                              child: Icon(
                                                Icons.medication,
                                                color: colorScheme.primary
                                                    .withOpacity(0.5),
                                                size: 80,
                                              ),
                                            );
                                          },
                                    ),
                                  )
                                : Center(
                                    child: Icon(
                                      Icons.medication,
                                      color: colorScheme.primary.withOpacity(
                                        0.5,
                                      ),
                                      size: 80,
                                    ),
                                  ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            name,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _InfoBadge(
                                icon: Icons.science_outlined,
                                label: widget.medicine.form,
                                colorScheme: colorScheme,
                              ),
                              const SizedBox(width: 8),
                              _InfoBadge(
                                icon: Icons.medication_liquid_outlined,
                                label: widget.medicine.dosage,
                                colorScheme: colorScheme,
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${widget.medicine.price.toStringAsFixed(2)} ₪',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  color: colorScheme.primary,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: widget.medicine.stock > 0
                                      ? colorScheme.primary.withOpacity(0.1)
                                      : colorScheme.error.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  widget.medicine.stock > 0
                                      ? '${_isArabic ? 'متوفر' : 'In Stock'}: ${widget.medicine.stock}'
                                      : (_isArabic
                                            ? 'غير متوفر'
                                            : 'Out of Stock'),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: widget.medicine.stock > 0
                                        ? colorScheme.primary
                                        : colorScheme.error,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Text(
                            _isArabic ? 'الوصف' : 'Description',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            description,
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.5,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 20),
                          if (widget.medicine.composition.isNotEmpty) ...[
                            Text(
                              _isArabic ? 'المكونات' : 'Composition',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              widget.medicine.composition,
                              style: TextStyle(
                                fontSize: 14,
                                height: 1.5,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: colorScheme.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: colorScheme.outlineVariant,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: colorScheme.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.local_pharmacy,
                                    color: colorScheme.primary,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _isArabic ? 'الصيدلية' : 'Pharmacy',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        widget.pharmacyName,
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: colorScheme.onSurface,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 20,
                          offset: const Offset(0, -4),
                        ),
                      ],
                    ),
                    child: SafeArea(
                      top: false,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (access == _AccessState.pharmacy) ...[
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: colorScheme.error.withOpacity(0.10),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: colorScheme.error.withOpacity(0.25),
                                ),
                              ),
                              child: Text(
                                _isArabic
                                    ? 'لا يمكن للصيدلية الإضافة إلى السلة. سجّل دخول كـ مستخدم أولًا.'
                                    : 'Pharmacy accounts cannot add to cart. Sign in as a customer first.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: colorScheme.error,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ] else if (access == _AccessState.signedOut) ...[
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: colorScheme.primary.withOpacity(0.10),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: colorScheme.primary.withOpacity(0.25),
                                ),
                              ),
                              child: Text(
                                _isArabic
                                    ? 'يجب تسجيل الدخول كـ مستخدم لإضافة المنتج إلى السلة.'
                                    : 'You must sign in as a customer to add this item to cart.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                          Row(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: colorScheme.outlineVariant,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    IconButton(
                                      onPressed: canAddToCart && _quantity > 1
                                          ? () {
                                              setState(() {
                                                _quantity--;
                                              });
                                            }
                                          : null,
                                      icon: const Icon(Icons.remove),
                                      iconSize: 20,
                                      color: colorScheme.onSurface,
                                    ),
                                    SizedBox(
                                      width: 40,
                                      child: Text(
                                        '$_quantity',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                          color: colorScheme.onSurface,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      onPressed:
                                          canAddToCart &&
                                              _quantity < widget.medicine.stock
                                          ? () {
                                              setState(() {
                                                _quantity++;
                                              });
                                            }
                                          : null,
                                      icon: const Icon(Icons.add),
                                      iconSize: 20,
                                      color: colorScheme.onSurface,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: canAddToCart
                                        ? colorScheme.primary
                                        : colorScheme.outlineVariant,
                                    foregroundColor: canAddToCart
                                        ? colorScheme.onPrimary
                                        : colorScheme.onSurfaceVariant,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  onPressed: canAddToCart
                                      ? () => _addToCart(context)
                                      : () async {
                                          await _ensureCustomerAccess(context);
                                        },
                                  icon: const Icon(
                                    Icons.add_shopping_cart_rounded,
                                  ),
                                  label: Text(
                                    _isArabic ? 'أضف للسلة' : 'Add to Cart',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
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

  Future<void> _addToCart(BuildContext context) async {
    final ok = await _ensureCustomerAccess(context);
    if (!ok) return;

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final cartItem = CartItem(
      medicineId: widget.medicine.id,
      name: _isArabic ? widget.medicine.nameAr : widget.medicine.nameEn,
      imageUrl: widget.medicine.imageUrl,
      price: widget.medicine.price,
      quantity: _quantity,
      pharmacyId: widget.pharmacyId,
      pharmacyName: widget.pharmacyName,
    );

    try {
      final cartProvider = context.read<CartProvider>();
      await cartProvider.addItem(cartItem);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isArabic ? 'تمت الإضافة للسلة' : 'Added to cart',
              style: TextStyle(color: colorScheme.onPrimary),
            ),
            backgroundColor: colorScheme.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isArabic ? 'حدث خطأ' : 'Error occurred',
              style: TextStyle(color: colorScheme.onError),
            ),
            backgroundColor: colorScheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }
}

class _InfoBadge extends StatelessWidget {
  const _InfoBadge({
    required this.icon,
    required this.label,
    required this.colorScheme,
  });

  final IconData icon;
  final String label;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.primary.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: colorScheme.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}
