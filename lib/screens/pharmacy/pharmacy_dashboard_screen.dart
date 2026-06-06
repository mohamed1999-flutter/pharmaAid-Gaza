import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app/app_controller.dart';
import '../../core/service/auth_service.dart';
import '../../core/service/firestore_service.dart';
import '../chat/chat_list_screen.dart';
import '../user/user_shell_screen.dart';

class PharmacyDashboardScreen extends StatefulWidget {
  const PharmacyDashboardScreen({super.key});

  @override
  State<PharmacyDashboardScreen> createState() =>
      _PharmacyDashboardScreenState();
}

class _PharmacyDashboardScreenState extends State<PharmacyDashboardScreen>
    with AutomaticKeepAliveClientMixin {
  late final String _uid = AuthService.currentUser?.uid ?? '';
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _ordersStream =
      _uid.isEmpty
      ? const Stream<QuerySnapshot<Map<String, dynamic>>>.empty()
      : FirestoreService.ordersStream(_uid);

  final Set<String> _expandedOrderIds = <String>{};

  @override
  bool get wantKeepAlive => true;

  String _asString(dynamic value, [String fallback = '']) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }

  int _asInt(dynamic value, [int fallback = 0]) {
    if (value == null) return fallback;
    if (value is int) return value;
    if (value is double) return value.round();
    return int.tryParse(value.toString()) ?? fallback;
  }

  double _asDouble(dynamic value, [double fallback = 0.0]) {
    if (value == null) return fallback;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString()) ?? fallback;
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, v) => MapEntry(key.toString(), v));
    }
    return <String, dynamic>{};
  }

  List<dynamic> _asList(dynamic value) {
    if (value is List) return value;
    return <dynamic>[];
  }

  String _formatMoney(dynamic value) {
    final numValue = _asDouble(value);
    if (numValue == numValue.roundToDouble()) {
      return numValue.toInt().toString();
    }
    return numValue.toStringAsFixed(2);
  }

  void _toggleExpanded(String orderId) {
    setState(() {
      if (_expandedOrderIds.contains(orderId)) {
        _expandedOrderIds.remove(orderId);
      } else {
        _expandedOrderIds.add(orderId);
      }
    });
  }

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
          title: Text(isAr ? 'لوحة الصيدلية' : 'Pharmacy Dashboard'),
          centerTitle: false,
          elevation: 0,
          actions: [
            StreamBuilder<int>(
              stream: FirestoreService.totalUnreadCountStream(_uid, true),
              builder: (context, snapshot) {
                final count = snapshot.data ?? 0;
                return Badge(
                  label: Text('$count'),
                  isLabelVisible: count > 0,
                  backgroundColor: Colors.red,
                  child: IconButton(
                    tooltip: isAr ? 'المحادثات' : 'Chats',
                    icon: const Icon(Icons.chat_bubble_outline_rounded),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              const ChatListScreen(isPharmacy: true),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
            IconButton(
              tooltip: isAr ? 'الخروج' : 'Exit',
              icon: const Icon(Icons.logout_rounded),
              onPressed: () async {
                await context.read<AppController>().toggleSystemMode();
                if (!context.mounted) return;
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const UserShellScreen()),
                  (route) => false,
                );
              },
            ),
          ],
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
                        (e) =>
                            _asString(e.data()['status'], 'pending') ==
                            'pending',
                      )
                      .length;
                  final accepted = docs
                      .where((e) => _asString(e.data()['status']) == 'accepted')
                      .length;
                  final preparing = docs
                      .where(
                        (e) => _asString(e.data()['status']) == 'preparing',
                      )
                      .length;
                  final delivered = docs
                      .where(
                        (e) => _asString(e.data()['status']) == 'delivered',
                      )
                      .length;

                  final recent = docs.take(4).toList();

                  return CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                          child: _HeroCard(
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
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  isAr ? 'نظرة سريعة' : 'Quick Overview',
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                              Text(
                                '${docs.length} ${isAr ? 'طلب' : 'orders'}',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: cs.onSurfaceVariant,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        sliver: SliverGrid(
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisExtent: 110,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                              ),
                          delegate: SliverChildListDelegate.fixed([
                            _StatCard(
                              title: isAr ? 'معلقة' : 'Pending',
                              value: pending,
                              icon: Icons.pending_actions_rounded,
                            ),
                            _StatCard(
                              title: isAr ? 'مقبولة' : 'Accepted',
                              value: accepted,
                              icon: Icons.check_circle_outline_rounded,
                            ),
                            _StatCard(
                              title: isAr ? 'تجهيز' : 'Preparing',
                              value: preparing,
                              icon: Icons.kitchen_outlined,
                            ),
                            _StatCard(
                              title: isAr ? 'تم التسليم' : 'Delivered',
                              value: delivered,
                              icon: Icons.local_shipping_outlined,
                            ),
                          ]),
                        ),
                      ),
                      const SliverToBoxAdapter(child: SizedBox(height: 18)),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  isAr ? 'آخر الطلبات' : 'Recent Orders',
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (recent.isEmpty)
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
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                          sliver: SliverList.separated(
                            itemCount: recent.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final data = _asMap(recent[index].data());
                              final orderId = _asString(
                                data['id'],
                                recent[index].id,
                              );
                              final status = _asString(
                                data['status'],
                                'pending',
                              );

                              return _OrderCard(
                                key: ValueKey(orderId),
                                isAr: isAr,
                                data: data,
                                orderId: orderId,
                                status: status,
                                uid: _uid,
                                expanded: _expandedOrderIds.contains(orderId),
                                onToggle: () => _toggleExpanded(orderId),
                                asString: _asString,
                                asInt: _asInt,
                                asDouble: _asDouble,
                                asList: _asList,
                                formatMoney: _formatMoney,
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

class _HeroCard extends StatelessWidget {
  const _HeroCard({
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
          colors: [cs.primary, cs.primary.withOpacity(0.72)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: cs.primary.withOpacity(0.18),
            blurRadius: 30,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isAr ? 'مرحبًا بك 👋' : 'Welcome 👋',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isAr
                ? 'إدارة الطلبات بشكل سريع وواضح'
                : 'Fast, clean order management',
            style: TextStyle(
              color: Colors.white.withOpacity(0.92),
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _MiniStat(
                  title: isAr ? 'معلقة' : 'Pending',
                  value: pending,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MiniStat(
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
                child: _MiniStat(
                  title: isAr ? 'تجهيز' : 'Preparing',
                  value: preparing,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MiniStat(
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

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.title, required this.value});

  final String title;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.14)),
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
              color: Colors.white.withOpacity(0.9),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final int value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: cs.primary.withOpacity(0.10),
            child: Icon(icon, color: cs.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$value',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
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
    super.key,
    required this.isAr,
    required this.data,
    required this.orderId,
    required this.status,
    required this.uid,
    required this.expanded,
    required this.onToggle,
    required this.asString,
    required this.asInt,
    required this.asDouble,
    required this.asList,
    required this.formatMoney,
  });

  final bool isAr;
  final Map<String, dynamic> data;
  final String orderId;
  final String status;
  final String uid;
  final bool expanded;
  final VoidCallback onToggle;

  final String Function(dynamic value, [String fallback]) asString;
  final int Function(dynamic value, [int fallback]) asInt;
  final double Function(dynamic value, [double fallback]) asDouble;
  final List<dynamic> Function(dynamic value) asList;
  final String Function(dynamic value) formatMoney;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final customerName = asString(data['customerName'], '');
    final totalText = formatMoney(data['total']);

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: cs.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: cs.primary.withOpacity(0.10),
                        child: Icon(
                          Icons.receipt_long_rounded,
                          color: cs.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              customerName.isEmpty
                                  ? (isAr ? 'عميل' : 'Customer')
                                  : customerName,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isAr
                                  ? 'الإجمالي: $totalText'
                                  : 'Total: $totalText',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: cs.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      _StatusChip(status: status),
                      const SizedBox(width: 8),
                      Icon(
                        expanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        color: cs.onSurfaceVariant,
                      ),
                    ],
                  ),
                  AnimatedCrossFade(
                    firstChild: const SizedBox(height: 0),
                    secondChild: Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _DetailRow(
                            label: isAr ? 'رقم الهاتف' : 'Phone',
                            value: asString(data['customerPhone'], ''),
                          ),
                          const SizedBox(height: 8),
                          _DetailRow(
                            label: isAr ? 'العنوان' : 'Address',
                            value: asString(data['address'], ''),
                          ),
                          if (asString(data['note'], '').isNotEmpty) ...[
                            const SizedBox(height: 8),
                            _DetailRow(
                              label: isAr ? 'ملاحظات' : 'Note',
                              value: asString(data['note'], ''),
                            ),
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
                                  orderId: orderId,
                                  status: 'accepted',
                                ),
                              ),
                              _ActionBtn(
                                label: isAr ? 'مرفوض' : 'Reject',
                                icon: Icons.close_rounded,
                                onTap: () => FirestoreService.updateOrderStatus(
                                  uid: uid,
                                  orderId: orderId,
                                  status: 'rejected',
                                ),
                              ),
                              _ActionBtn(
                                label: isAr ? 'تجهيز' : 'Preparing',
                                icon: Icons.kitchen_outlined,
                                onTap: () => FirestoreService.updateOrderStatus(
                                  uid: uid,
                                  orderId: orderId,
                                  status: 'preparing',
                                ),
                              ),
                              _ActionBtn(
                                label: isAr ? 'تم التسليم' : 'Delivered',
                                icon: Icons.local_shipping_outlined,
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
                    crossFadeState: expanded
                        ? CrossFadeState.showSecond
                        : CrossFadeState.showFirst,
                    duration: const Duration(milliseconds: 220),
                    sizeCurve: Curves.easeOut,
                    firstCurve: Curves.easeOut,
                    secondCurve: Curves.easeOut,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildItems(ThemeData theme) {
    final items = asList(data['items']);
    if (items.isEmpty) return const [];

    return [
      Text(
        'Items',
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w900,
        ),
      ),
      const SizedBox(height: 8),
      ...items.map((item) {
        final map = item is Map
            ? item.map((key, value) => MapEntry(key.toString(), value))
            : <String, dynamic>{};

        final name = asString(map['name'], '');
        final quantity = asInt(map['quantity'], 0);
        final unitPrice = formatMoney(map['unitPrice']);

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
                Expanded(child: Text(name)),
                Text(
                  '$quantity × $unitPrice',
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
