import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../core/models/pharmacy_models.dart';
import '../../core/service/auth_service.dart';
import '../../core/service/firestore_service.dart';

class PharmacyCategoriesScreen extends StatefulWidget {
  const PharmacyCategoriesScreen({super.key});

  @override
  State<PharmacyCategoriesScreen> createState() =>
      _PharmacyCategoriesScreenState();
}

class _PharmacyCategoriesScreenState extends State<PharmacyCategoriesScreen>
    with AutomaticKeepAliveClientMixin {
  late final String _uid = AuthService.currentUser?.uid ?? '';
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _stream = _uid.isEmpty
      ? const Stream.empty()
      : FirestoreService.categoriesStream(_uid);

  @override
  bool get wantKeepAlive => true;

  Future<void> _showCategorySheet({PharmacyCategory? existing}) async {
    final isEdit = existing != null;
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    final formKey = GlobalKey<FormState>();
    final nameAr = TextEditingController(text: existing?.nameAr ?? '');
    final nameEn = TextEditingController(text: existing?.nameEn ?? '');
    final imageUrl = TextEditingController(text: existing?.imageUrl ?? '');

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
                    isEdit
                        ? (isAr ? 'تعديل الكاتجوري' : 'Edit Category')
                        : (isAr ? 'إضافة كاتجوري' : 'Add Category'),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 18),
                  _InputField(
                    controller: nameAr,
                    label: isAr ? 'الاسم بالعربية' : 'Name in Arabic',
                    validator: (value) {
                      if ((value ?? '').trim().isEmpty) {
                        return isAr
                            ? 'اكتب الاسم بالعربية'
                            : 'Enter Arabic name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  _InputField(
                    controller: nameEn,
                    label: isAr ? 'الاسم بالإنجليزي' : 'Name in English',
                    validator: (value) {
                      if ((value ?? '').trim().isEmpty) {
                        return isAr
                            ? 'اكتب الاسم بالإنجليزي'
                            : 'Enter English name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  _InputField(
                    controller: imageUrl,
                    label: isAr ? 'رابط الصورة' : 'Image URL',
                    keyboardType: TextInputType.url,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      icon: Icon(
                        isEdit ? Icons.save_rounded : Icons.add_rounded,
                      ),
                      onPressed: () async {
                        if (!(formKey.currentState?.validate() ?? false))
                          return;

                        final category = PharmacyCategory(
                          id:
                              existing?.id ??
                              FirebaseFirestore.instance
                                  .collection('tmp')
                                  .doc()
                                  .id,
                          nameAr: nameAr.text.trim(),
                          nameEn: nameEn.text.trim(),
                          imageUrl: imageUrl.text.trim(),
                          createdAt: existing?.createdAt ?? DateTime.now(),
                        );

                        if (isEdit) {
                          await FirestoreService.updateCategory(
                            uid: _uid,
                            category: category,
                          );
                        } else {
                          await FirestoreService.addCategory(
                            uid: _uid,
                            category: category,
                          );
                        }

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
  }

  Widget _image(String url, ColorScheme cs) {
    if (url.trim().isEmpty || !url.startsWith('http')) {
      return Center(
        child: Icon(Icons.category_rounded, color: cs.primary, size: 34),
      );
    }

    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) {
        return Center(
          child: Icon(Icons.broken_image_rounded, color: cs.primary, size: 34),
        );
      },
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return Center(
          child: CircularProgressIndicator(
            strokeWidth: 2.4,
            value: progress.expectedTotalBytes == null
                ? null
                : progress.cumulativeBytesLoaded / progress.expectedTotalBytes!,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(isAr ? 'الكاتجوري' : 'Categories'),
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

                final docs = snapshot.data!.docs;

                if (docs.isEmpty) {
                  return _EmptyState(
                    isAr: isAr,
                    onAdd: () => _showCategorySheet(),
                  );
                }

                return CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                        child: _HeaderCard(
                          title: isAr ? 'تنظيم سريع' : 'Fast organization',
                          subtitle: isAr
                              ? 'أضف وحرر الكاتجوريز بشكل أنيق وسهل'
                              : 'Manage categories in a clean and simple way',
                          count: docs.length,
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      sliver: SliverGrid(
                        gridDelegate:
                            const SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 360,
                              mainAxisExtent: 310,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                            ),
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final category = PharmacyCategory.fromMap(
                            docs[index].data(),
                          );

                          return _CategoryCard(
                            category: category,
                            isAr: isAr,
                            imageBuilder: () => _image(category.imageUrl, cs),
                            onEdit: () =>
                                _showCategorySheet(existing: category),
                            onDelete: () async {
                              await FirestoreService.deleteCategory(
                                uid: _uid,
                                categoryId: category.id,
                              );
                            },
                          );
                        }, childCount: docs.length),
                      ),
                    ),
                  ],
                );
              },
            ),
      floatingActionButton: _uid.isEmpty
          ? null
          : FloatingActionButton.extended(
              heroTag: 'pharmacy_categories_fab',
              onPressed: _showCategorySheet,
              icon: const Icon(Icons.add_rounded),
              label: Text(isAr ? 'إضافة' : 'Add'),
            ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.title,
    required this.subtitle,
    required this.count,
  });

  final String title;
  final String subtitle;
  final int count;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [cs.primary.withOpacity(0.96), cs.primary.withOpacity(0.72)],
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.white.withOpacity(0.18),
            child: Icon(Icons.category_rounded, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.category,
    required this.isAr,
    required this.imageBuilder,
    required this.onEdit,
    required this.onDelete,
  });

  final PharmacyCategory category;
  final bool isAr;
  final Widget Function() imageBuilder;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final title = category.nameAr.isEmpty
        ? category.nameEn
        : '${category.nameAr}${category.nameEn.isEmpty ? '' : ' / ${category.nameEn}'}';

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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(color: cs.primary.withOpacity(0.06)),
                  imageBuilder(),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: PopupMenuButton<String>(
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.32),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.more_horiz_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      onSelected: (value) {
                        if (value == 'edit') onEdit();
                        if (value == 'delete') onDelete();
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'edit',
                          child: Text(isAr ? 'تعديل' : 'Edit'),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Text(isAr ? 'حذف' : 'Delete'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    category.id,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: onEdit,
                          child: Text(isAr ? 'تعديل' : 'Edit'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      IconButton.filledTonal(
                        onPressed: onDelete,
                        icon: const Icon(Icons.delete_outline_rounded),
                      ),
                    ],
                  ),
                ],
              ),
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
    this.keyboardType,
  });

  final TextEditingController controller;
  final String label;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(labelText: label),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.isAr, required this.onAdd});

  final bool isAr;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.category_outlined, size: 72, color: cs.primary),
            const SizedBox(height: 14),
            Text(
              isAr ? 'لا توجد كاتجوريز بعد' : 'No categories yet',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              isAr
                  ? 'ابدأ بإضافة أول كاتجوري بشكل مرتب وجميل'
                  : 'Start by adding your first category',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded),
              label: Text(isAr ? 'إضافة كاتجوري' : 'Add Category'),
            ),
          ],
        ),
      ),
    );
  }
}
