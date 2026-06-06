import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/models/user_models.dart';
import '../../core/providers/cart_provider.dart';
import '../../core/service/auth_service.dart';
import '../../core/service/firestore_service.dart';
import 'user_shell_screen.dart';

enum DeliveryContactMethod { phone, whatsapp }

class CheckoutScreen extends StatefulWidget {
  final String pharmacyId;
  const CheckoutScreen({super.key, required this.pharmacyId});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  final _noteController = TextEditingController();

  bool _isProcessing = false;
  bool _cashOnDelivery = true;
  DeliveryContactMethod _deliveryContactMethod = DeliveryContactMethod.phone;

  bool get _isArabic => Localizations.localeOf(context).languageCode == 'ar';

  @override
  void dispose() {
    _addressController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  String _t(String ar, String en) => _isArabic ? ar : en;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final direction = _isArabic ? TextDirection.rtl : TextDirection.ltr;

    return Directionality(
      textDirection: direction,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          centerTitle: true,
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          title: Text(
            _t('تأكيد الشراء', 'Checkout'),
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: Colors.black,
            ),
          ),
          leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(
              _isArabic ? Icons.arrow_forward : Icons.arrow_back,
              color: Colors.black,
            ),
          ),
        ),
        body: Consumer<CartProvider>(
          builder: (context, cartProvider, child) {
            final pharmacyItems = cartProvider.getItemsForPharmacy(
              widget.pharmacyId,
            );

            if (pharmacyItems.isEmpty) {
              return Center(
                child: Text(
                  _t(
                    'السلة فارغة لهذه الصيدلية',
                    'Cart is empty for this pharmacy',
                  ),
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              );
            }

            final pharmacyId = widget.pharmacyId;
            final pharmacyName = pharmacyItems.first.pharmacyName;

            return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              future: FirestoreService.getPharmacyDetails(pharmacyId),
              builder: (context, snapshot) {
                String pharmacyAddress = '';
                if (snapshot.hasData && snapshot.data!.exists) {
                  final data = snapshot.data!.data()!;
                  pharmacyAddress =
                      (data['pharmacyAddress'] ?? data['address'] ?? '')
                          .toString();
                }

                final subtotal = cartProvider.getTotalForPharmacy(pharmacyId);
                const deliveryFee = 10.0;
                const discount = 0.0;
                final total = subtotal + deliveryFee - discount;

                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Address section
                        _SectionTitle(text: _t('العنوان', 'Address')),
                        const SizedBox(height: 8),
                        _AddressCard(
                          address: pharmacyAddress.isEmpty
                              ? _t('لا يوجد عنوان متاح', 'No address available')
                              : pharmacyAddress,
                        ),

                        const SizedBox(height: 18),

                        // Contact method
                        _SectionTitle(
                          text: _t('طريقة التواصل', 'Contact method'),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: _ChoiceButton(
                                text: _t('واتس اب', 'WhatsApp'),
                                selected:
                                    _deliveryContactMethod ==
                                    DeliveryContactMethod.whatsapp,
                                onTap: () {
                                  setState(() {
                                    _deliveryContactMethod =
                                        DeliveryContactMethod.whatsapp;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: _ChoiceButton(
                                text: _t('الهاتف', 'Phone'),
                                selected:
                                    _deliveryContactMethod ==
                                    DeliveryContactMethod.phone,
                                onTap: () {
                                  setState(() {
                                    _deliveryContactMethod =
                                        DeliveryContactMethod.phone;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 18),

                        // Payment method
                        _SectionTitle(
                          text: _t('طريقة الدفع', 'Payment method'),
                        ),
                        const SizedBox(height: 10),
                        _PaymentCard(
                          title: _t('الدفع عند الاستلام', 'Cash on delivery'),
                          selected: _cashOnDelivery,
                          onChanged: (value) {
                            setState(() => _cashOnDelivery = value ?? false);
                          },
                        ),

                        const SizedBox(height: 18),

                        // Address input
                        _SectionTitle(
                          text: _t('عنوان التوصيل', 'Delivery address'),
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _addressController,
                          maxLines: 3,
                          textAlign: _isArabic
                              ? TextAlign.right
                              : TextAlign.left,
                          decoration: InputDecoration(
                            hintText: _t(
                              'اكتب عنوانك بالتفصيل',
                              'Write your full address',
                            ),
                            hintStyle: TextStyle(color: Colors.grey.shade500),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: colorScheme.primary,
                                width: 1.3,
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return _t('مطلوب', 'Required');
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 18),

                        // Order summary
                        _SectionTitle(
                          text: _t('إجمالي الطلب', 'Order summary'),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: Colors.grey.shade200),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Column(
                            children: [
                              ...pharmacyItems.map((item) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          '${item.name} x${item.quantity}',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.grey.shade800,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        '${item.total.toStringAsFixed(1)} ${_t('شيكل', 'AED')}',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),

                              const Divider(height: 20),

                              _SummaryRow(
                                label: _t('اجمالي الطلب', 'Subtotal'),
                                value:
                                    '${subtotal.toStringAsFixed(1)} ${_t('شيكل', 'AED')}',
                              ),
                              const SizedBox(height: 8),
                              _SummaryRow(
                                label: _t('خدمة التوصيل', 'Delivery fee'),
                                value:
                                    '${deliveryFee.toStringAsFixed(1)} ${_t('شيكل', 'AED')}',
                              ),
                              const SizedBox(height: 8),
                              _SummaryRow(
                                label: _t('كود خصم', 'Discount code'),
                                value:
                                    '${discount.toStringAsFixed(1)} ${_t('شيكل', 'AED')}',
                              ),
                              const SizedBox(height: 8),
                              _SummaryRow(
                                label: _t('الإجمالي', 'Total'),
                                value:
                                    '${total.toStringAsFixed(1)} ${_t('شيكل', 'AED')}',
                                isTotal: true,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 18),

                        // Note
                        _SectionTitle(text: _t('ملاحظات', 'Notes')),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _noteController,
                          maxLines: 3,
                          textAlign: _isArabic
                              ? TextAlign.right
                              : TextAlign.left,
                          decoration: InputDecoration(
                            hintText: _t(
                              'أي ملاحظات إضافية...',
                              'Any extra notes...',
                            ),
                            hintStyle: TextStyle(color: Colors.grey.shade500),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: colorScheme.primary,
                                width: 1.3,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 22),

                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF12D47B),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            onPressed: _isProcessing ? null : _submitOrder,
                            child: _isProcessing
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : Text(
                                    _t('تأكيد الطلب', 'Confirm order'),
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
                );
              },
            );
          },
        ),
      ),
    );
  }

  Future<void> _submitOrder() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isProcessing = true;
    });

    final colorScheme = Theme.of(context).colorScheme;

    try {
      final user = AuthService.currentUser;
      if (user == null)
        throw Exception(_t('المستخدم غير مسجل الدخول', 'User not logged in'));

      final cartProvider = context.read<CartProvider>();
      final pharmacyItems = cartProvider.getItemsForPharmacy(widget.pharmacyId);
      final pharmacyId = widget.pharmacyId;
      final pharmacyName = pharmacyItems.first.pharmacyName;

      final pharmacySnapshot = await FirestoreService.getPharmacyDetails(
        pharmacyId,
      );
      final pharmacyAddress =
          (pharmacySnapshot.data()?['pharmacyAddress'] ??
                  pharmacySnapshot.data()?['address'] ??
                  '')
              .toString();

      final order = UserOrder(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: user.uid,
        pharmacyId: pharmacyId,
        pharmacyName: pharmacyName,
        pharmacyAddress: pharmacyAddress,
        items: pharmacyItems,
        total: cartProvider.getTotalForPharmacy(pharmacyId),
        status: 'pending',
        deliveryAddress: _addressController.text.trim(),
        customerPhone: '',
        customerNote: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
        createdAt: DateTime.now(),
        estimatedDelivery: DateTime.now().add(const Duration(hours: 2)),
      );

      await FirestoreService.createUserOrder(order: order);
      await cartProvider.clearPharmacyCart(pharmacyId);

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => const UserShellScreen(initialIndex: 3),
          ),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _t('حدث خطأ: $e', 'Error: $e'),
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
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        color: Colors.black,
      ),
    );
  }
}

class _AddressCard extends StatelessWidget {
  const _AddressCard({required this.address});

  final String address;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.location_on_outlined,
            size: 20,
            color: Color(0xFF12D47B),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              address,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF12D47B),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const Icon(
            Icons.radio_button_checked,
            color: Color(0xFF12D47B),
            size: 18,
          ),
        ],
      ),
    );
  }
}

class _ChoiceButton extends StatelessWidget {
  const _ChoiceButton({
    required this.text,
    required this.selected,
    required this.onTap,
  });

  final String text;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 54,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF12D47B) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? const Color(0xFF12D47B) : Colors.grey.shade300,
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }
}

class _PaymentCard extends StatelessWidget {
  const _PaymentCard({
    required this.title,
    required this.selected,
    required this.onChanged,
  });

  final String title;
  final bool selected;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          Radio<bool>(
            value: true,
            groupValue: selected,
            onChanged: onChanged,
            activeColor: const Color(0xFF12D47B),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.isTotal = false,
  });

  final String label;
  final String value;
  final bool isTotal;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.w800 : FontWeight.w500,
              color: Colors.grey.shade800,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.w800 : FontWeight.w600,
            color: isTotal ? Colors.black : Colors.grey.shade700,
          ),
        ),
      ],
    );
  }
}
