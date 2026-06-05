import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../core/models/pharmacy_models.dart';
import '../../core/service/auth_service.dart';
import '../../core/service/firestore_service.dart';

/// Manages medicines with full product details.
/// Hint: Medicine entries are saved under pharmacies/{uid}/medicines.
class PharmacyMedicinesScreen extends StatefulWidget {
  const PharmacyMedicinesScreen({super.key});

  @override
  State<PharmacyMedicinesScreen> createState() =>
      _PharmacyMedicinesScreenState();
}

class _PharmacyMedicinesScreenState extends State<PharmacyMedicinesScreen> {
  String? _selectedCategoryId;

  Future<void> _showMedicineDialog(
    BuildContext context, {
    MedicineModel? existing,
    List<QueryDocumentSnapshot<Map<String, dynamic>>>? categories,
  }) async {
    final isEdit = existing != null;
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    final categoryId = TextEditingController(
      text: existing?.categoryId ?? (_selectedCategoryId ?? ''),
    );
    final nameAr = TextEditingController(text: existing?.nameAr ?? '');
    final nameEn = TextEditingController(text: existing?.nameEn ?? '');
    final descAr = TextEditingController(text: existing?.descriptionAr ?? '');
    final descEn = TextEditingController(text: existing?.descriptionEn ?? '');
    final composition = TextEditingController(
      text: existing?.composition ?? '',
    );
    final dosage = TextEditingController(text: existing?.dosage ?? '');
    final form = TextEditingController(text: existing?.form ?? '');
    final price = TextEditingController(text: existing?.price.toString() ?? '');
    final stock = TextEditingController(text: existing?.stock.toString() ?? '');
    final imageUrl = TextEditingController(text: existing?.imageUrl ?? '');

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            isEdit
                ? (isAr ? 'تعديل الدواء' : 'Edit Medicine')
                : (isAr ? 'إضافة دواء' : 'Add Medicine'),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _field(categoryId, isAr ? 'Category ID' : 'Category ID'),
                  const SizedBox(height: 10),
                  if (categories != null && categories.isNotEmpty)
                    DropdownButtonFormField<String>(
                      value: categoryId.text.isEmpty ? null : categoryId.text,
                      decoration: InputDecoration(
                        labelText: isAr
                            ? 'اختيار الكاتجوري'
                            : 'Choose category',
                        border: const OutlineInputBorder(),
                      ),
                      items: categories.map((doc) {
                        final data = doc.data();
                        return DropdownMenuItem(
                          value: data['id'] as String,
                          child: Text('${data['nameAr']} / ${data['nameEn']}'),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) categoryId.text = value;
                      },
                    ),
                  const SizedBox(height: 10),
                  _field(
                    nameAr,
                    isAr ? 'اسم الدواء بالعربية' : 'Medicine name AR',
                  ),
                  const SizedBox(height: 10),
                  _field(
                    nameEn,
                    isAr ? 'اسم الدواء بالإنجليزي' : 'Medicine name EN',
                  ),
                  const SizedBox(height: 10),
                  _field(descAr, isAr ? 'الوصف بالعربية' : 'Description AR'),
                  const SizedBox(height: 10),
                  _field(descEn, isAr ? 'الوصف بالإنجليزي' : 'Description EN'),
                  const SizedBox(height: 10),
                  _field(composition, isAr ? 'المكونات' : 'Composition'),
                  const SizedBox(height: 10),
                  _field(dosage, isAr ? 'الجرعة' : 'Dosage'),
                  const SizedBox(height: 10),
                  _field(form, isAr ? 'الشكل الدوائي' : 'Form'),
                  const SizedBox(height: 10),
                  _field(
                    price,
                    isAr ? 'السعر' : 'Price',
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 10),
                  _field(
                    stock,
                    isAr ? 'المخزون' : 'Stock',
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 10),
                  _field(
                    imageUrl,
                    isAr ? 'رابط صورة الدواء' : 'Medicine image URL',
                  ),
                ],
              ),
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

                final medicine = MedicineModel(
                  id:
                      existing?.id ??
                      FirebaseFirestore.instance.collection('tmp').doc().id,
                  categoryId: categoryId.text.trim(),
                  nameAr: nameAr.text.trim(),
                  nameEn: nameEn.text.trim(),
                  descriptionAr: descAr.text.trim(),
                  descriptionEn: descEn.text.trim(),
                  composition: composition.text.trim(),
                  dosage: dosage.text.trim(),
                  form: form.text.trim(),
                  price: double.tryParse(price.text.trim()) ?? 0,
                  stock: int.tryParse(stock.text.trim()) ?? 0,
                  imageUrl: imageUrl.text.trim().isEmpty
                      ? null
                      : imageUrl.text.trim(),
                  isAvailable: (existing?.isAvailable ?? true),
                  createdAt: existing?.createdAt ?? DateTime.now(),
                );

                if (isEdit) {
                  await FirestoreService.updateMedicine(
                    uid: uid,
                    medicine: medicine,
                  );
                } else {
                  await FirestoreService.addMedicine(
                    uid: uid,
                    medicine: medicine,
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

  Widget _field(
    TextEditingController controller,
    String label, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
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
        title: Text(isAr ? 'الأدوية' : 'Medicines'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              final catSnap = await FirebaseFirestore.instance
                  .collection('pharmacies')
                  .doc(uid)
                  .collection('categories')
                  .get();

              await _showMedicineDialog(context, categories: catSnap.docs);
            },
          ),
        ],
      ),
      body: StreamBuilder(
        stream: FirestoreService.medicinesStream(uid),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return Center(
              child: Text(
                isAr ? 'لا توجد أدوية بعد' : 'No medicines yet',
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
              final medicine = MedicineModel.fromMap(data);

              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: cs.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: cs.outlineVariant),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        width: 76,
                        height: 76,
                        color: cs.primary.withOpacity(0.1),
                        child: medicine.imageUrl == null
                            ? Icon(Icons.medical_services, color: cs.primary)
                            : Image.network(
                                medicine.imageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    Icon(Icons.broken_image, color: cs.primary),
                              ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${medicine.nameAr} / ${medicine.nameEn}',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            medicine.form,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${isAr ? 'السعر' : 'Price'}: ${medicine.price} | ${isAr ? 'المخزون' : 'Stock'}: ${medicine.stock}',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      onSelected: (value) async {
                        if (value == 'edit') {
                          final catSnap = await FirebaseFirestore.instance
                              .collection('pharmacies')
                              .doc(uid)
                              .collection('categories')
                              .get();
                          await _showMedicineDialog(
                            context,
                            existing: medicine,
                            categories: catSnap.docs,
                          );
                        } else if (value == 'delete') {
                          await FirestoreService.deleteMedicine(
                            uid: uid,
                            medicineId: medicine.id,
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
