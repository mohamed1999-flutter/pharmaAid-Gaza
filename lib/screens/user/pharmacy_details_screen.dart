import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../core/models/pharmacy_models.dart';
import '../../core/models/user_models.dart';
import '../../core/service/auth_service.dart';
import '../../core/service/firestore_service.dart';
import '../chat/chat_detail_screen.dart';
import '../shared/map_picker_screen.dart';
import 'medicine_details_screen.dart';
import 'pharmacy_medicines_screen.dart';

class PharmacyDetailsScreen extends StatefulWidget {
  final String pharmacyId;
  final String pharmacyName;

  const PharmacyDetailsScreen({
    super.key,
    required this.pharmacyId,
    required this.pharmacyName,
  });

  @override
  State<PharmacyDetailsScreen> createState() => _PharmacyDetailsScreenState();
}

class _PharmacyDetailsScreenState extends State<PharmacyDetailsScreen> {
  late final Future<DocumentSnapshot<Map<String, dynamic>>> _pharmacyFuture;

  bool get _isArabic => Localizations.localeOf(context).languageCode == 'ar';

  @override
  void initState() {
    super.initState();
    _log('PharmacyDetailsScreen initState called');
    _log('Pharmacy ID: ${widget.pharmacyId}');
    _log('Pharmacy Name: ${widget.pharmacyName}');
    _pharmacyFuture = _loadPharmacyDetails();
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> _loadPharmacyDetails() async {
    _log('Starting to load pharmacy details from Firestore...');
    try {
      final snapshot = await FirestoreService.getPharmacyDetails(
        widget.pharmacyId,
      );

      if (!snapshot.exists) {
        _log('Pharmacy document does not exist.');
      } else {
        _log('Pharmacy document loaded successfully.');
        _log('Raw pharmacy data: ${snapshot.data()}');
      }

      return snapshot;
    } catch (e, stackTrace) {
      _log('Failed to load pharmacy details.');
      _log('Error: $e');
      _log('StackTrace: $stackTrace');
      rethrow;
    }
  }

  void _log(String message) {
    debugPrint('[PharmacyDetailsScreen] $message');
  }

  void _startChat(BuildContext context) async {
    final currentUser = AuthService.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isArabic
                ? 'يرجى تسجيل الدخول أولاً'
                : 'Please login first to chat',
          ),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final userDoc = await FirestoreService.getUserProfile(currentUser.uid);
      final userData = userDoc.data() ?? {};
      final userName = userData['name'] ?? userData['fullName'] ?? 'User';
      final userImageUrl = userData['imageUrl'];

      // Try to get pharmacy image from the future if it's already completed
      String? pharmacyImageUrl;
      try {
        final snapshot = await _pharmacyFuture;
        if (snapshot.exists) {
          pharmacyImageUrl =
              snapshot.data()?['pharmacyImageUrl'] ??
              snapshot.data()?['imageUrl'];
        }
      } catch (_) {}

      final chatId = await FirestoreService.getOrCreateChatRoom(
        userId: currentUser.uid,
        userName: userName,
        userImageUrl: userImageUrl,
        pharmacyId: widget.pharmacyId,
        pharmacyName: widget.pharmacyName,
        pharmacyImageUrl: pharmacyImageUrl,
      );

      if (!mounted) return;
      Navigator.pop(context); // Close loading

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatDetailScreen(
            chatId: chatId,
            otherName: widget.pharmacyName,
            otherId: widget.pharmacyId,
            isPharmacy: false,
            otherImageUrl: pharmacyImageUrl,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isArabic
                ? 'حدث خطأ أثناء بدء المحادثة'
                : 'Error starting chat: $e',
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _log('PharmacyDetailsScreen dispose called');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final direction = _isArabic ? TextDirection.rtl : TextDirection.ltr;

    _log('Build method called');

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
            widget.pharmacyName,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: colorScheme.onSurface,
            ),
          ),
          leading: IconButton(
            onPressed: () {
              _log('Back button tapped');
              Navigator.pop(context);
            },
            icon: Icon(Icons.arrow_back_rounded, color: colorScheme.onSurface),
          ),
          actions: [
            IconButton(
              onPressed: () => _startChat(context),
              icon: Icon(
                Icons.chat_bubble_outline_rounded,
                color: colorScheme.onSurface,
              ),
              tooltip: _isArabic ? 'محادثة' : 'Chat',
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: SafeArea(
          child: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            future: _pharmacyFuture,
            builder: (context, snapshot) {
              _log('FutureBuilder state: ${snapshot.connectionState}');

              if (snapshot.connectionState == ConnectionState.waiting) {
                _log('Pharmacy details are still loading...');
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                _log('FutureBuilder received an error: ${snapshot.error}');
                return _buildErrorState(colorScheme);
              }

              if (!snapshot.hasData) {
                _log('FutureBuilder has no data.');
                return _buildErrorState(colorScheme);
              }

              if (!snapshot.data!.exists) {
                _log('Pharmacy document was not found in Firestore.');
                return _buildErrorState(colorScheme);
              }

              final data = snapshot.data!.data();
              if (data == null) {
                _log('Pharmacy data is null.');
                return _buildErrorState(colorScheme);
              }

              _log('Pharmacy details loaded successfully.');
              _log('Parsed data keys: ${data.keys.toList()}');

              final pharmacy = PharmacyDisplay.fromMap(data);

              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _PharmacyHeroCard(
                        pharmacy: pharmacy,
                        data: data,
                        colorScheme: colorScheme,
                        isArabic: _isArabic,
                        onTapBrowseMedicines: () {
                          _log('Browse all medicines tapped from hero card');
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PharmacyMedicinesScreen(
                                pharmacyId: widget.pharmacyId,
                                pharmacyName: widget.pharmacyName,
                                pharmacyImageUrl: pharmacy.imageUrl,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 18),

                      Row(
                        children: [
                          Expanded(
                            child: _MiniStatCard(
                              icon: Icons.star_rounded,
                              title: _isArabic ? 'التقييم' : 'Rating',
                              value: pharmacy.rating.toStringAsFixed(1),
                              colorScheme: colorScheme,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _MiniStatCard(
                              icon: pharmacy.isOpen
                                  ? Icons.wb_sunny_rounded
                                  : Icons.nightlight_round_rounded,
                              title: _isArabic ? 'الحالة' : 'Status',
                              value: pharmacy.isOpen
                                  ? (_isArabic ? 'مفتوح' : 'Open')
                                  : (_isArabic ? 'مغلق' : 'Closed'),
                              colorScheme: colorScheme,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      _InfoSection(
                        title: _isArabic ? 'نبذة' : 'About',
                        icon: Icons.info_outline_rounded,
                        colorScheme: colorScheme,
                        child: Wrap(
                          runSpacing: 12,
                          spacing: 12,
                          children: [
                            _InfoChip(
                              icon: Icons.location_on_outlined,
                              label: pharmacy.address,
                              colorScheme: colorScheme,
                            ),
                            InkWell(
                              onTap: () {
                                try {
                                  final coords = pharmacy.location.split(',');
                                  if (coords.length == 2) {
                                    final lat = double.parse(coords[0].trim());
                                    final lng = double.parse(coords[1].trim());
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => MapViewScreen(
                                          location: LatLng(lat, lng),
                                          title: pharmacy.name,
                                        ),
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  // Fail silently
                                }
                              },
                              child: _InfoChip(
                                icon: Icons.map_outlined,
                                label: pharmacy.location,
                                colorScheme: colorScheme,
                              ),
                            ),
                            _InfoChip(
                              icon: Icons.person_outline_rounded,
                              label:
                                  _pickString(data, const [
                                    'ownerName',
                                    'pharmacyOwnerName',
                                    'name',
                                  ]) ??
                                  widget.pharmacyName,
                              colorScheme: colorScheme,
                            ),
                            if (_pickString(data, const [
                                  'phone',
                                  'phoneNumber',
                                  'contactPhone',
                                ]) !=
                                null)
                              _InfoChip(
                                icon: Icons.phone_outlined,
                                label:
                                    _pickString(data, const [
                                      'phone',
                                      'phoneNumber',
                                      'contactPhone',
                                    ]) ??
                                    '',
                                colorScheme: colorScheme,
                              ),
                            if (_pickString(data, const [
                                  'email',
                                  'contactEmail',
                                ]) !=
                                null)
                              _InfoChip(
                                icon: Icons.mail_outline_rounded,
                                label:
                                    _pickString(data, const [
                                      'email',
                                      'contactEmail',
                                    ]) ??
                                    '',
                                colorScheme: colorScheme,
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      _SectionHeader(
                        title: _isArabic ? 'الأقسام' : 'Categories',
                        actionLabel: _isArabic ? 'عرض الكل' : 'View all',
                        onActionTap: () {
                          _log('View all categories tapped');
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PharmacyMedicinesScreen(
                                pharmacyId: widget.pharmacyId,
                                pharmacyName: widget.pharmacyName,
                                pharmacyImageUrl: pharmacy.imageUrl,
                              ),
                            ),
                          );
                        },
                        colorScheme: colorScheme,
                      ),
                      const SizedBox(height: 10),

                      StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                        stream: FirestoreService.pharmacyCategoriesStream(
                          widget.pharmacyId,
                        ),
                        builder: (context, catSnapshot) {
                          _log(
                            'Categories StreamBuilder state: ${catSnapshot.connectionState}',
                          );

                          if (catSnapshot.connectionState ==
                              ConnectionState.waiting) {
                            _log('Loading categories...');
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 18),
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }

                          if (catSnapshot.hasError) {
                            _log(
                              'Failed to load categories: ${catSnapshot.error}',
                            );
                            return _EmptyState(
                              icon: Icons.error_outline_rounded,
                              message: _isArabic
                                  ? 'فشل تحميل الأقسام'
                                  : 'Failed to load categories',
                              colorScheme: colorScheme,
                            );
                          }

                          if (!catSnapshot.hasData ||
                              catSnapshot.data!.docs.isEmpty) {
                            _log('No categories found.');
                            return _EmptyState(
                              icon: Icons.category_outlined,
                              message: _isArabic
                                  ? 'لا توجد أقسام'
                                  : 'No categories',
                              colorScheme: colorScheme,
                            );
                          }

                          final categories = catSnapshot.data!.docs
                              .map(
                                (doc) => PharmacyCategory.fromMap(
                                  doc.data(),
                                  doc.id,
                                ),
                              )
                              .toList();

                          _log(
                            'Categories loaded successfully: ${categories.length}',
                          );

                          return SizedBox(
                            height: 54,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: categories.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(width: 10),
                              itemBuilder: (context, index) {
                                final category = categories[index];
                                final name = _isArabic
                                    ? category.nameAr
                                    : category.nameEn;

                                return _CategoryButton(
                                  label: name,
                                  colorScheme: colorScheme,
                                  onTap: () {
                                    _log(
                                      'Category tapped: ${category.id} | $name',
                                    );
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => PharmacyMedicinesScreen(
                                          pharmacyId: widget.pharmacyId,
                                          pharmacyName: widget.pharmacyName,
                                          pharmacyImageUrl: pharmacy.imageUrl,
                                          categoryId: category.id,
                                          categoryName: name,
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 18),

                      _SectionHeader(
                        title: _isArabic
                            ? 'الأدوية المتاحة'
                            : 'Available medicines',
                        actionLabel: _isArabic ? 'تصفح الكل' : 'Browse all',
                        onActionTap: () {
                          _log('Browse all medicines tapped');
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PharmacyMedicinesScreen(
                                pharmacyId: widget.pharmacyId,
                                pharmacyName: widget.pharmacyName,
                                pharmacyImageUrl: pharmacy.imageUrl,
                              ),
                            ),
                          );
                        },
                        colorScheme: colorScheme,
                      ),
                      const SizedBox(height: 10),

                      StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                        stream: FirestoreService.pharmacyMedicinesStream(
                          widget.pharmacyId,
                        ),
                        builder: (context, medSnapshot) {
                          _log(
                            'Medicines StreamBuilder state: ${medSnapshot.connectionState}',
                          );

                          if (medSnapshot.connectionState ==
                              ConnectionState.waiting) {
                            _log('Loading medicines...');
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 20),
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }

                          if (medSnapshot.hasError) {
                            _log(
                              'Failed to load medicines: ${medSnapshot.error}',
                            );
                            return _EmptyState(
                              icon: Icons.error_outline_rounded,
                              message: _isArabic
                                  ? 'فشل تحميل الأدوية'
                                  : 'Failed to load medicines',
                              colorScheme: colorScheme,
                            );
                          }

                          if (!medSnapshot.hasData ||
                              medSnapshot.data!.docs.isEmpty) {
                            _log('No medicines found.');
                            return _EmptyState(
                              icon: Icons.medication_outlined,
                              message: _isArabic
                                  ? 'لا توجد أدوية متاحة'
                                  : 'No medicines available',
                              colorScheme: colorScheme,
                            );
                          }

                          final medicines = medSnapshot.data!.docs
                              .map(
                                (doc) => _MedicineEntry(
                                  medicine: MedicineModel.fromMap(
                                    doc.data(),
                                    doc.id,
                                  ),
                                  data: doc.data(),
                                ),
                              )
                              .toList();

                          // Sort by newest first in memory to avoid Firestore index requirement
                          medicines.sort(
                            (a, b) => b.medicine.createdAt.compareTo(
                              a.medicine.createdAt,
                            ),
                          );

                          _log(
                            'Medicines loaded successfully: ${medicines.length}',
                          );
                          _log(
                            'Showing preview medicines: ${medicines.take(6).length}',
                          );

                          final preview = medicines.take(6).toList();

                          return SizedBox(
                            height: 240,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: preview.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(width: 12),
                              itemBuilder: (context, index) {
                                final entry = preview[index];
                                return _MedicinePreviewCard(
                                  entry: entry,
                                  pharmacyId: widget.pharmacyId,
                                  pharmacyName: widget.pharmacyName,
                                  colorScheme: colorScheme,
                                  isArabic: _isArabic,
                                  onTap: () {
                                    _log(
                                      'Medicine tapped: ${entry.medicine.id} | ${_isArabic ? entry.medicine.nameAr : entry.medicine.nameEn}',
                                    );
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => MedicineDetailsScreen(
                                          medicine: entry.medicine,
                                          pharmacyId: widget.pharmacyId,
                                          pharmacyName: widget.pharmacyName,
                                          pharmacyImageUrl: pharmacy.imageUrl,
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 20),

                      SizedBox(
                        width: double.infinity,
                        height: 56,
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
                            _log('Browse all medicines button tapped');
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PharmacyMedicinesScreen(
                                  pharmacyId: widget.pharmacyId,
                                  pharmacyName: widget.pharmacyName,
                                  pharmacyImageUrl: pharmacy.imageUrl,
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.shopping_bag_outlined),
                          label: Text(
                            _isArabic
                                ? 'تصفح كل الأدوية'
                                : 'Browse all medicines',
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
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(ColorScheme colorScheme) {
    _log('Rendering error state UI');
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.local_pharmacy_outlined,
            size: 72,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 12),
          Text(
            _isArabic
                ? 'تعذر تحميل تفاصيل الصيدلية'
                : 'Failed to load pharmacy details',
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _PharmacyHeroCard extends StatelessWidget {
  const _PharmacyHeroCard({
    required this.pharmacy,
    required this.data,
    required this.colorScheme,
    required this.isArabic,
    required this.onTapBrowseMedicines,
  });

  final PharmacyDisplay pharmacy;
  final Map<String, dynamic> data;
  final ColorScheme colorScheme;
  final bool isArabic;
  final VoidCallback onTapBrowseMedicines;

  @override
  Widget build(BuildContext context) {
    final subtitle =
        _pickString(data, const ['tagline', 'description', 'about', 'bio']) ??
        (isArabic ? 'صيدلية موثوقة لخدمتك' : 'Trusted pharmacy for your needs');

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 220,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (pharmacy.imageUrl != null && pharmacy.imageUrl!.isNotEmpty)
                  Image.network(
                    pharmacy.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return _HeroFallback(colorScheme: colorScheme);
                    },
                  )
                else
                  _HeroFallback(colorScheme: colorScheme),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.15),
                        Colors.black.withOpacity(0.50),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 16,
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              pharmacy.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              subtitle,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      _StatusBadge(
                        isOpen: pharmacy.isOpen,
                        isArabic: isArabic,
                        colorScheme: colorScheme,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _QuickAction(
                      icon: Icons.location_on_outlined,
                      label: isArabic ? 'الموقع' : 'Location',
                      colorScheme: colorScheme,
                      onTap: () {
                        debugPrint('[PharmacyDetails] Location QuickAction tapped for: ${pharmacy.name}');
                        try {
                          final coords = pharmacy.location.split(',');
                          if (coords.length == 2) {
                            final lat = double.parse(coords[0].trim());
                            final lng = double.parse(coords[1].trim());
                            debugPrint('[PharmacyDetails] Navigating to MapViewScreen: $lat, $lng');
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => MapViewScreen(
                                  location: LatLng(lat, lng),
                                  title: pharmacy.name,
                                ),
                              ),
                            );
                          } else {
                            debugPrint('[PharmacyDetails] Location format invalid: ${pharmacy.location}');
                          }
                        } catch (e) {
                          debugPrint('[PharmacyDetails] Error parsing location: $e');
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                isArabic
                                    ? 'موقع الصيدلية غير صالح'
                                    : 'Invalid pharmacy location',
                              ),
                            ),
                          );
                        }
                      },
                    ),
                    const SizedBox(width: 10),
                    _QuickAction(
                      icon: Icons.category_outlined,
                      label: isArabic ? 'الأقسام' : 'Categories',
                      colorScheme: colorScheme,
                      onTap: () {
                        debugPrint(
                          '[PharmacyDetailsScreen] Categories quick action tapped',
                        );
                      },
                    ),
                    const SizedBox(width: 10),
                    _QuickAction(
                      icon: Icons.medication_outlined,
                      label: isArabic ? 'الأدوية' : 'Medicines',
                      colorScheme: colorScheme,
                      onTap: onTapBrowseMedicines,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroFallback extends StatelessWidget {
  const _HeroFallback({required this.colorScheme});

  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: colorScheme.primary.withOpacity(0.12),
      child: Center(
        child: Icon(
          Icons.local_pharmacy_rounded,
          size: 92,
          color: colorScheme.primary.withOpacity(0.7),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.isOpen,
    required this.isArabic,
    required this.colorScheme,
  });

  final bool isOpen;
  final bool isArabic;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isOpen
            ? Colors.greenAccent.withOpacity(0.18)
            : Colors.redAccent.withOpacity(0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: isOpen
              ? Colors.greenAccent.withOpacity(0.35)
              : Colors.redAccent.withOpacity(0.35),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isOpen ? Icons.check_circle_rounded : Icons.cancel_rounded,
            size: 16,
            color: isOpen ? Colors.green.shade700 : Colors.red.shade700,
          ),
          const SizedBox(width: 6),
          Text(
            isOpen
                ? (isArabic ? 'مفتوح' : 'Open')
                : (isArabic ? 'مغلق' : 'Closed'),
            style: TextStyle(
              color: isOpen ? Colors.green.shade800 : Colors.red.shade800,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.colorScheme,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final ColorScheme colorScheme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
            child: Column(
              children: [
                Icon(icon, color: colorScheme.primary, size: 22),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniStatCard extends StatelessWidget {
  const _MiniStatCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.colorScheme,
  });

  final IconData icon;
  final String title;
  final String value;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: colorScheme.primary, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  const _InfoSection({
    required this.title,
    required this.icon,
    required this.child,
    required this.colorScheme,
  });

  final String title;
  final IconData icon;
  final Widget child;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: colorScheme.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
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
        color: colorScheme.surfaceContainerHighest.withOpacity(0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.8)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: colorScheme.primary),
          const SizedBox(width: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 240),
            child: Text(
              label,
              style: TextStyle(
                color: colorScheme.onSurface,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.actionLabel,
    required this.onActionTap,
    required this.colorScheme,
  });

  final String title;
  final String actionLabel;
  final VoidCallback onActionTap;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        TextButton(
          onPressed: onActionTap,
          child: Text(
            actionLabel,
            style: TextStyle(
              color: colorScheme.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _CategoryButton extends StatelessWidget {
  const _CategoryButton({
    required this.label,
    required this.colorScheme,
    required this.onTap,
  });

  final String label;
  final ColorScheme colorScheme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: colorScheme.primary.withOpacity(0.08),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: colorScheme.primary.withOpacity(0.18)),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: colorScheme.primary,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}

class _MedicinePreviewCard extends StatelessWidget {
  const _MedicinePreviewCard({
    required this.entry,
    required this.pharmacyId,
    required this.pharmacyName,
    required this.colorScheme,
    required this.isArabic,
    required this.onTap,
  });

  final _MedicineEntry entry;
  final String pharmacyId;
  final String pharmacyName;
  final ColorScheme colorScheme;
  final bool isArabic;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final medicine = entry.medicine;
    final name = isArabic ? medicine.nameAr : medicine.nameEn;
    final isAvailable = entry.data['isAvailable'] != false;
    final subtitle =
        _pickString(entry.data, const ['description', 'subtitle', 'note']) ??
        medicine.form;

    return SizedBox(
      width: 180,
      child: Material(
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
                  offset: const Offset(0, 8),
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
                                ? Colors.green.withOpacity(0.88)
                                : Colors.red.withOpacity(0.88),
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
                              '${medicine.price.toStringAsFixed(2)} ₪',
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
                                Icons.arrow_forward_rounded,
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
      child: Icon(
        Icons.medication_rounded,
        size: 54,
        color: colorScheme.primary.withOpacity(0.55),
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Column(
        children: [
          Icon(icon, color: colorScheme.onSurfaceVariant, size: 40),
          const SizedBox(height: 10),
          Text(
            message,
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _MedicineEntry {
  final MedicineModel medicine;
  final Map<String, dynamic> data;

  const _MedicineEntry({required this.medicine, required this.data});
}

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
