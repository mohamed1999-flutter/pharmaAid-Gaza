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

class _PharmacyCategoriesScreenState extends State<PharmacyCategoriesScreen> {
  late final String _uid = AuthService.currentUser?.uid ?? '';
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _stream = _uid.isEmpty
      ? const Stream.empty()
      : FirestoreService.categoriesStream(_uid);

  Future<void> _showCategoryDialog(
    BuildContext context, {
    PharmacyCategory? existing,
  }) async {
    final isEdit = existing != null;
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    final nameAr = TextEditingController(text: existing?.nameAr ?? '');
    final nameEn = TextEditingController(text: existing?.nameEn ?? '');
    final imageUrl = TextEditingController(text: existing?.imageUrl ?? '');

    try {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          return Dialog(
            insetPadding: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
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
                    _field(
                      controller: nameAr,
                      label: isAr ? 'الاسم بالعربية' : 'Name AR',
                    ),
                    const SizedBox(height: 12),
                    _field(
                      controller: nameEn,
                      label: isAr ? 'الاسم بالإنجليزي' : 'Name EN',
                    ),
                    const SizedBox(height: 12),
                    _field(
                      controller: imageUrl,
                      label: isAr ? 'رابط الصورة' : 'Image URL',
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.pop(dialogContext),
                            child: Text(isAr ? 'إلغاء' : 'Cancel'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: FilledButton(
                            onPressed: () async {
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
                                createdAt:
                                    existing?.createdAt ?? DateTime.now(),
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

                              if (context.mounted) {
                                Navigator.pop(dialogContext);
                              }
                            },
                            child: Text(isAr ? 'حفظ' : 'Save'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    } finally {
      nameAr.dispose();
      nameEn.dispose();
      imageUrl.dispose();
    }
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(labelText: label),
    );
  }

  Widget _image(String url, ColorScheme cs) {
    if (url.trim().isEmpty || !url.startsWith('http')) {
      return Icon(Icons.category_rounded, color: cs.primary, size: 30);
    }

    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) {
        return Icon(Icons.broken_image_rounded, color: cs.primary, size: 30);
      },
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
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
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(isAr ? 'الكاتجوري' : 'Categories'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: _uid.isEmpty ? null : () => _showCategoryDialog(context),
          ),
        ],
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
                  return Center(
                    child: Text(
                      isAr ? 'لا توجد كاتجوريز بعد' : 'No categories yet',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  );
                }

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: docs.map((doc) {
                        final category = PharmacyCategory.fromMap(doc.data());

                        return SizedBox(
                          width: 260,
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: cs.surface,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: cs.outlineVariant),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(18),
                                  child: Container(
                                    height: 140,
                                    width: double.infinity,
                                    color: cs.primary.withOpacity(0.08),
                                    child: _image(category.imageUrl, cs),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  category.nameAr.isEmpty
                                      ? category.nameEn
                                      : '${category.nameAr} / ${category.nameEn}',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  category.id,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: cs.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: () => _showCategoryDialog(
                                          context,
                                          existing: category,
                                        ),
                                        child: Text(isAr ? 'تعديل' : 'Edit'),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    IconButton.filledTonal(
                                      onPressed: () async {
                                        await FirestoreService.deleteCategory(
                                          uid: _uid,
                                          categoryId: category.id,
                                        );
                                      },
                                      icon: const Icon(
                                        Icons.delete_outline_rounded,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                );
              },
            ),
      floatingActionButton: _uid.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _showCategoryDialog(context),
              icon: const Icon(Icons.add_rounded),
              label: Text(isAr ? 'إضافة' : 'Add'),
            ),
    );
  }
}
