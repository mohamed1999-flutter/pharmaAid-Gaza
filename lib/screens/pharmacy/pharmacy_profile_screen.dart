import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../core/service/auth_service.dart';
import '../../core/service/firestore_service.dart';

class PharmacyProfileScreen extends StatefulWidget {
  const PharmacyProfileScreen({super.key});

  @override
  State<PharmacyProfileScreen> createState() => _PharmacyProfileScreenState();
}

class _PharmacyProfileScreenState extends State<PharmacyProfileScreen>
    with AutomaticKeepAliveClientMixin {
  late final String _uid = AuthService.currentUser?.uid ?? '';
  late final Stream<DocumentSnapshot<Map<String, dynamic>>> _stream =
      _uid.isEmpty
      ? const Stream.empty()
      : FirestoreService.pharmacyStream(_uid);

  @override
  bool get wantKeepAlive => true;

  Future<void> _showEditSheet(Map<String, dynamic> data) async {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final formKey = GlobalKey<FormState>();

    final name = TextEditingController(text: (data['name'] ?? '').toString());
    final address = TextEditingController(
      text: (data['address'] ?? '').toString(),
    );
    final location = TextEditingController(
      text: (data['location'] ?? '').toString(),
    );
    final imageUrl = TextEditingController(
      text: (data['imageUrl'] ?? '').toString(),
    );

    try {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        builder: (sheetContext) {
          final bottomInset = MediaQuery.of(sheetContext).viewInsets.bottom;

          return Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 16 + bottomInset),
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isAr ? 'تعديل بيانات الصيدلية' : 'Edit pharmacy info',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 18),
                    _InputField(
                      controller: name,
                      label: isAr ? 'اسم الصيدلية' : 'Pharmacy name',
                      validator: (value) {
                        if ((value ?? '').trim().isEmpty) {
                          return isAr
                              ? 'اكتب اسم الصيدلية'
                              : 'Enter pharmacy name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    _InputField(
                      controller: address,
                      label: isAr ? 'العنوان' : 'Address',
                    ),
                    const SizedBox(height: 12),
                    _InputField(
                      controller: location,
                      label: isAr ? 'الموقع' : 'Location',
                    ),
                    const SizedBox(height: 12),
                    _InputField(
                      controller: imageUrl,
                      label: isAr ? 'رابط الصورة' : 'Image URL',
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        icon: const Icon(Icons.save_rounded),
                        onPressed: () async {
                          if (!(formKey.currentState?.validate() ?? false))
                            return;

                          await FirestoreService.updatePharmacyInfo(
                            uid: _uid,
                            data: {
                              'name': name.text.trim(),
                              'address': address.text.trim(),
                              'location': location.text.trim(),
                              'imageUrl': imageUrl.text.trim(),
                            },
                          );

                          if (mounted) Navigator.pop(sheetContext);
                        },
                        label: Text(isAr ? 'حفظ' : 'Save'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    } finally {
      name.dispose();
      address.dispose();
      location.dispose();
      imageUrl.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(isAr ? 'الملف الشخصي' : 'Profile'),
        centerTitle: false,
      ),
      body: _uid.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
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

                final data = snapshot.data!.data();
                if (data == null) {
                  return _EmptyProfileState(
                    isAr: isAr,
                    onReload: () => setState(() {}),
                  );
                }

                final name = (data['name'] ?? '—').toString();
                final ownerName = (data['ownerName'] ?? '—').toString();
                final email = (data['email'] ?? '—').toString();
                final address = (data['address'] ?? '—').toString();
                final location = (data['location'] ?? '—').toString();
                final imageUrl = (data['imageUrl'] ?? '').toString();

                final statsStream = _profileStatsStream();

                return CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                        child: _ProfileHeroCard(
                          isAr: isAr,
                          name: name,
                          ownerName: ownerName,
                          email: email,
                          imageUrl: imageUrl,
                          onEdit: () => _showEditSheet(data),
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                        child: Text(
                          isAr ? 'معلومات أساسية' : 'Basic info',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate.fixed([
                          _InfoTile(
                            label: isAr ? 'الاسم' : 'Name',
                            value: name,
                          ),
                          const SizedBox(height: 10),
                          _InfoTile(
                            label: isAr ? 'اسم المالك' : 'Owner',
                            value: ownerName,
                          ),
                          const SizedBox(height: 10),
                          _InfoTile(
                            label: isAr ? 'البريد الإلكتروني' : 'Email',
                            value: email,
                          ),
                          const SizedBox(height: 10),
                          _InfoTile(
                            label: isAr ? 'العنوان' : 'Address',
                            value: address,
                          ),
                          const SizedBox(height: 10),
                          _InfoTile(
                            label: isAr ? 'الموقع' : 'Location',
                            value: location,
                          ),
                        ]),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
                        child: Text(
                          isAr ? 'إحصائيات سريعة' : 'Quick stats',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: StreamBuilder<_ProfileStats>(
                          stream: statsStream,
                          builder: (context, statsSnapshot) {
                            final stats =
                                statsSnapshot.data ?? const _ProfileStats();

                            return GridView.count(
                              crossAxisCount: 2,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                              childAspectRatio: 1.9,
                              children: [
                                _StatCard(
                                  title: isAr ? 'الكاتجوريز' : 'Categories',
                                  value: stats.categories,
                                  icon: Icons.category_rounded,
                                ),
                                _StatCard(
                                  title: isAr ? 'الأدوية' : 'Medicines',
                                  value: stats.medicines,
                                  icon: Icons.medication_rounded,
                                ),
                                _StatCard(
                                  title: isAr ? 'الطلبات' : 'Orders',
                                  value: stats.orders,
                                  icon: Icons.receipt_long_rounded,
                                ),
                                _StatCard(
                                  title: isAr ? 'الحالة' : 'Status',
                                  value: stats.orders > 0 ? 1 : 0,
                                  icon: Icons.verified_rounded,
                                  valueLabel: stats.orders > 0
                                      ? (isAr ? 'نشط' : 'Active')
                                      : (isAr ? 'فارغ' : 'Empty'),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 18)),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        child: Row(
                          children: [
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: () => _showEditSheet(data),
                                icon: const Icon(Icons.edit_rounded),
                                label: Text(
                                  isAr ? 'تعديل البيانات' : 'Edit info',
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                minimumSize: Size.zero,
                              ),
                              onPressed: () => AuthService.signOut(),
                              icon: const Icon(Icons.logout_rounded),
                              label: Text(isAr ? 'خروج' : 'Logout'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }

  Stream<_ProfileStats> _profileStatsStream() async* {
    if (_uid.isEmpty) {
      yield const _ProfileStats();
      return;
    }

    final categories = await FirestoreService.categoriesStream(_uid).first;
    final medicines = await FirestoreService.medicinesStream(_uid).first;
    final orders = await FirestoreService.ordersStream(_uid).first;

    yield _ProfileStats(
      categories: categories.docs.length,
      medicines: medicines.docs.length,
      orders: orders.docs.length,
    );
  }
}

class _ProfileHeroCard extends StatelessWidget {
  const _ProfileHeroCard({
    required this.isAr,
    required this.name,
    required this.ownerName,
    required this.email,
    required this.imageUrl,
    required this.onEdit,
  });

  final bool isAr;
  final String name;
  final String ownerName;
  final String email;
  final String imageUrl;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [cs.primary.withOpacity(0.96), cs.primary.withOpacity(0.72)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: cs.primary.withOpacity(0.15),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Container(
              width: 84,
              height: 84,
              color: Colors.white.withOpacity(0.16),
              child: imageUrl.startsWith('http')
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.local_pharmacy_rounded,
                        color: Colors.white,
                        size: 40,
                      ),
                    )
                  : const Icon(
                      Icons.local_pharmacy_rounded,
                      color: Colors.white,
                      size: 40,
                    ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  isAr ? 'المالك: $ownerName' : 'Owner: $ownerName',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.92),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.86),
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          IconButton.filled(
            onPressed: onEdit,
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.16),
            ),
            icon: const Icon(Icons.edit_rounded, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: cs.primary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
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
    this.valueLabel,
  });

  final String title;
  final int value;
  final IconData icon;
  final String? valueLabel;

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
                  valueLabel ?? '$value',
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

class _EmptyProfileState extends StatelessWidget {
  const _EmptyProfileState({required this.isAr, required this.onReload});

  final bool isAr;
  final VoidCallback onReload;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person_off_rounded, size: 72, color: cs.primary),
            const SizedBox(height: 14),
            Text(
              isAr ? 'لا توجد بيانات للملف' : 'No profile data found',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              isAr
                  ? 'جرّب إعادة تحميل الصفحة أو تأكد من بيانات الصيدلية'
                  : 'Try reloading or check the pharmacy document',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onReload,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(isAr ? 'إعادة المحاولة' : 'Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  const _InputField({
    required this.controller,
    required this.label,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      decoration: InputDecoration(labelText: label),
    );
  }
}

class _ProfileStats {
  const _ProfileStats({
    this.categories = 0,
    this.medicines = 0,
    this.orders = 0,
  });

  final int categories;
  final int medicines;
  final int orders;
}
