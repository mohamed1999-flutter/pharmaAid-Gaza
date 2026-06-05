import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../core/models/pharmacy_models.dart';
import '../../core/service/auth_service.dart';
import '../../core/service/firestore_service.dart';

/// Displays previous orders with details and status controls.
class PharmacyOrdersScreen extends StatelessWidget {
  const PharmacyOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = AuthService.currentUser!.uid;
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(isAr ? 'الطلبات السابقة' : 'Previous Orders')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirestoreService.ordersStream(uid),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return Center(
              child: Text(isAr ? 'لا توجد طلبات' : 'No orders yet'),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final data = docs[index].data();
              final order = PharmacyOrder.fromMap(data);

              return ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: BorderSide(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
                collapsedShape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: BorderSide(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
                title: Text(
                  order.customerName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                subtitle: Text(
                  '${isAr ? 'الإجمالي' : 'Total'}: ${order.total} | ${isAr ? 'الحالة' : 'Status'}: ${order.status}',
                ),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(order.customerPhone),
                  ),
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(order.address),
                  ),
                  if ((order.note ?? '').isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '${isAr ? 'ملاحظات' : 'Note'}: ${order.note}',
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  ...order.items.map(
                    (item) => ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(item.name),
                      subtitle: Text('${item.quantity} x ${item.unitPrice}'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _btn(
                        context,
                        isAr ? 'مقبول' : 'Accepted',
                        () => FirestoreService.updateOrderStatus(
                          uid: uid,
                          orderId: order.id,
                          status: 'accepted',
                        ),
                      ),
                      _btn(
                        context,
                        isAr ? 'مرفوض' : 'Rejected',
                        () => FirestoreService.updateOrderStatus(
                          uid: uid,
                          orderId: order.id,
                          status: 'rejected',
                        ),
                      ),
                      _btn(
                        context,
                        isAr ? 'تجهيز' : 'Preparing',
                        () => FirestoreService.updateOrderStatus(
                          uid: uid,
                          orderId: order.id,
                          status: 'preparing',
                        ),
                      ),
                      _btn(
                        context,
                        isAr ? 'تم التسليم' : 'Delivered',
                        () => FirestoreService.updateOrderStatus(
                          uid: uid,
                          orderId: order.id,
                          status: 'delivered',
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _btn(BuildContext context, String label, VoidCallback onTap) {
    return OutlinedButton(onPressed: onTap, child: Text(label));
  }
}
