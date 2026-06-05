import 'package:flutter/material.dart';

import '../../core/service/auth_service.dart';
import '../../core/service/firestore_service.dart';

/// Shows and updates the pharmacy main information.
/// Hint: This screen keeps the pharmacy profile synced with Firestore.
class PharmacyProfileScreen extends StatefulWidget {
  const PharmacyProfileScreen({super.key});

  @override
  State<PharmacyProfileScreen> createState() => _PharmacyProfileScreenState();
}

class _PharmacyProfileScreenState extends State<PharmacyProfileScreen> {
  Future<void> _editProfile(
    BuildContext context,
    Map<String, dynamic> data,
  ) async {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    final name = TextEditingController(text: data['name'] ?? '');
    final address = TextEditingController(text: data['address'] ?? '');
    final location = TextEditingController(text: data['location'] ?? '');
    final imageUrl = TextEditingController(text: data['imageUrl'] ?? '');

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(isAr ? 'تعديل بيانات الصيدلية' : 'Edit Pharmacy Info'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                _field(name, isAr ? 'اسم الصيدلية' : 'Pharmacy name'),
                const SizedBox(height: 10),
                _field(address, isAr ? 'العنوان' : 'Address'),
                const SizedBox(height: 10),
                _field(location, isAr ? 'الموقع' : 'Location'),
                const SizedBox(height: 10),
                _field(imageUrl, isAr ? 'رابط الصورة' : 'Image URL'),
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
                await FirestoreService.updatePharmacyInfo(
                  uid: AuthService.currentUser!.uid,
                  data: {
                    'name': name.text.trim(),
                    'address': address.text.trim(),
                    'location': location.text.trim(),
                    'imageUrl': imageUrl.text.trim().isEmpty
                        ? null
                        : imageUrl.text.trim(),
                  },
                );
                if (context.mounted) Navigator.pop(dialogContext);
              },
              child: Text(isAr ? 'حفظ' : 'Save'),
            ),
          ],
        );
      },
    );
  }

  Widget _field(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
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
        title: Text(isAr ? 'الصيدلية' : 'Pharmacy'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => AuthService.signOut(),
          ),
        ],
      ),
      body: StreamBuilder(
        stream: FirestoreService.pharmacyStream(uid),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!.data() ?? {};

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: cs.surface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: cs.outlineVariant),
                  ),
                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Container(
                          width: 110,
                          height: 110,
                          color: cs.primary.withOpacity(0.1),
                          child: (data['imageUrl'] ?? '').toString().isEmpty
                              ? Icon(
                                  Icons.local_pharmacy,
                                  size: 52,
                                  color: cs.primary,
                                )
                              : Image.network(
                                  data['imageUrl'],
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Icon(
                                    Icons.broken_image,
                                    size: 52,
                                    color: cs.primary,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        data['name'] ?? '',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(data['address'] ?? ''),
                      const SizedBox(height: 6),
                      Text(data['location'] ?? ''),
                      const SizedBox(height: 6),
                      Text(data['email'] ?? ''),
                      const SizedBox(height: 18),
                      SizedBox(
                        height: 48,
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _editProfile(context, data),
                          icon: const Icon(Icons.edit),
                          label: Text(isAr ? 'تعديل البيانات' : 'Edit info'),
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
