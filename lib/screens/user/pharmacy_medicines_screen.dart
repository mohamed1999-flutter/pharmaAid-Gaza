import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../core/models/pharmacy_models.dart';
import '../../core/service/firestore_service.dart';
import 'medicine_details_screen.dart';

class PharmacyMedicinesScreen extends StatefulWidget {
  final String pharmacyId;
  final String pharmacyName;
  final String? pharmacyImageUrl;
  final String? categoryId;
  final String? categoryName;

  const PharmacyMedicinesScreen({
    super.key,
    required this.pharmacyId,
    required this.pharmacyName,
    this.pharmacyImageUrl,
    this.categoryId,
    this.categoryName,
  });

  @override
  State<PharmacyMedicinesScreen> createState() =>
      _PharmacyMedicinesScreenState();
}

class _PharmacyMedicinesScreenState extends State<PharmacyMedicinesScreen> {
  String? _selectedCategoryId;
  final TextEditingController _searchController = TextEditingController();

  _MedicineSort _sortMode = _MedicineSort.newest;

  bool get _isArabic => Localizations.localeOf(context).languageCode == 'ar';

  @override
  void initState() {
    super.initState();
    _selectedCategoryId = widget.categoryId;
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final direction = _isArabic ? TextDirection.rtl : TextDirection.ltr;

    return Directionality(
      textDirection: direction,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          centerTitle: true,
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: theme.scaffoldBackgroundColor,
          surfaceTintColor: Colors.transparent,
          title: Text(
            widget.categoryName ?? (_isArabic ? 'الأدوية' : 'Medicines'),
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: colorScheme.onSurface,
            ),
          ),
          leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.arrow_back_rounded, color: colorScheme.onSurface),
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: _SearchBar(
                  controller: _searchController,
                  isArabic: _isArabic,
                  colorScheme: colorScheme,
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: _SortPill(
                        colorScheme: colorScheme,
                        isArabic: _isArabic,
                        value: _sortMode,
                        onChanged: (mode) {
                          setState(() => _sortMode = mode);
                        },
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              SizedBox(
                height: 48,
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirestoreService.pharmacyCategoriesStream(
                    widget.pharmacyId,
                  ),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const SizedBox.shrink();
                    }

                    final categories = snapshot.data!.docs
                        .map(
                          (doc) => PharmacyCategory.fromMap(doc.data(), doc.id),
                        )
                        .toList();

                    return ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: categories.length + 1,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return _CategoryFilterChip(
                            label: _isArabic ? 'الكل' : 'All',
                            isSelected: _selectedCategoryId == null,
                            colorScheme: colorScheme,
                            onTap: () {
                              setState(() => _selectedCategoryId = null);
                            },
                          );
                        }

                        final category = categories[index - 1];
                        final name = _isArabic
                            ? category.nameAr
                            : category.nameEn;

                        return _CategoryFilterChip(
                          label: name,
                          isSelected: _selectedCategoryId == category.id,
                          colorScheme: colorScheme,
                          onTap: () {
                            setState(() => _selectedCategoryId = category.id);
                          },
                        );
                      },
                    );
                  },
                ),
              ),

              const SizedBox(height: 10),

              Expanded(
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirestoreService.pharmacyMedicinesStream(
                    widget.pharmacyId,
                    categoryId: _selectedCategoryId,
                  ),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          _isArabic ? 'حدث خطأ' : 'Error occurred',
                          style: TextStyle(color: colorScheme.error),
                        ),
                      );
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return _EmptyState(
                        icon: Icons.medication_outlined,
                        message: _isArabic
                            ? 'لا توجد أدوية متاحة'
                            : 'No medicines available',
                        colorScheme: colorScheme,
                      );
                    }

                    final entries = snapshot.data!.docs
                        .map(
                          (doc) => _MedicineEntry(
                            medicine: MedicineModel.fromMap(doc.data(), doc.id),
                            data: doc.data(),
                          ),
                        )
                        .toList();

                    final filtered = _filterAndSort(entries);

                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                          child: Row(
                            children: [
                              Text(
                                _isArabic
                                    ? 'عدد النتائج: ${filtered.length}'
                                    : '${filtered.length} results',
                                style: TextStyle(
                                  color: colorScheme.onSurfaceVariant,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const Spacer(),
                              if (_selectedCategoryId != null)
                                TextButton(
                                  onPressed: () {
                                    setState(() => _selectedCategoryId = null);
                                  },
                                  child: Text(
                                    _isArabic ? 'إلغاء الفلتر' : 'Clear filter',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: colorScheme.primary,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: filtered.isEmpty
                              ? _EmptyState(
                                  icon: Icons.search_off_rounded,
                                  message: _isArabic
                                      ? 'لا توجد نتائج مطابقة'
                                      : 'No matching results',
                                  colorScheme: colorScheme,
                                )
                              : GridView.builder(
                                  padding: const EdgeInsets.fromLTRB(
                                    16,
                                    0,
                                    16,
                                    16,
                                  ),
                                  physics: const BouncingScrollPhysics(),
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 2,
                                        mainAxisSpacing: 12,
                                        crossAxisSpacing: 12,
                                        childAspectRatio: 0.69,
                                      ),
                                  itemCount: filtered.length,
                                  itemBuilder: (context, index) {
                                    final entry = filtered[index];
                                    return _MedicineCard(
                                      entry: entry,
                                      colorScheme: colorScheme,
                                      isArabic: _isArabic,
                                      onTap: () {
                                        _showMedicineQuickSheet(
                                          context,
                                          entry,
                                          colorScheme,
                                        );
                                      },
                                    );
                                  },
                                ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<_MedicineEntry> _filterAndSort(List<_MedicineEntry> entries) {
    final term = _searchController.text.trim().toLowerCase();

    final filtered = term.isEmpty
        ? entries
        : entries.where((entry) {
            final medicine = entry.medicine;
            final extra = _pickString(entry.data, const [
              'description',
              'subtitle',
              'note',
              'usage',
              'indication',
              'activeIngredient',
            ]);

            return medicine.nameAr.toLowerCase().contains(term) ||
                medicine.nameEn.toLowerCase().contains(term) ||
                medicine.form.toLowerCase().contains(term) ||
                (extra != null && extra.toLowerCase().contains(term));
          }).toList();

    switch (_sortMode) {
      case _MedicineSort.newest:
        filtered.sort(
          (a, b) => b.medicine.createdAt.compareTo(a.medicine.createdAt),
        );
        return filtered;

      case _MedicineSort.priceLowHigh:
        filtered.sort((a, b) => a.medicine.price.compareTo(b.medicine.price));
        return filtered;

      case _MedicineSort.priceHighLow:
        filtered.sort((a, b) => b.medicine.price.compareTo(a.medicine.price));
        return filtered;

      case _MedicineSort.name:
        filtered.sort((a, b) {
          final aName = _isArabic ? a.medicine.nameAr : a.medicine.nameEn;
          final bName = _isArabic ? b.medicine.nameAr : b.medicine.nameEn;
          return aName.toLowerCase().compareTo(bName.toLowerCase());
        });
        return filtered;
    }
  }

  Future<void> _showMedicineQuickSheet(
    BuildContext context,
    _MedicineEntry entry,
    ColorScheme colorScheme,
  ) async {
    final medicine = entry.medicine;
    final name = _isArabic ? medicine.nameAr : medicine.nameEn;
    final description = _pickString(entry.data, const [
      'description',
      'subtitle',
      'note',
      'usage',
      'indication',
    ]);
    final manufacturer = _pickString(entry.data, const [
      'manufacturer',
      'company',
      'brand',
    ]);
    final activeIngredient = _pickString(entry.data, const [
      'activeIngredient',
      'ingredient',
    ]);
    final dosage = _pickString(entry.data, const ['dosage', 'dose']);
    final strength = _pickString(entry.data, const [
      'strength',
      'concentration',
    ]);
    final stock = _pickString(entry.data, const ['stock', 'quantity']);
    final isAvailable = entry.data['isAvailable'] != false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.84,
          minChildSize: 0.6,
          maxChildSize: 0.95,
          builder: (context, controller) {
            return Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
              ),
              child: SingleChildScrollView(
                controller: controller,
                padding: EdgeInsets.fromLTRB(
                  16,
                  12,
                  16,
                  16 + MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 54,
                        height: 5,
                        decoration: BoxDecoration(
                          color: colorScheme.outlineVariant,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _MedicineHero(
                      entry: entry,
                      colorScheme: colorScheme,
                      isArabic: _isArabic,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      name,
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _SmallBadge(
                          text: medicine.form,
                          colorScheme: colorScheme,
                        ),
                        const SizedBox(width: 8),
                        _SmallBadge(
                          text: isAvailable
                              ? (_isArabic ? 'متاح' : 'Available')
                              : (_isArabic ? 'غير متاح' : 'Unavailable'),
                          colorScheme: colorScheme,
                          active: isAvailable,
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Text(
                          '\$${medicine.price.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: colorScheme.primary,
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const Spacer(),
                        if (stock != null)
                          _SmallBadge(
                            text: _isArabic
                                ? 'المخزون: $stock'
                                : 'Stock: $stock',
                            colorScheme: colorScheme,
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    if (description != null) ...[
                      _SheetSectionTitle(
                        title: _isArabic ? 'الوصف' : 'Description',
                        colorScheme: colorScheme,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        description,
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 14,
                          height: 1.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    _SheetSectionTitle(
                      title: _isArabic ? 'التفاصيل' : 'Details',
                      colorScheme: colorScheme,
                    ),
                    const SizedBox(height: 10),

                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        if (dosage != null)
                          _DetailChip(
                            icon: Icons.medication_liquid_outlined,
                            label: _isArabic
                                ? 'الجرعة: $dosage'
                                : 'Dosage: $dosage',
                            colorScheme: colorScheme,
                          ),
                        if (strength != null)
                          _DetailChip(
                            icon: Icons.science_outlined,
                            label: _isArabic
                                ? 'التركيز: $strength'
                                : 'Strength: $strength',
                            colorScheme: colorScheme,
                          ),
                        if (manufacturer != null)
                          _DetailChip(
                            icon: Icons.factory_outlined,
                            label: _isArabic
                                ? 'الشركة: $manufacturer'
                                : 'Manufacturer: $manufacturer',
                            colorScheme: colorScheme,
                          ),
                        if (activeIngredient != null)
                          _DetailChip(
                            icon: Icons.health_and_safety_outlined,
                            label: _isArabic
                                ? 'المادة الفعالة: $activeIngredient'
                                : 'Active ingredient: $activeIngredient',
                            colorScheme: colorScheme,
                          ),
                      ],
                    ),

                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: colorScheme.onPrimary,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.push(
                            sheetContext,
                            MaterialPageRoute(
                              builder: (_) => MedicineDetailsScreen(
                                medicine: entry.medicine,
                                pharmacyId: widget.pharmacyId,
                                pharmacyName: widget.pharmacyName,
                                pharmacyImageUrl: widget.pharmacyImageUrl,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.open_in_new_rounded),
                        label: Text(
                          _isArabic
                              ? 'عرض التفاصيل الكاملة'
                              : 'Open full details',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.controller,
    required this.isArabic,
    required this.colorScheme,
  });

  final TextEditingController controller;
  final bool isArabic;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(0.65),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: TextField(
        controller: controller,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: isArabic ? 'ابحث عن دواء...' : 'Search medicine...',
          hintStyle: TextStyle(
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: colorScheme.onSurfaceVariant,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
        style: TextStyle(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _SortPill extends StatelessWidget {
  const _SortPill({
    required this.colorScheme,
    required this.isArabic,
    required this.value,
    required this.onChanged,
  });

  final ColorScheme colorScheme;
  final bool isArabic;
  final _MedicineSort value;
  final ValueChanged<_MedicineSort> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<_MedicineSort>(
          value: value,
          isExpanded: true,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: colorScheme.primary,
          ),
          borderRadius: BorderRadius.circular(16),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
          items: [
            DropdownMenuItem(
              value: _MedicineSort.newest,
              child: Text(isArabic ? 'الأحدث' : 'Newest'),
            ),
            DropdownMenuItem(
              value: _MedicineSort.priceLowHigh,
              child: Text(isArabic ? 'السعر: من الأقل' : 'Price: Low to High'),
            ),
            DropdownMenuItem(
              value: _MedicineSort.priceHighLow,
              child: Text(isArabic ? 'السعر: من الأعلى' : 'Price: High to Low'),
            ),
            DropdownMenuItem(
              value: _MedicineSort.name,
              child: Text(isArabic ? 'الاسم' : 'Name'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryFilterChip extends StatelessWidget {
  const _CategoryFilterChip({
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
    return Material(
      color: isSelected ? colorScheme.primary : colorScheme.surface,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
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
              color: isSelected ? colorScheme.onPrimary : colorScheme.onSurface,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}

class _MedicineCard extends StatelessWidget {
  const _MedicineCard({
    required this.entry,
    required this.colorScheme,
    required this.isArabic,
    required this.onTap,
  });

  final _MedicineEntry entry;
  final ColorScheme colorScheme;
  final bool isArabic;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final medicine = entry.medicine;
    final name = isArabic ? medicine.nameAr : medicine.nameEn;
    final isAvailable = entry.data['isAvailable'] != false;
    final subtitle =
        _pickString(entry.data, const [
          'description',
          'subtitle',
          'note',
          'usage',
        ]) ??
        medicine.form;

    return Material(
      color: colorScheme.surface,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: colorScheme.outlineVariant),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 4,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(22),
                      ),
                      child:
                          medicine.imageUrl != null &&
                              medicine.imageUrl!.isNotEmpty
                          ? Image.network(
                              medicine.imageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return _MedicineFallback(
                                  colorScheme: colorScheme,
                                );
                              },
                            )
                          : _MedicineFallback(colorScheme: colorScheme),
                    ),
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isAvailable
                              ? Colors.green.withOpacity(0.90)
                              : Colors.red.withOpacity(0.90),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          isAvailable
                              ? (isArabic ? 'متاح' : 'Available')
                              : (isArabic ? 'غير متاح' : 'Unavailable'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          color: colorScheme.onSurface,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Spacer(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '\$${medicine.price.toStringAsFixed(2)}',
                            style: TextStyle(
                              color: colorScheme.primary,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: colorScheme.primary,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.add_rounded,
                              color: colorScheme.onPrimary,
                              size: 18,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MedicineHero extends StatelessWidget {
  const _MedicineHero({
    required this.entry,
    required this.colorScheme,
    required this.isArabic,
  });

  final _MedicineEntry entry;
  final ColorScheme colorScheme;
  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    final medicine = entry.medicine;
    final isAvailable = entry.data['isAvailable'] != false;

    return Container(
      height: 220,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: colorScheme.surfaceContainerHighest.withOpacity(0.45),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (medicine.imageUrl != null && medicine.imageUrl!.isNotEmpty)
            Image.network(
              medicine.imageUrl!,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return _MedicineFallback(colorScheme: colorScheme);
              },
            )
          else
            _MedicineFallback(colorScheme: colorScheme),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.10),
                  Colors.black.withOpacity(0.45),
                ],
              ),
            ),
          ),
          Positioned(
            left: 16,
            bottom: 16,
            child: Row(
              children: [
                _SmallBadge(text: medicine.form, colorScheme: colorScheme),
                const SizedBox(width: 8),
                _SmallBadge(
                  text: isAvailable
                      ? (isArabic ? 'متاح' : 'Available')
                      : (isArabic ? 'غير متاح' : 'Unavailable'),
                  colorScheme: colorScheme,
                  active: isAvailable,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MedicineFallback extends StatelessWidget {
  const _MedicineFallback({required this.colorScheme});

  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: colorScheme.primary.withOpacity(0.08),
      child: Center(
        child: Icon(
          Icons.medication_rounded,
          size: 70,
          color: colorScheme.primary.withOpacity(0.6),
        ),
      ),
    );
  }
}

class _SmallBadge extends StatelessWidget {
  const _SmallBadge({
    required this.text,
    required this.colorScheme,
    this.active,
  });

  final String text;
  final ColorScheme colorScheme;
  final bool? active;

  @override
  Widget build(BuildContext context) {
    final bg = active == null
        ? colorScheme.surfaceContainerHighest.withOpacity(0.7)
        : (active!
              ? Colors.green.withOpacity(0.18)
              : Colors.red.withOpacity(0.18));

    final fg = active == null
        ? colorScheme.onSurface
        : (active! ? Colors.green.shade800 : Colors.red.shade800);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: active == null
              ? colorScheme.outlineVariant
              : (active!
                    ? Colors.green.withOpacity(0.30)
                    : Colors.red.withOpacity(0.30)),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _DetailChip extends StatelessWidget {
  const _DetailChip({
    required this.icon,
    required this.label,
    required this.colorScheme,
  });

  final IconData icon;
  final String label;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(0.55),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetSectionTitle extends StatelessWidget {
  const _SheetSectionTitle({required this.title, required this.colorScheme});

  final String title;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        color: colorScheme.onSurface,
        fontSize: 16,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.message,
    required this.colorScheme,
  });

  final IconData icon;
  final String message;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 56, color: colorScheme.onSurfaceVariant),
            const SizedBox(height: 14),
            Text(
              message,
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _MedicineEntry {
  final MedicineModel medicine;
  final Map<String, dynamic> data;

  const _MedicineEntry({required this.medicine, required this.data});
}

enum _MedicineSort { newest, priceLowHigh, priceHighLow, name }

String? _pickString(Map<String, dynamic> data, List<String> keys) {
  for (final key in keys) {
    final value = data[key];
    if (value == null) continue;

    final text = value.toString().trim();
    if (text.isNotEmpty && text.toLowerCase() != 'null') {
      return text;
    }
  }
  return null;
}
