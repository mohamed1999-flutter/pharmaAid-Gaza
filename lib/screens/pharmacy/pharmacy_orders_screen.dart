import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../core/models/pharmacy_models.dart';
import '../../core/service/auth_service.dart';
import '../../core/service/firestore_service.dart';

class PharmacyOrdersScreen extends StatefulWidget {
  const PharmacyOrdersScreen({super.key});

  @override
  State<PharmacyOrdersScreen> createState() => _PharmacyOrdersScreenState();
}

class _PharmacyOrdersScreenState extends State<PharmacyOrdersScreen> {
  late final String _uid = AuthService.currentUser?.uid ?? '';
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _stream = _uid.isEmpty
      ? const Stream.empty()
      : FirestoreService.ordersStream(_uid);

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(isAr ? 'الطلبات السابقة' : 'Previous Orders')),
      body: _uid.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _stream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text(isAr ? 'حدث خطأ' : 'Something went wrong'),
                  );
                }

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs;
                if (docs.isEmpty) {
                  return Center(
                    child: Text(
                      isAr ? 'لا توجد طلبات' : 'No orders yet',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final data = docs[index].data();
                    final order = PharmacyOrder.fromMap(data);

                    return Container(
                      decoration: BoxDecoration(
                        color: cs.surface,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: cs.outlineVariant),
                      ),
                      child: Theme(
                        data: theme.copyWith(dividerColor: Colors.transparent),
                        child: ExpansionTile(
                          tilePadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          childrenPadding: const EdgeInsets.fromLTRB(
                            16,
                            0,
                            16,
                            16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          collapsedShape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          leading: CircleAvatar(
                            backgroundColor: cs.primary.withOpacity(0.12),
                            child: Icon(
                              Icons.receipt_long_rounded,
                              color: cs.primary,
                            ),
                          ),
                          title: Text(
                            order.customerName,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              '${isAr ? 'الإجمالي' : 'Total'}: ${order.total}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ),
                          trailing: _StatusChip(status: order.status),
                          children: [
                            _detailTile(
                              context,
                              label: isAr ? 'رقم الهاتف' : 'Phone',
                              value: order.customerPhone,
                            ),
                            const SizedBox(height: 8),
                            _detailTile(
                              context,
                              label: isAr ? 'العنوان' : 'Address',
                              value: order.address,
                            ),
                            if ((order.note ?? '').isNotEmpty) ...[
                              const SizedBox(height: 8),
                              _detailTile(
                                context,
                                label: isAr ? 'ملاحظات' : 'Note',
                                value: order.note!,
                              ),
                            ],
                            const SizedBox(height: 14),
                            ...order.items.map(
                              (item) => Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: cs.surfaceContainerHighest.withOpacity(
                                    0.5,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(child: Text(item.name)),
                                    Text(
                                      '${item.quantity} × ${item.unitPrice}',
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _btn(
                                  context,
                                  isAr ? 'مقبول' : 'Accepted',
                                  () => FirestoreService.updateOrderStatus(
                                    uid: _uid,
                                    orderId: order.id,
                                    status: 'accepted',
                                  ),
                                ),
                                _btn(
                                  context,
                                  isAr ? 'مرفوض' : 'Rejected',
                                  () => FirestoreService.updateOrderStatus(
                                    uid: _uid,
                                    orderId: order.id,
                                    status: 'rejected',
                                  ),
                                ),
                                _btn(
                                  context,
                                  isAr ? 'تجهيز' : 'Preparing',
                                  () => FirestoreService.updateOrderStatus(
                                    uid: _uid,
                                    orderId: order.id,
                                    status: 'preparing',
                                  ),
                                ),
                                _btn(
                                  context,
                                  isAr ? 'تم التسليم' : 'Delivered',
                                  () => FirestoreService.updateOrderStatus(
                                    uid: _uid,
                                    orderId: order.id,
                                    status: 'delivered',
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }

  Widget _detailTile(
    BuildContext context, {
    required String label,
    required String value,
  }) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withOpacity(0.45),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        '$label: $value',
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _btn(BuildContext context, String label, VoidCallback onTap) {
    return OutlinedButton(onPressed: onTap, child: Text(label));
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    Color bg;
    Color fg;
    String label;

    switch (status) {
      case 'accepted':
        bg = Colors.green.withOpacity(0.14);
        fg = Colors.green.shade700;
        label = 'Accepted';
        break;
      case 'rejected':
        bg = Colors.red.withOpacity(0.14);
        fg = Colors.red.shade700;
        label = 'Rejected';
        break;
      case 'preparing':
        bg = Colors.orange.withOpacity(0.14);
        fg = Colors.orange.shade800;
        label = 'Preparing';
        break;
      case 'delivered':
        bg = Colors.blue.withOpacity(0.14);
        fg = Colors.blue.shade700;
        label = 'Delivered';
        break;
      default:
        bg = cs.primary.withOpacity(0.14);
        fg = cs.primary;
        label = 'Pending';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(color: fg, fontWeight: FontWeight.w800, fontSize: 12),
      ),
    );
  }
}
