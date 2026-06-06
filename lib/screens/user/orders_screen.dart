import 'dart:ui' as ui;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/models/user_models.dart';
import '../../core/service/auth_service.dart';
import '../../core/service/firestore_service.dart';
import 'pharmacy_details_screen.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  String _selectedFilter = 'all';

  bool get _isArabic => Localizations.localeOf(context).languageCode == 'ar';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final direction = _isArabic ? ui.TextDirection.rtl : ui.TextDirection.ltr;
    final user = AuthService.currentUser;

    return Directionality(
      textDirection: direction,
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                cs.primary.withOpacity(0.10),
                theme.scaffoldBackgroundColor,
              ],
            ),
          ),
          child: SafeArea(
            child: user == null
                ? _buildSignedOutState(theme, cs)
                : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: FirestoreService.userOrdersStream(
                      user.uid,
                      status: _selectedFilter == 'all' ? null : _selectedFilter,
                    ),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return _buildLoadingState(cs);
                      }

                      if (snapshot.hasError) {
                        return _buildErrorState(
                          theme,
                          cs,
                          message: _isArabic
                              ? 'تعذر تحميل الطلبات'
                              : 'Failed to load orders',
                        );
                      }

                      final docs = snapshot.data?.docs ?? [];
                      final orders = docs
                          .map((doc) => UserOrder.fromMap(doc.data(), doc.id))
                          .toList();

                      if (orders.isEmpty) {
                        return _buildEmptyState(theme, cs);
                      }

                      final pendingCount = orders
                          .where((o) => o.status == 'pending')
                          .length;
                      final preparingCount = orders
                          .where((o) => o.status == 'preparing')
                          .length;
                      final readyCount = orders
                          .where((o) => o.status == 'ready')
                          .length;
                      final completedCount = orders
                          .where((o) => o.status == 'completed')
                          .length;

                      return ListView(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                        children: [
                          _HeaderCard(
                            isArabic: _isArabic,
                            totalOrders: orders.length,
                            pendingCount: pendingCount,
                            preparingCount: preparingCount,
                            readyCount: readyCount,
                            completedCount: completedCount,
                            colorScheme: cs,
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 54,
                            child: ListView(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.only(bottom: 4),
                              children: [
                                _FilterChip(
                                  label: _isArabic ? 'الكل' : 'All',
                                  isSelected: _selectedFilter == 'all',
                                  colorScheme: cs,
                                  onTap: () =>
                                      setState(() => _selectedFilter = 'all'),
                                ),
                                _FilterChip(
                                  label: _isArabic ? 'قيد الانتظار' : 'Pending',
                                  isSelected: _selectedFilter == 'pending',
                                  colorScheme: cs,
                                  onTap: () => setState(
                                    () => _selectedFilter = 'pending',
                                  ),
                                ),
                                _FilterChip(
                                  label: _isArabic
                                      ? 'قيد التحضير'
                                      : 'Preparing',
                                  isSelected: _selectedFilter == 'preparing',
                                  colorScheme: cs,
                                  onTap: () => setState(
                                    () => _selectedFilter = 'preparing',
                                  ),
                                ),
                                _FilterChip(
                                  label: _isArabic ? 'جاهز' : 'Ready',
                                  isSelected: _selectedFilter == 'ready',
                                  colorScheme: cs,
                                  onTap: () =>
                                      setState(() => _selectedFilter = 'ready'),
                                ),
                                _FilterChip(
                                  label: _isArabic ? 'مكتمل' : 'Completed',
                                  isSelected: _selectedFilter == 'completed',
                                  colorScheme: cs,
                                  onTap: () => setState(
                                    () => _selectedFilter = 'completed',
                                  ),
                                ),
                                _FilterChip(
                                  label: _isArabic ? 'ملغي' : 'Cancelled',
                                  isSelected: _selectedFilter == 'cancelled',
                                  colorScheme: cs,
                                  onTap: () => setState(
                                    () => _selectedFilter = 'cancelled',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          ...orders.map(
                            (order) => _OrderCard(
                              order: order,
                              colorScheme: cs,
                              isArabic: _isArabic,
                              onTap: () => _showOrderDetails(context, order),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildSignedOutState(ThemeData theme, ColorScheme cs) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Card(
          elevation: 0,
          color: cs.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: cs.outlineVariant),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock_outline_rounded, size: 56, color: cs.primary),
                const SizedBox(height: 14),
                Text(
                  _isArabic ? 'يجب تسجيل الدخول أولًا' : 'Please sign in first',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _isArabic
                      ? 'لا يمكن عرض الطلبات بدون حساب صيدلي مسجل.'
                      : 'Orders cannot be shown without a signed-in pharmacist account.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState(ColorScheme cs) {
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildErrorState(
    ThemeData theme,
    ColorScheme cs, {
    required String message,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Card(
          elevation: 0,
          color: cs.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: cs.outlineVariant),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline_rounded, size: 56, color: cs.error),
                const SizedBox(height: 14),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _isArabic
                      ? 'حاول مرة أخرى بعد قليل'
                      : 'Please try again in a moment',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 14),
                OutlinedButton(
                  onPressed: () => setState(() {}),
                  child: Text(_isArabic ? 'إعادة المحاولة' : 'Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, ColorScheme cs) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Card(
          elevation: 0,
          color: cs.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: cs.outlineVariant),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.receipt_long_outlined,
                  size: 64,
                  color: cs.onSurfaceVariant,
                ),
                const SizedBox(height: 14),
                Text(
                  _isArabic ? 'لا توجد طلبات' : 'No orders yet',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _isArabic
                      ? 'عندما تصل طلبات جديدة ستظهر هنا مباشرة.'
                      : 'New orders will appear here automatically.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy • HH:mm').format(date);
  }

  void _showOrderDetails(BuildContext context, UserOrder order) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => DraggableScrollableSheet(
        initialChildSize: 0.72,
        minChildSize: 0.52,
        maxChildSize: 0.96,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
            ),
            child: Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: cs.outlineVariant,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(20),
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              _isArabic ? 'تفاصيل الطلب' : 'Order Details',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          _StatusBadge(
                            status: order.status,
                            colorScheme: cs,
                            isArabic: _isArabic,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _DetailCard(
                        title: _isArabic ? 'معلومات الطلب' : 'Order info',
                        children: [
                          _InfoRow(
                            icon: Icons.tag_rounded,
                            label: _isArabic ? 'رقم الطلب' : 'Order ID',
                            value: '#${order.id}',
                            colorScheme: cs,
                          ),
                          const SizedBox(height: 12),
                          _InfoRow(
                            icon: Icons.calendar_month_rounded,
                            label: _isArabic ? 'تاريخ الإنشاء' : 'Created at',
                            value: _formatDate(order.createdAt),
                            colorScheme: cs,
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _DetailCard(
                        title: _isArabic ? 'البيانات الأساسية' : 'Main info',
                        children: [
                          _InfoRow(
                            icon: Icons.local_pharmacy_rounded,
                            label: _isArabic ? 'الصيدلية' : 'Pharmacy',
                            value: order.pharmacyName,
                            colorScheme: cs,
                          ),
                          const SizedBox(height: 12),
                          _InfoRow(
                            icon: Icons.location_on_outlined,
                            label: _isArabic ? 'العنوان' : 'Address',
                            value: order.deliveryAddress,
                            colorScheme: cs,
                          ),
                          if ((order.customerNote ?? '').trim().isNotEmpty) ...[
                            const SizedBox(height: 12),
                            _InfoRow(
                              icon: Icons.note_outlined,
                              label: _isArabic ? 'ملاحظة' : 'Note',
                              value: order.customerNote!,
                              colorScheme: cs,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 14),
                      _DetailCard(
                        title: _isArabic ? 'المنتجات' : 'Items',
                        children: [
                          if (order.items.isEmpty)
                            Text(
                              _isArabic
                                  ? 'لا توجد منتجات داخل الطلب'
                                  : 'No items inside this order',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                            )
                          else
                            ...order.items.map((item) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: cs.surfaceContainerHighest
                                        .withOpacity(0.45),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: cs.outlineVariant,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 20,
                                        backgroundColor: cs.primary.withOpacity(
                                          0.12,
                                        ),
                                        child: Icon(
                                          Icons.medication_outlined,
                                          size: 20,
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
                                              item.name,
                                              style: theme.textTheme.bodyLarge
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              '${_isArabic ? 'الكمية' : 'Qty'}: ${item.quantity}',
                                              style: theme.textTheme.bodySmall
                                                  ?.copyWith(
                                                    color: cs.onSurfaceVariant,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        '\$${item.total.toStringAsFixed(2)}',
                                        style: theme.textTheme.bodyLarge
                                            ?.copyWith(
                                              fontWeight: FontWeight.w800,
                                              color: cs.primary,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: cs.primary.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: cs.primary.withOpacity(0.20),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _isArabic ? 'المجموع' : 'Total',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Text(
                              '\$${order.total.toStringAsFixed(2)}',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w900,
                                color: cs.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PharmacyDetailsScreen(
                                  pharmacyId: order.pharmacyId,
                                  pharmacyName: order.pharmacyName,
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.storefront_outlined),
                          label: Text(
                            _isArabic ? 'عرض الصيدلية' : 'View Pharmacy',
                          ),
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.isArabic,
    required this.totalOrders,
    required this.pendingCount,
    required this.preparingCount,
    required this.readyCount,
    required this.completedCount,
    required this.colorScheme,
  });

  final bool isArabic;
  final int totalOrders;
  final int pendingCount;
  final int preparingCount;
  final int readyCount;
  final int completedCount;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          colors: [colorScheme.primary, colorScheme.secondary],
        ),
        boxShadow: [
          BoxShadow(
            blurRadius: 24,
            offset: const Offset(0, 12),
            color: colorScheme.primary.withOpacity(0.20),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.receipt_long_rounded, color: colorScheme.onPrimary),
              const SizedBox(width: 10),
              Text(
                isArabic ? 'طلباتي' : 'My Orders',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: colorScheme.onPrimary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            isArabic
                ? 'تابع كل طلبات العملاء من مكان واحد'
                : 'Track all customer orders in one place',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onPrimary.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _StatPill(
                label: isArabic ? 'الإجمالي' : 'Total',
                value: totalOrders.toString(),
                colorScheme: colorScheme,
              ),
              _StatPill(
                label: isArabic ? 'قيد الانتظار' : 'Pending',
                value: pendingCount.toString(),
                colorScheme: colorScheme,
              ),
              _StatPill(
                label: isArabic ? 'قيد التحضير' : 'Preparing',
                value: preparingCount.toString(),
                colorScheme: colorScheme,
              ),
              _StatPill(
                label: isArabic ? 'جاهز' : 'Ready',
                value: readyCount.toString(),
                colorScheme: colorScheme,
              ),
              _StatPill(
                label: isArabic ? 'مكتمل' : 'Completed',
                value: completedCount.toString(),
                colorScheme: colorScheme,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({
    required this.label,
    required this.value,
    required this.colorScheme,
  });

  final String label;
  final String value;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.18)),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          color: colorScheme.onPrimary,
          fontWeight: FontWeight.w700,
          fontSize: 12.5,
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.colorScheme,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final ColorScheme colorScheme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? colorScheme.primary : colorScheme.surface,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.outlineVariant,
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isSelected
                    ? colorScheme.onPrimary
                    : colorScheme.onSurface,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({
    required this.order,
    required this.colorScheme,
    required this.isArabic,
    required this.onTap,
  });

  final UserOrder order;
  final ColorScheme colorScheme;
  final bool isArabic;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        order.pharmacyName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                    _StatusBadge(
                      status: order.status,
                      colorScheme: colorScheme,
                      isArabic: isArabic,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  '#${order.id}',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(
                      Icons.shopping_bag_outlined,
                      size: 18,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${order.items.length} ${isArabic ? 'منتج' : 'items'}',
                      style: TextStyle(
                        fontSize: 13,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '\$${order.total.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.status,
    required this.colorScheme,
    required this.isArabic,
  });

  final String status;
  final ColorScheme colorScheme;
  final bool isArabic;

  Color get _badgeColor {
    switch (status) {
      case 'pending':
        return colorScheme.primary;
      case 'preparing':
        return Colors.orange;
      case 'ready':
        return Colors.green;
      case 'completed':
        return Colors.teal;
      case 'cancelled':
        return colorScheme.error;
      default:
        return colorScheme.onSurfaceVariant;
    }
  }

  String get _label {
    switch (status) {
      case 'pending':
        return isArabic ? 'قيد الانتظار' : 'Pending';
      case 'preparing':
        return isArabic ? 'قيد التحضير' : 'Preparing';
      case 'ready':
        return isArabic ? 'جاهز' : 'Ready';
      case 'completed':
        return isArabic ? 'مكتمل' : 'Completed';
      case 'cancelled':
        return isArabic ? 'ملغي' : 'Cancelled';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _badgeColor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        _label,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w800,
          color: _badgeColor,
        ),
      ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  const _DetailCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 15.5,
              fontWeight: FontWeight.w800,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.colorScheme,
  });

  final IconData icon;
  final String label;
  final String value;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: colorScheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
