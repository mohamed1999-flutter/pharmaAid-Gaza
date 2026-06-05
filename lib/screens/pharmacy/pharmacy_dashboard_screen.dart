import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../core/service/auth_service.dart';
import '../../core/service/firestore_service.dart';
import '../home_screen/home_screen.dart';

class PharmacyDashboardScreen extends StatefulWidget {
  const PharmacyDashboardScreen({super.key});

  @override
  State<PharmacyDashboardScreen> createState() =>
      _PharmacyDashboardScreenState();
}

class _PharmacyDashboardScreenState extends State<PharmacyDashboardScreen> {
  late final String _uid = AuthService.currentUser?.uid ?? '';
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _ordersStream =
      _uid.isEmpty ? const Stream.empty() : FirestoreService.ordersStream(_uid);

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(isAr ? 'لوحة الصيدلية' : 'Pharmacy Dashboard'),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.exit_to_app_rounded),
            tooltip: isAr ? 'خروج من النظام' : 'Exit system',
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const HomeScreen()),
                (route) => false,
              );
            },
          ),
        ),
        body: _uid.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _ordersStream,
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
                  final pending = docs
                      .where(
                        (e) => (e.data()['status'] ?? 'pending') == 'pending',
                      )
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

                  return CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                          child: _HeaderCard(
                            isAr: isAr,
                            pending: pending,
                            accepted: accepted,
                            preparing: preparing,
                            delivered: delivered,
                          ),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                          child: Text(
                            isAr ? 'الطلبات الحالية' : 'Current Orders',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      if (docs.isEmpty)
                        SliverFillRemaining(
                          hasScrollBody: false,
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
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          sliver: SliverList.separated(
                            itemCount: docs.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final data = docs[index].data();
                              final orderId =
                                  data['id'] as String? ?? docs[index].id;
                              final status = (data['status'] ?? 'pending')
                                  .toString();

                              return _OrderCard(
                                isAr: isAr,
                                data: data,
                                orderId: orderId,
                                status: status,
                                uid: _uid,
                              );
                            },
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

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.isAr,
    required this.pending,
    required this.accepted,
    required this.preparing,
    required this.delivered,
  });

  final bool isAr;
  final int pending;
  final int accepted;
  final int preparing;
  final int delivered;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [cs.primary.withOpacity(0.95), cs.primary.withOpacity(0.65)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isAr ? 'مرحبًا بك 👋' : 'Welcome 👋',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isAr ? 'إدارة الطلبات بشكل سريع وواضح' : 'Fast order management',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.95,
            children: [
              _StatMiniCard(
                title: isAr ? 'معلقة' : 'Pending',
                value: pending,
                icon: Icons.pending_actions_rounded,
              ),
              _StatMiniCard(
                title: isAr ? 'مقبولة' : 'Accepted',
                value: accepted,
                icon: Icons.check_circle_outline_rounded,
              ),
              _StatMiniCard(
                title: isAr ? 'تجهيز' : 'Preparing',
                value: preparing,
                icon: Icons.kitchen_outlined,
              ),
              _StatMiniCard(
                title: isAr ? 'تم التسليم' : 'Delivered',
                value: delivered,
                icon: Icons.local_shipping_outlined,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatMiniCard extends StatelessWidget {
  const _StatMiniCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final int value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.16)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.white.withOpacity(0.16),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$value',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
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

class _OrderCard extends StatelessWidget {
  const _OrderCard({
    required this.isAr,
    required this.data,
    required this.orderId,
    required this.status,
    required this.uid,
  });

  final bool isAr;
  final Map<String, dynamic> data;
  final String orderId;
  final String status;
  final String uid;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          collapsedShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          leading: CircleAvatar(
            backgroundColor: cs.primary.withOpacity(0.12),
            child: Icon(Icons.receipt_long_rounded, color: cs.primary),
          ),
          title: Text(
            data['customerName'] ?? '',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '${isAr ? 'الإجمالي' : 'Total'}: ${data['total'] ?? 0}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
          ),
          trailing: _StatusChip(status: status),
          children: [
            _DetailRow(
              label: isAr ? 'رقم الهاتف' : 'Phone',
              value: data['customerPhone'] ?? '',
            ),
            const SizedBox(height: 8),
            _DetailRow(
              label: isAr ? 'العنوان' : 'Address',
              value: data['address'] ?? '',
            ),
            if ((data['note'] ?? '').toString().isNotEmpty) ...[
              const SizedBox(height: 8),
              _DetailRow(
                label: isAr ? 'ملاحظات' : 'Note',
                value: data['note'] ?? '',
              ),
            ],
            const SizedBox(height: 14),
            ..._buildItems(theme, data),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _ActionBtn(
                  label: isAr ? 'مقبول' : 'Accepted',
                  onTap: () => FirestoreService.updateOrderStatus(
                    uid: uid,
                    orderId: orderId,
                    status: 'accepted',
                  ),
                ),
                _ActionBtn(
                  label: isAr ? 'مرفوض' : 'Rejected',
                  onTap: () => FirestoreService.updateOrderStatus(
                    uid: uid,
                    orderId: orderId,
                    status: 'rejected',
                  ),
                ),
                _ActionBtn(
                  label: isAr ? 'تجهيز' : 'Preparing',
                  onTap: () => FirestoreService.updateOrderStatus(
                    uid: uid,
                    orderId: orderId,
                    status: 'preparing',
                  ),
                ),
                _ActionBtn(
                  label: isAr ? 'تم التسليم' : 'Delivered',
                  onTap: () => FirestoreService.updateOrderStatus(
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
  }

  List<Widget> _buildItems(ThemeData theme, Map<String, dynamic> data) {
    final items = (data['items'] as List?) ?? const [];
    if (items.isEmpty) return [];

    return [
      Text(
        'Items',
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w800,
        ),
      ),
      const SizedBox(height: 8),
      ...items.map((item) {
        final map = (item as Map).cast<String, dynamic>();
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(child: Text(map['name']?.toString() ?? '')),
                Text(
                  '${map['quantity'] ?? 0} × ${map['unitPrice'] ?? 0}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    ];
  }
}

class _ActionBtn extends StatelessWidget {
  const _ActionBtn({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(onPressed: onTap, child: Text(label));
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withOpacity(0.45),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        '$label: $value',
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
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
