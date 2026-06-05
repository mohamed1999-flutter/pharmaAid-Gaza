import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../core/service/auth_service.dart';
import '../../core/service/firestore_service.dart';

/// Pharmacy home dashboard that receives and manages live orders.
class PharmacyDashboardScreen extends StatelessWidget {
  const PharmacyDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = AuthService.currentUser!.uid;
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(isAr ? 'لوحة الصيدلية' : 'Pharmacy Dashboard'),
          centerTitle: true,
        ),
        body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirestoreService.ordersStream(uid),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Center(child: Text('Something went wrong'));
            }

            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final docs = snapshot.data!.docs;
            final pending = docs
                .where((e) => (e.data()['status'] ?? 'pending') == 'pending')
                .length;
            final accepted = docs
                .where((e) => (e.data()['status'] ?? '') == 'accepted')
                .length;
            final preparing = docs
                .where((e) => (e.data()['status'] ?? '') == 'preparing')
                .length;
            final delivered = docs
                .where((e) => (e.data()['status'] ?? '') == 'delivered')
                .length;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _StatsRow(
                    pending: pending,
                    accepted: accepted,
                    preparing: preparing,
                    delivered: delivered,
                    isAr: isAr,
                  ),
                  const SizedBox(height: 18),
                  Text(
                    isAr ? 'الطلبات الحالية' : 'Current Orders',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (docs.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 40),
                      child: Center(
                        child: Text(
                          isAr ? 'لا توجد طلبات حتى الآن' : 'No orders yet',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ),
                    )
                  else
                    ...docs.map((doc) {
                      final data = doc.data();
                      final orderId = data['id'] as String;
                      final status = (data['status'] ?? 'pending').toString();

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: cs.surface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: cs.outlineVariant),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 46,
                                    height: 46,
                                    decoration: BoxDecoration(
                                      color: cs.primary.withOpacity(0.12),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.receipt_long,
                                      color: cs.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          data['customerName'] ?? '',
                                          style: theme.textTheme.titleMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.w700,
                                              ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          data['customerPhone'] ?? '',
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                                color: cs.onSurfaceVariant,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  _StatusChip(status: status),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                data['address'] ?? '',
                                style: theme.textTheme.bodyMedium,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${isAr ? 'الإجمالي' : 'Total'}: ${data['total'] ?? 0}',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '${isAr ? 'الحالة' : 'Status'}: $status',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  _actionButton(
                                    context,
                                    label: isAr ? 'مقبول' : 'Accepted',
                                    onTap: () =>
                                        FirestoreService.updateOrderStatus(
                                          uid: uid,
                                          orderId: orderId,
                                          status: 'accepted',
                                        ),
                                  ),
                                  _actionButton(
                                    context,
                                    label: isAr ? 'مرفوض' : 'Rejected',
                                    onTap: () =>
                                        FirestoreService.updateOrderStatus(
                                          uid: uid,
                                          orderId: orderId,
                                          status: 'rejected',
                                        ),
                                  ),
                                  _actionButton(
                                    context,
                                    label: isAr ? 'يتم التجهيز' : 'Preparing',
                                    onTap: () =>
                                        FirestoreService.updateOrderStatus(
                                          uid: uid,
                                          orderId: orderId,
                                          status: 'preparing',
                                        ),
                                  ),
                                  _actionButton(
                                    context,
                                    label: isAr ? 'تم التسليم' : 'Delivered',
                                    onTap: () =>
                                        FirestoreService.updateOrderStatus(
                                          uid: uid,
                                          orderId: orderId,
                                          status: 'delivered',
                                        ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _actionButton(
    BuildContext context, {
    required String label,
    required VoidCallback onTap,
  }) {
    final cs = Theme.of(context).colorScheme;

    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: cs.primary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: onTap,
      child: Text(label),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({
    required this.pending,
    required this.accepted,
    required this.preparing,
    required this.delivered,
    required this.isAr,
  });

  final int pending;
  final int accepted;
  final int preparing;
  final int delivered;
  final bool isAr;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.9,
      children: [
        _statCard(
          context,
          isAr ? 'معلقة' : 'Pending',
          pending.toString(),
          Icons.pending_actions,
        ),
        _statCard(
          context,
          isAr ? 'مقبولة' : 'Accepted',
          accepted.toString(),
          Icons.check_circle_outline,
        ),
        _statCard(
          context,
          isAr ? 'تجهيز' : 'Preparing',
          preparing.toString(),
          Icons.kitchen_outlined,
        ),
        _statCard(
          context,
          isAr ? 'تم التسليم' : 'Delivered',
          delivered.toString(),
          Icons.local_shipping_outlined,
        ),
      ],
    );
  }

  Widget _statCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
  ) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: cs.primary.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: cs.primary, size: 22),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(title),
            ],
          ),
        ],
      ),
    );
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

    switch (status) {
      case 'accepted':
        bg = Colors.green.withOpacity(0.14);
        fg = Colors.green;
        break;
      case 'rejected':
        bg = Colors.red.withOpacity(0.14);
        fg = Colors.red;
        break;
      case 'preparing':
        bg = Colors.orange.withOpacity(0.14);
        fg = Colors.orange;
        break;
      case 'delivered':
        bg = Colors.blue.withOpacity(0.14);
        fg = Colors.blue;
        break;
      default:
        bg = cs.primary.withOpacity(0.14);
        fg = cs.primary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status,
        style: TextStyle(color: fg, fontWeight: FontWeight.w700, fontSize: 12),
      ),
    );
  }
}
