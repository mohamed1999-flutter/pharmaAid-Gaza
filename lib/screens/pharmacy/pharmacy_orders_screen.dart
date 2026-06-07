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

class _PharmacyOrdersScreenState extends State<PharmacyOrdersScreen>
    with AutomaticKeepAliveClientMixin {
  late final String _uid = AuthService.currentUser?.uid ?? '';
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _stream = _uid.isEmpty
      ? const Stream.empty()
      : FirestoreService.ordersStream(_uid);

  String _filter = 'all';

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(isAr ? 'الطلبات' : 'Orders'),
          centerTitle: false,
        ),
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

                  final allDocs = snapshot.data!.docs;
                  final filteredDocs = _filter == 'all'
                      ? allDocs
                      : allDocs
                            .where(
                              (e) =>
                                  (e.data()['status'] ?? 'pending') == _filter,
                            )
                            .toList();

                  final pending = allDocs
                      .where(
                        (e) => (e.data()['status'] ?? 'pending') == 'pending',
                      )
                      .length;
                  final accepted = allDocs
                      .where((e) => (e.data()['status'] ?? '') == 'accepted')
                      .length;
                  final preparing = allDocs
                      .where((e) => (e.data()['status'] ?? '') == 'preparing')
                      .length;
                  final delivered = allDocs
                      .where((e) => (e.data()['status'] ?? '') == 'delivered')
                      .length;

                  return CustomScrollView(
                    physics: const BouncingScrollPhysics(),
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
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _FilterChipItem(
                                label: isAr ? 'الكل' : 'All',
                                selected: _filter == 'all',
                                onTap: () => setState(() => _filter = 'all'),
                              ),
                              _FilterChipItem(
                                label: isAr ? 'معلقة' : 'Pending',
                                selected: _filter == 'pending',
                                onTap: () =>
                                    setState(() => _filter = 'pending'),
                              ),
                              _FilterChipItem(
                                label: isAr ? 'مقبولة' : 'Accepted',
                                selected: _filter == 'accepted',
                                onTap: () =>
                                    setState(() => _filter = 'accepted'),
                              ),
                              _FilterChipItem(
                                label: isAr ? 'تجهيز' : 'Preparing',
                                selected: _filter == 'preparing',
                                onTap: () =>
                                    setState(() => _filter = 'preparing'),
                              ),
                              _FilterChipItem(
                                label: isAr ? 'تم التسليم' : 'Delivered',
                                selected: _filter == 'delivered',
                                onTap: () =>
                                    setState(() => _filter = 'delivered'),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (filteredDocs.isEmpty)
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(
                            child: Text(
                              isAr ? 'لا توجد طلبات' : 'No orders found',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: cs.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          sliver: SliverList.separated(
                            itemCount: filteredDocs.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final data = filteredDocs[index].data();
                              final order = PharmacyOrder.fromMap(data);

                              return _OrderCard(
                                key: ValueKey(order.id),
                                isAr: isAr,
                                order: order,
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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [cs.primary.withOpacity(0.96), cs.primary.withOpacity(0.68)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: cs.primary.withOpacity(0.15),
            blurRadius: 26,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isAr ? 'إدارة الطلبات' : 'Order management',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isAr
                ? 'فلترة سريعة ومتابعة واضحة'
                : 'Quick filtering and clear tracking',
            style: TextStyle(
              color: Colors.white.withOpacity(0.92),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _SmallStat(
                  title: isAr ? 'معلقة' : 'Pending',
                  value: pending,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SmallStat(
                  title: isAr ? 'مقبولة' : 'Accepted',
                  value: accepted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _SmallStat(
                  title: isAr ? 'تجهيز' : 'Preparing',
                  value: preparing,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SmallStat(
                  title: isAr ? 'تم التسليم' : 'Delivered',
                  value: delivered,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SmallStat extends StatelessWidget {
  const _SmallStat({required this.title, required this.value});

  final String title;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Column(
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
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withOpacity(0.92),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChipItem extends StatelessWidget {
  const _FilterChipItem({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      labelStyle: TextStyle(
        fontWeight: FontWeight.w700,
        color: selected ? cs.primary : cs.onSurfaceVariant,
      ),
      selectedColor: cs.primary.withOpacity(0.12),
      backgroundColor: cs.surface,
      side: BorderSide(color: cs.outlineVariant),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({
    super.key,
    required this.isAr,
    required this.order,
    required this.uid,
  });

  final bool isAr;
  final PharmacyOrder order;
  final String uid;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: cs.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          key: ValueKey('tile_${order.id}'),
          initiallyExpanded: false,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          collapsedShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          leading: CircleAvatar(
            backgroundColor: cs.primary.withOpacity(0.10),
            child: Icon(Icons.receipt_long_rounded, color: cs.primary),
          ),
          title: Text(
            order.customerName,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              isAr ? 'الإجمالي: ${order.total} ₪' : 'Total: ${order.total} ₪',
              style: theme.textTheme.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          trailing: _StatusChip(status: order.status),
          children: [
            _DetailRow(
              label: isAr ? 'رقم الهاتف' : 'Phone',
              value: order.customerPhone,
            ),
            const SizedBox(height: 8),
            _DetailRow(
              label: isAr ? 'العنوان' : 'Address',
              value: order.address,
            ),
            if (order.note != null && order.note!.isNotEmpty) ...[
              const SizedBox(height: 8),
              _DetailRow(label: isAr ? 'ملاحظات' : 'Note', value: order.note!),
            ],
            const SizedBox(height: 14),
            ..._buildItems(theme),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _ActionBtn(
                  label: isAr ? 'مقبول' : 'Accept',
                  icon: Icons.check_rounded,
                  onTap: () => FirestoreService.updateOrderStatus(
                    uid: uid,
                    orderId: order.id,
                    status: 'accepted',
                  ),
                ),
                _ActionBtn(
                  label: isAr ? 'مرفوض' : 'Reject',
                  icon: Icons.close_rounded,
                  onTap: () => FirestoreService.updateOrderStatus(
                    uid: uid,
                    orderId: order.id,
                    status: 'rejected',
                  ),
                ),
                _ActionBtn(
                  label: isAr ? 'تجهيز' : 'Preparing',
                  icon: Icons.kitchen_outlined,
                  onTap: () => FirestoreService.updateOrderStatus(
                    uid: uid,
                    orderId: order.id,
                    status: 'preparing',
                  ),
                ),
                _ActionBtn(
                  label: isAr ? 'تم التسليم' : 'Delivered',
                  icon: Icons.local_shipping_outlined,
                  onTap: () => FirestoreService.updateOrderStatus(
                    uid: uid,
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
  }

  List<Widget> _buildItems(ThemeData theme) {
    if (order.items.isEmpty) return [];

    return [
      Text(
        isAr ? 'العناصر' : 'Items',
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w900,
        ),
      ),
      const SizedBox(height: 8),
      ...order.items.map((item) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withOpacity(
                0.48,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(child: Text(item.name)),
                Text(
                  '${item.quantity} × ${item.unitPrice} ₪',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w800,
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

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
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
}

class _ActionBtn extends StatelessWidget {
  const _ActionBtn({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilledButton.tonalIcon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
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
