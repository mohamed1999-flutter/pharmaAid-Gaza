import 'package:flutter/material.dart';

import '../../core/service/auth_service.dart';

/// Complete pharmacist registration screen.
/// Hint: This screen creates the Firebase Auth account and the Firestore pharmacy profile.
class RegisterPharmacyScreen extends StatefulWidget {
  const RegisterPharmacyScreen({super.key});

  @override
  State<RegisterPharmacyScreen> createState() => _RegisterPharmacyScreenState();
}

class _RegisterPharmacyScreenState extends State<RegisterPharmacyScreen> {
  final _formKey = GlobalKey<FormState>();

  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  final _pharmacyName = TextEditingController();
  final _pharmacyAddress = TextEditingController();
  final _pharmacyLocation = TextEditingController();
  final _pharmacyImageUrl = TextEditingController();

  bool _loading = false;
  bool _obscure1 = true;
  bool _obscure2 = true;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    _pharmacyName.dispose();
    _pharmacyAddress.dispose();
    _pharmacyLocation.dispose();
    _pharmacyImageUrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      await AuthService.signUpPharmacy(
        name: _name.text,
        email: _email.text,
        password: _password.text,
        confirmPassword: _confirmPassword.text,
        pharmacyName: _pharmacyName.text,
        pharmacyAddress: _pharmacyAddress.text,
        pharmacyLocation: _pharmacyLocation.text,
        pharmacyImageUrl: _pharmacyImageUrl.text.trim().isEmpty
            ? null
            : _pharmacyImageUrl.text.trim(),
      );

      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final direction = isAr ? TextDirection.rtl : TextDirection.ltr;
    final theme = Theme.of(context);

    return Directionality(
      textDirection: direction,
      child: Scaffold(
        appBar: AppBar(
          title: Text(isAr ? 'إنشاء حساب صيدلي' : 'Create Pharmacist Account'),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  _field(
                    controller: _name,
                    label: isAr ? 'اسمك الكامل' : 'Full name',
                  ),
                  const SizedBox(height: 14),
                  _field(
                    controller: _email,
                    label: isAr ? 'البريد الإلكتروني' : 'Email',
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 14),
                  _passwordField(
                    controller: _password,
                    label: isAr ? 'كلمة المرور' : 'Password',
                    obscure: _obscure1,
                    onToggle: () => setState(() => _obscure1 = !_obscure1),
                  ),
                  const SizedBox(height: 14),
                  _passwordField(
                    controller: _confirmPassword,
                    label: isAr ? 'تأكيد كلمة المرور' : 'Confirm password',
                    obscure: _obscure2,
                    onToggle: () => setState(() => _obscure2 = !_obscure2),
                  ),
                  const SizedBox(height: 14),
                  _field(
                    controller: _pharmacyName,
                    label: isAr ? 'اسم الصيدلية' : 'Pharmacy name',
                  ),
                  const SizedBox(height: 14),
                  _field(
                    controller: _pharmacyAddress,
                    label: isAr ? 'عنوان الصيدلية' : 'Pharmacy address',
                  ),
                  const SizedBox(height: 14),
                  _field(
                    controller: _pharmacyLocation,
                    label: isAr ? 'موقع الصيدلية' : 'Pharmacy location',
                  ),
                  const SizedBox(height: 14),
                  _field(
                    controller: _pharmacyImageUrl,
                    label: isAr
                        ? 'رابط صورة الصيدلية (اختياري)'
                        : 'Pharmacy image URL (optional)',
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 52,
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _submit,
                      child: _loading
                          ? const CircularProgressIndicator()
                          : Text(isAr ? 'إنشاء الحساب' : 'Create account'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    isAr
                        ? 'الصورة هنا لازم تكون رابط من الإنترنت'
                        : 'Image must be a public URL from the internet',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
    );
  }

  Widget _passwordField({
    required TextEditingController controller,
    required String label,
    required bool obscure,
    required VoidCallback onToggle,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        suffixIcon: IconButton(
          icon: Icon(obscure ? Icons.visibility_off : Icons.visibility),
          onPressed: onToggle,
        ),
      ),
      validator: (v) => v == null || v.length < 6 ? 'Min 6 chars' : null,
    );
  }
}
