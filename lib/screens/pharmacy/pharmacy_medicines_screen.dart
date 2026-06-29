import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../core/models/pharmacy_models.dart';
import '../../core/service/auth_service.dart';
import '../../core/service/firestore_service.dart';

class PharmacyMedicinesScreen extends StatefulWidget {
  const PharmacyMedicinesScreen({super.key});

  @override
  State<PharmacyMedicinesScreen> createState() =>
      _PharmacyMedicinesScreenState();
}

class _PharmacyMedicinesScreenState extends State<PharmacyMedicinesScreen>
    with AutomaticKeepAliveClientMixin {
  late final String _uid = AuthService.currentUser?.uid ?? '';

  String _query = '';
  String _selectedCategoryId = 'all';
  String _availabilityFilter = 'all'; // all | available | hidden

  @override
  bool get wantKeepAlive => true;

  Stream<QuerySnapshot<Map<String, dynamic>>> get _medicinesStream {
    if (_uid.isEmpty)
      return Stream<QuerySnapshot<Map<String, dynamic>>>.empty();
    return FirestoreService.medicinesStream(_uid);
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> get _categoriesStream {
    if (_uid.isEmpty)
      return Stream<QuerySnapshot<Map<String, dynamic>>>.empty();
    return FirestoreService.categoriesStream(_uid);
  }

  Future<void> _showMedicineSheet({
    required List<PharmacyCategory> categories,
    MedicineModel? existing,
  }) async {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    if (categories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isAr
                ? 'لازم تضيف كاتجوري أولاً قبل إضافة الأدوية'
                : 'Please create a category first before adding medicines',
          ),
        ),
      );
      return;
    }

    final formKey = GlobalKey<FormState>();

    final nameAr = TextEditingController(text: existing?.nameAr ?? '');
    final nameEn = TextEditingController(text: existing?.nameEn ?? '');
    final descriptionAr = TextEditingController(
      text: existing?.descriptionAr ?? '',
    );
    final descriptionEn = TextEditingController(
      text: existing?.descriptionEn ?? '',
    );
    final composition = TextEditingController(
      text: existing?.composition ?? '',
    );
    final dosage = TextEditingController(text: existing?.dosage ?? '');
    final form = TextEditingController(text: existing?.form ?? '');
    final price = TextEditingController(
      text: existing == null ? '' : existing.price.toString(),
    );
    final stock = TextEditingController(
      text: existing == null ? '' : existing.stock.toString(),
    );
    final imageUrl = TextEditingController(text: existing?.imageUrl ?? '');

    String selectedCategoryId = existing?.categoryId.isNotEmpty == true
        ? existing!.categoryId
        : categories.first.id;
    bool isAvailable = existing?.isAvailable ?? true;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (sheetContext) {
        final bottomInset = MediaQuery.of(sheetContext).viewInsets.bottom;
        final theme = Theme.of(sheetContext);
        final cs = theme.colorScheme;
        final isEdit = existing != null;

        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 16 + bottomInset),
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              isEdit
                                  ? (isAr ? 'تعديل دواء' : 'Edit Medicine')
                                  : (isAr ? 'إضافة دواء' : 'Add Medicine'),
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          _AvailabilityBadge(
                            isAvailable: isAvailable,
                            isAr: isAr,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isAr
                            ? 'املأ كل البيانات وحدد الكاتجوري بدقة'
                            : 'Fill every field and choose the category carefully',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 18),
                      _SheetField(
                        controller: nameAr,
                        label: isAr
                            ? 'اسم الدواء بالعربية'
                            : 'Medicine name AR',
                        validator: (value) {
                          if ((value ?? '').trim().isEmpty) {
                            return isAr
                                ? 'أدخل الاسم بالعربية'
                                : 'Enter Arabic name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      _SheetField(
                        controller: nameEn,
                        label: isAr
                            ? 'اسم الدواء بالإنجليزي'
                            : 'Medicine name EN',
                        validator: (value) {
                          if ((value ?? '').trim().isEmpty) {
                            return isAr
                                ? 'أدخل الاسم بالإنجليزي'
                                : 'Enter English name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: selectedCategoryId,
                        decoration: InputDecoration(
                          labelText: isAr
                              ? 'الكاتجوري (إجباري)'
                              : 'Category (required)',
                        ),
                        items: categories.map((category) {
                          final label = _categoryLabel(category, isAr);
                          return DropdownMenuItem<String>(
                            value: category.id,
                            child: Text(label),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          setModalState(() => selectedCategoryId = value);
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return isAr
                                ? 'اختر الكاتجوري'
                                : 'Please choose a category';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      _SheetField(
                        controller: composition,
                        label: isAr ? 'المادة الفعالة' : 'Composition',
                        validator: (value) {
                          if ((value ?? '').trim().isEmpty) {
                            return isAr
                                ? 'أدخل المادة الفعالة'
                                : 'Enter composition';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      _SheetField(
                        controller: dosage,
                        label: isAr ? 'الجرعة / الاستخدام' : 'Dosage',
                        validator: (value) {
                          if ((value ?? '').trim().isEmpty) {
                            return isAr ? 'أدخل الجرعة' : 'Enter dosage';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      _SheetField(
                        controller: form,
                        label: isAr ? 'الشكل الدوائي' : 'Form',
                        validator: (value) {
                          if ((value ?? '').trim().isEmpty) {
                            return isAr ? 'أدخل الشكل الدوائي' : 'Enter form';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _SheetField(
                              controller: price,
                              label: isAr ? 'السعر' : 'Price',
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              validator: (value) {
                                final parsed = double.tryParse(
                                  (value ?? '').trim(),
                                );
                                if (parsed == null || parsed < 0) {
                                  return isAr
                                      ? 'سعر غير صحيح'
                                      : 'Invalid price';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _SheetField(
                              controller: stock,
                              label: isAr ? 'المخزون' : 'Stock',
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                final parsed = int.tryParse(
                                  (value ?? '').trim(),
                                );
                                if (parsed == null || parsed < 0) {
                                  return isAr
                                      ? 'مخزون غير صحيح'
                                      : 'Invalid stock';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _SheetField(
                        controller: imageUrl,
                        label: isAr ? 'رابط الصورة' : 'Image URL',
                        keyboardType: TextInputType.url,
                      ),
                      const SizedBox(height: 12),
                      _SheetField(
                        controller: descriptionAr,
                        label: isAr ? 'الوصف بالعربية' : 'Description AR',
                        maxLines: 3,
                        validator: (value) {
                          if ((value ?? '').trim().isEmpty) {
                            return isAr
                                ? 'أدخل الوصف بالعربية'
                                : 'Enter Arabic description';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      _SheetField(
                        controller: descriptionEn,
                        label: isAr ? 'الوصف بالإنجليزي' : 'Description EN',
                        maxLines: 3,
                        validator: (value) {
                          if ((value ?? '').trim().isEmpty) {
                            return isAr
                                ? 'أدخل الوصف بالإنجليزي'
                                : 'Enter English description';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        value: isAvailable,
                        onChanged: (value) {
                          setModalState(() => isAvailable = value);
                        },
                        title: Text(isAr ? 'متاح للعرض' : 'Visible'),
                        subtitle: Text(
                          isAr
                              ? 'لو أغلقتها لن يختفي من قاعدة البيانات، فقط سيتم إخفاؤه'
                              : 'When turned off, the medicine is hidden but not deleted',
                        ),
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          icon: Icon(
                            isEdit ? Icons.save_rounded : Icons.add_rounded,
                          ),
                          onPressed: () async {
                            if (!(formKey.currentState?.validate() ?? false))
                              return;

                            final selectedCategory = categories.firstWhere(
                              (e) => e.id == selectedCategoryId,
                              orElse: () => categories.first,
                            );

                            final medicineId =
                                existing?.id ??
                                FirebaseFirestore.instance
                                    .collection('medicines')
                                    .doc()
                                    .id;

                            final medicine = MedicineModel(
                              id: medicineId,
                              categoryId: selectedCategory.id,
                              nameAr: nameAr.text.trim(),
                              nameEn: nameEn.text.trim(),
                              descriptionAr: descriptionAr.text.trim(),
                              descriptionEn: descriptionEn.text.trim(),
                              composition: composition.text.trim(),
                              dosage: dosage.text.trim(),
                              form: form.text.trim(),
                              price: double.tryParse(price.text.trim()) ?? 0,
                              stock: int.tryParse(stock.text.trim()) ?? 0,
                              imageUrl: imageUrl.text.trim().isEmpty
                                  ? null
                                  : imageUrl.text.trim(),
                              isAvailable: isAvailable,
                              createdAt: existing?.createdAt ?? DateTime.now(),
                            );

                            if (existing == null) {
                              await FirestoreService.addMedicine(
                                uid: _uid,
                                medicine: medicine,
                              );
                            } else {
                              await FirestoreService.updateMedicine(
                                uid: _uid,
                                medicine: medicine,
                              );
                            }

                            if (mounted) {
                              Navigator.pop(sheetContext);
                            }
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
      },
    );
  }

  Future<void> _confirmDelete({required MedicineModel medicine}) async {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(isAr ? 'حذف الدواء' : 'Delete medicine'),
          content: Text(
            isAr
                ? 'هل أنت متأكد أنك تريد حذف هذا الدواء نهائيًا؟'
                : 'Are you sure you want to delete this medicine permanently?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(isAr ? 'إلغاء' : 'Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(isAr ? 'حذف' : 'Delete'),
            ),
          ],
        );
      },
    );

    if (ok != true) return;

    await FirestoreService.deleteMedicine(uid: _uid, medicineId: medicine.id);
  }

  Future<void> _toggleVisibility(MedicineModel medicine) async {
    final updated = MedicineModel(
      id: medicine.id,
      categoryId: medicine.categoryId,
      nameAr: medicine.nameAr,
      nameEn: medicine.nameEn,
      descriptionAr: medicine.descriptionAr,
      descriptionEn: medicine.descriptionEn,
      composition: medicine.composition,
      dosage: medicine.dosage,
      form: medicine.form,
      price: medicine.price,
      stock: medicine.stock,
      imageUrl: medicine.imageUrl,
      isAvailable: !medicine.isAvailable,
      createdAt: medicine.createdAt,
    );

    await FirestoreService.updateMedicine(uid: _uid, medicine: updated);
  }

  String _categoryLabel(PharmacyCategory category, bool isAr) {
    final ar = category.nameAr.trim();
    final en = category.nameEn.trim();

    if (isAr) {
      if (ar.isNotEmpty && en.isNotEmpty) return '$ar / $en';
      if (ar.isNotEmpty) return ar;
      return en;
    } else {
      if (en.isNotEmpty && ar.isNotEmpty) return '$en / $ar';
      if (en.isNotEmpty) return en;
      return ar;
    }
  }

  String _medicineTitle(MedicineModel medicine, bool isAr) {
    if (isAr) {
      if (medicine.nameAr.trim().isNotEmpty) return medicine.nameAr;
      return medicine.nameEn;
    } else {
      if (medicine.nameEn.trim().isNotEmpty) return medicine.nameEn;
      return medicine.nameAr;
    }
  }

  String _medicineSubtitle(MedicineModel medicine, bool isAr) {
    if (isAr) {
      if (medicine.nameEn.trim().isNotEmpty &&
          medicine.nameEn != medicine.nameAr) {
        return medicine.nameEn;
      }
      return medicine.form;
    } else {
      if (medicine.nameAr.trim().isNotEmpty &&
          medicine.nameAr != medicine.nameEn) {
        return medicine.nameAr;
      }
      return medicine.form;
    }
  }

  Widget _image(String? url, ColorScheme cs) {
    final value = (url ?? '').trim();

    if (value.isEmpty || !value.startsWith('http')) {
      return Center(
        child: Icon(Icons.medication_rounded, color: cs.primary, size: 36),
      );
    }

    return Image.network(
      value,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) {
        return Center(
          child: Icon(Icons.broken_image_rounded, color: cs.primary, size: 36),
        );
      },
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return Center(
          child: CircularProgressIndicator(
            strokeWidth: 2.2,
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

    if (_uid.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _categoriesStream,
        builder: (context, categoriesSnapshot) {
          if (categoriesSnapshot.hasError) {
            print('🔥 Firestore Stream Error (Medicines - Categories): ${categoriesSnapshot.error}');
            return Scaffold(
              appBar: AppBar(title: Text(isAr ? 'الأدوية' : 'Medicines')),
              body: Center(
                child: Text(isAr ? 'حدث خطأ: ${categoriesSnapshot.error}' : 'Something went wrong'),
              ),
            );
          }

          if (!categoriesSnapshot.hasData) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          final categories = categoriesSnapshot.data!.docs.map((doc) {
            final data = doc.data();
            return PharmacyCategory(
              id: (data['id'] ?? doc.id).toString(),
              nameAr: (data['nameAr'] ?? '').toString(),
              nameEn: (data['nameEn'] ?? '').toString(),
              imageUrl: (data['imageUrl'] ?? '').toString(),
              createdAt:
                  (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
            );
          }).toList();

          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _medicinesStream,
            builder: (context, medicinesSnapshot) {
              if (medicinesSnapshot.hasError) {
                print('🔥 Firestore Stream Error (Medicines): ${medicinesSnapshot.error}');
                return Scaffold(
                  appBar: AppBar(title: Text(isAr ? 'الأدوية' : 'Medicines')),
                  body: Center(
                    child: Text(isAr ? 'حدث خطأ: ${medicinesSnapshot.error}' : 'Something went wrong'),
                  ),
                );
              }

              if (!medicinesSnapshot.hasData) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              final docs = medicinesSnapshot.data!.docs;
              final medicines = docs
                  .map((doc) => MedicineModel.fromMap(doc.data()))
                  .toList();

              final filtered = medicines.where((medicine) {
                final categoryMatch = _selectedCategoryId == 'all'
                    ? true
                    : medicine.categoryId == _selectedCategoryId;

                final availabilityMatch = switch (_availabilityFilter) {
                  'available' => medicine.isAvailable,
                  'hidden' => !medicine.isAvailable,
                  _ => true,
                };

                final q = _query.trim().toLowerCase();

                final searchMatch = q.isEmpty
                    ? true
                    : _medicineTitle(
                            medicine,
                            true,
                          ).toLowerCase().contains(q) ||
                          _medicineTitle(
                            medicine,
                            false,
                          ).toLowerCase().contains(q) ||
                          medicine.composition.toLowerCase().contains(q) ||
                          medicine.dosage.toLowerCase().contains(q) ||
                          medicine.form.toLowerCase().contains(q);

                return categoryMatch && availabilityMatch && searchMatch;
              }).toList();

              final totalCount = medicines.length;
              final availableCount = medicines
                  .where((e) => e.isAvailable)
                  .length;
              final hiddenCount = medicines.where((e) => !e.isAvailable).length;

              return Scaffold(
                appBar: AppBar(
                  title: Text(isAr ? 'الأدوية' : 'Medicines'),
                  centerTitle: false,
                  actions: [
                    IconButton(
                      tooltip: isAr ? 'إضافة دواء' : 'Add medicine',
                      onPressed: categories.isEmpty
                          ? null
                          : () => _showMedicineSheet(categories: categories),
                      icon: const Icon(Icons.add_rounded),
                    ),
                    const SizedBox(width: 4),
                  ],
                ),
                body: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                        child: _MedicinesHeader(
                          isAr: isAr,
                          query: _query,
                          onQueryChanged: (value) {
                            setState(() => _query = value);
                          },
                          totalCount: totalCount,
                          availableCount: availableCount,
                          hiddenCount: hiddenCount,
                          categoriesCount: categories.length,
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isAr ? 'الكاتجوري' : 'Categories',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              height: 42,
                              child: ListView(
                                scrollDirection: Axis.horizontal,
                                children: [
                                  _FilterChipItem(
                                    label: isAr ? 'الكل' : 'All',
                                    selected: _selectedCategoryId == 'all',
                                    onTap: () {
                                      setState(
                                        () => _selectedCategoryId = 'all',
                                      );
                                    },
                                  ),
                                  const SizedBox(width: 8),
                                  ...categories.map((category) {
                                    final selected =
                                        _selectedCategoryId == category.id;
                                    return Padding(
                                      padding: const EdgeInsets.only(right: 8),
                                      child: _FilterChipItem(
                                        label: _categoryLabel(category, isAr),
                                        selected: selected,
                                        onTap: () {
                                          setState(() {
                                            _selectedCategoryId = category.id;
                                          });
                                        },
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              isAr ? 'الحالة' : 'Availability',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _FilterChipItem(
                                  label: isAr ? 'الكل' : 'All',
                                  selected: _availabilityFilter == 'all',
                                  onTap: () {
                                    setState(() => _availabilityFilter = 'all');
                                  },
                                ),
                                _FilterChipItem(
                                  label: isAr ? 'ظاهر' : 'Visible',
                                  selected: _availabilityFilter == 'available',
                                  onTap: () {
                                    setState(
                                      () => _availabilityFilter = 'available',
                                    );
                                  },
                                ),
                                _FilterChipItem(
                                  label: isAr ? 'مخفي' : 'Hidden',
                                  selected: _availabilityFilter == 'hidden',
                                  onTap: () {
                                    setState(
                                      () => _availabilityFilter = 'hidden',
                                    );
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 8)),
                    if (categories.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: _EmptyState(
                          isAr: isAr,
                          icon: Icons.category_outlined,
                          title: isAr
                              ? 'لا توجد كاتجوريز'
                              : 'No categories found',
                          subtitle: isAr
                              ? 'لا يمكن إضافة دواء بدون كاتجوري'
                              : 'You cannot add medicines without categories',
                          actionLabel: isAr
                              ? 'اذهب للكاتجوريز'
                              : 'Go to categories',
                          onAction: () {},
                        ),
                      )
                    else if (filtered.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: _EmptyState(
                          isAr: isAr,
                          icon: Icons.medication_outlined,
                          title: isAr ? 'لا توجد أدوية' : 'No medicines found',
                          subtitle: isAr
                              ? 'جرّب تغيير البحث أو الفلتر'
                              : 'Try changing search or filters',
                          actionLabel: isAr ? 'إضافة دواء' : 'Add medicine',
                          onAction: () =>
                              _showMedicineSheet(categories: categories),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        sliver: SliverList.separated(
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final medicine = filtered[index];
                            final category = categories.firstWhere(
                              (c) => c.id == medicine.categoryId,
                              orElse: () => categories.first,
                            );

                            return _MedicineCard(
                              medicine: medicine,
                              categoryLabel: _categoryLabel(category, isAr),
                              title: _medicineTitle(medicine, isAr),
                              subtitle: _medicineSubtitle(medicine, isAr),
                              isAr: isAr,
                              imageBuilder: () => _image(medicine.imageUrl, cs),
                              onEdit: () => _showMedicineSheet(
                                categories: categories,
                                existing: medicine,
                              ),
                              onDelete: () =>
                                  _confirmDelete(medicine: medicine),
                              onToggleVisibility: () =>
                                  _toggleVisibility(medicine),
                            );
                          },
                        ),
                      ),
                  ],
                ),
                floatingActionButton: FloatingActionButton.extended(
                  heroTag: 'pharmacy_medicines_fab',
                  onPressed: categories.isEmpty
                      ? null
                      : () => _showMedicineSheet(categories: categories),
                  icon: const Icon(Icons.add_rounded),
                  label: Text(isAr ? 'إضافة' : 'Add'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _MedicinesHeader extends StatelessWidget {
  const _MedicinesHeader({
    required this.isAr,
    required this.query,
    required this.onQueryChanged,
    required this.totalCount,
    required this.availableCount,
    required this.hiddenCount,
    required this.categoriesCount,
  });

  final bool isAr;
  final String query;
  final ValueChanged<String> onQueryChanged;
  final int totalCount;
  final int availableCount;
  final int hiddenCount;
  final int categoriesCount;

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
            color: cs.primary.withOpacity(0.14),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isAr ? 'إدارة الأدوية' : 'Medicine management',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isAr
                ? 'إضافة وتعديل وإخفاء وحذف بشكل منظم وسريع'
                : 'Add, edit, hide and delete in a clean way',
            style: TextStyle(
              color: Colors.white.withOpacity(0.92),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            onChanged: onQueryChanged,
            controller: TextEditingController(text: query),
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: isAr ? 'ابحث عن دواء...' : 'Search medicine...',
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.75)),
              prefixIcon: const Icon(Icons.search_rounded, color: Colors.white),
              filled: true,
              fillColor: Colors.white.withOpacity(0.14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _MiniStat(
                  title: isAr ? 'الكل' : 'All',
                  value: totalCount,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MiniStat(
                  title: isAr ? 'ظاهر' : 'Visible',
                  value: availableCount,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _MiniStat(
                  title: isAr ? 'مخفي' : 'Hidden',
                  value: hiddenCount,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MiniStat(
                  title: isAr ? 'كاتجوريز' : 'Categories',
                  value: categoriesCount,
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

class _MedicineCard extends StatelessWidget {
  const _MedicineCard({
    required this.medicine,
    required this.categoryLabel,
    required this.title,
    required this.subtitle,
    required this.isAr,
    required this.imageBuilder,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleVisibility,
  });

  final MedicineModel medicine;
  final String categoryLabel;
  final String title;
  final String subtitle;
  final bool isAr;
  final Widget Function() imageBuilder;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleVisibility;

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
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Container(
                      width: 78,
                      height: 78,
                      color: cs.primary.withOpacity(0.08),
                      child: imageBuilder(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            PopupMenuButton<String>(
                              onSelected: (value) {
                                switch (value) {
                                  case 'edit':
                                    onEdit();
                                    break;
                                  case 'toggle':
                                    onToggleVisibility();
                                    break;
                                  case 'delete':
                                    onDelete();
                                    break;
                                }
                              },
                              itemBuilder: (context) => [
                                PopupMenuItem(
                                  value: 'edit',
                                  child: Text(isAr ? 'تعديل' : 'Edit'),
                                ),
                                PopupMenuItem(
                                  value: 'toggle',
                                  child: Text(
                                    medicine.isAvailable
                                        ? (isAr ? 'إخفاء' : 'Hide')
                                        : (isAr ? 'إظهار' : 'Show'),
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Text(isAr ? 'حذف' : 'Delete'),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _Tag(
                              text: categoryLabel,
                              icon: Icons.category_rounded,
                            ),
                            _Tag(
                              text: medicine.form,
                              icon: Icons.medical_services_outlined,
                            ),
                            _Tag(
                              text: medicine.isAvailable
                                  ? (isAr ? 'ظاهر' : 'Visible')
                                  : (isAr ? 'مخفي' : 'Hidden'),
                              icon: medicine.isAvailable
                                  ? Icons.visibility_rounded
                                  : Icons.visibility_off_rounded,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                medicine.descriptionAr.isNotEmpty
                    ? medicine.descriptionAr
                    : medicine.descriptionEn,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _InfoPill(
                      title: isAr ? 'السعر' : 'Price',
                      value: '${medicine.price} ₪',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _InfoPill(
                      title: isAr ? 'المخزون' : 'Stock',
                      value: medicine.stock.toString(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit_rounded),
                      label: Text(isAr ? 'تعديل' : 'Edit'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onToggleVisibility,
                      icon: Icon(
                        medicine.isAvailable
                            ? Icons.visibility_off_rounded
                            : Icons.visibility_rounded,
                      ),
                      label: Text(
                        medicine.isAvailable
                            ? (isAr ? 'إخفاء' : 'Hide')
                            : (isAr ? 'إظهار' : 'Show'),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.text, required this.icon});

  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: cs.primary),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: cs.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withOpacity(0.45),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _AvailabilityBadge extends StatelessWidget {
  const _AvailabilityBadge({required this.isAvailable, required this.isAr});

  final bool isAvailable;
  final bool isAr;

  @override
  Widget build(BuildContext context) {
    final color = isAvailable ? Colors.green : Colors.red;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        isAvailable ? (isAr ? 'ظاهر' : 'Visible') : (isAr ? 'مخفي' : 'Hidden'),
        style: TextStyle(
          color: color.shade700,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _SheetField extends StatelessWidget {
  const _SheetField({
    required this.controller,
    required this.label,
    this.validator,
    this.keyboardType,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String label;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(labelText: label),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.isAr,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onAction,
  });

  final bool isAr;
  final IconData icon;
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 72, color: cs.primary),
            const SizedBox(height: 14),
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.add_rounded),
              label: Text(actionLabel),
            ),
          ],
        ),
      ),
    );
  }
}
