import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../core/models/pharmacy_models.dart';
import '../../core/service/auth_service.dart';
import '../../core/service/firestore_service.dart';

/// Manages pharmacy categories.
class PharmacyCategoriesScreen extends StatelessWidget {
  const PharmacyCategoriesScreen({super.key});

  Future<void> _showCategoryDialog(
    BuildContext context, {
    PharmacyCategory? existing,
  }) async {
    final isEdit = existing != null;
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    final nameAr = TextEditingController(text: existing?.nameAr ?? '');
    final nameEn = TextEditingController(text: existing?.nameEn ?? '');
    final imageUrl = TextEditingController(text: existing?.imageUrl ?? '');

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            isEdit
                ? (isAr ? 'تعديل الكاتجوري' : 'Edit Category')
                : (isAr ? 'إضافة كاتجوري' : 'Add Category'),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameAr,
                  decoration: InputDecoration(
                    labelText: isAr ? 'الاسم بالعربية' : 'Name AR',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameEn,
                  decoration: InputDecoration(
                    labelText: isAr ? 'الاسم بالإنجليزي' : 'Name EN',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: imageUrl,
                  decoration: InputDecoration(
                    labelText: isAr ? 'رابط الصورة' : 'Image URL',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(isAr ? 'إلغاء' : 'Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final uid = AuthService.currentUser!.uid;

                final category = PharmacyCategory(
                  id:
                      existing?.id ??
                      FirebaseFirestore.instance.collection('tmp').doc().id,
                  nameAr: nameAr.text.trim(),
                  nameEn: nameEn.text.trim(),
                  imageUrl: imageUrl.text.trim(),
                  createdAt: existing?.createdAt ?? DateTime.now(),
                );

                if (isEdit) {
                  await FirestoreService.updateCategory(
                    uid: uid,
                    category: category,
                  );
                } else {
                  await FirestoreService.addCategory(
                    uid: uid,
                    category: category,
                  );
                }

                if (context.mounted) Navigator.pop(dialogContext);
              },
              child: Text(isAr ? 'حفظ' : 'Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = AuthService.currentUser!.uid;
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(isAr ? 'الكاتجوري' : 'Categories'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showCategoryDialog(context),
          ),
        ],
      ),
      body: StreamBuilder(
        stream: FirestoreService.categoriesStream(uid),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text('Error'));
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

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final data = docs[index].data();
              final category = PharmacyCategory.fromMap(data);

              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: cs.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: cs.outlineVariant),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        width: 64,
                        height: 64,
                        color: cs.primary.withOpacity(0.12),
                        child: category.imageUrl.isEmpty
                            ? Icon(Icons.category, color: cs.primary)
                            : Image.network(
                                category.imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    Icon(Icons.broken_image, color: cs.primary),
                              ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${category.nameAr} / ${category.nameEn}',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            category.id,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      onSelected: (value) async {
                        if (value == 'edit') {
                          await _showCategoryDialog(
                            context,
                            existing: category,
                          );
                        } else if (value == 'delete') {
                          await FirestoreService.deleteCategory(
                            uid: uid,
                            categoryId: category.id,
                          );
                        }
                      },
                      itemBuilder: (_) => [
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
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
