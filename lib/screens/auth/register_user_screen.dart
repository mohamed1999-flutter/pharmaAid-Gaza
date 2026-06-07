import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app/app_controller.dart';
import '../../core/service/app_exception.dart';
import '../../core/service/auth_service.dart';
import 'auth_gate.dart';

class RegisterUserScreen extends StatefulWidget {
  const RegisterUserScreen({super.key});

  @override
  State<RegisterUserScreen> createState() => _RegisterUserScreenState();
}

class _RegisterUserScreenState extends State<RegisterUserScreen> {
  final _formKey = GlobalKey<FormState>();

  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();

  bool _loading = false;
  bool _obscure1 = true;
  bool _obscure2 = true;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  String? _required(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Required';
    return null;
  }

  String? _validateEmail(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Required';
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    if (!emailRegex.hasMatch(text)) return 'Enter a valid email';
    return null;
  }

  String? _validatePassword(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Required';
    if (text.length < 6) return 'Min 6 chars';
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Required';
    if (text != _password.text.trim()) return 'Passwords do not match';
    return null;
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _loading = true);

    try {
      final isAr = Localizations.localeOf(context).languageCode == 'ar';
      await AuthService.signUpCustomer(
        name: _name.text,
        email: _email.text,
        password: _password.text,
        confirmPassword: _confirmPassword.text,
        isAr: isAr,
      );

      if (!mounted) return;

      // Set app mode to customer after successful registration
      await context.read<AppController>().setAppMode(AppMode.customer);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account created successfully.'),
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthGate()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;

      final message = e is AppException ? e.message : e.toString();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final direction = isAr ? TextDirection.rtl : TextDirection.ltr;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Directionality(
      textDirection: direction,
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: Text(isAr ? 'إنشاء حساب مستخدم' : 'Create Customer Account'),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Card(
                  elevation: 0,
                  color: cs.primary.withOpacity(0.08),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                    side: BorderSide(color: cs.outlineVariant),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 26,
                          backgroundColor: cs.primary,
                          child: Icon(
                            Icons.person_rounded,
                            color: cs.onPrimary,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            isAr
                                ? 'املأ البيانات التالية لإنشاء حساب المستخدم'
                                : 'Fill in the form below to create a customer account',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              height: 1.5,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Card(
                  elevation: 0,
                  color: cs.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                    side: BorderSide(color: cs.outlineVariant),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          _field(
                            controller: _name,
                            label: isAr ? 'اسمك الكامل' : 'Full name',
                            icon: Icons.person_outline,
                            validator: _required,
                          ),
                          const SizedBox(height: 14),
                          _field(
                            controller: _email,
                            label: isAr ? 'البريد الإلكتروني' : 'Email',
                            icon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                            validator: _validateEmail,
                          ),
                          const SizedBox(height: 14),
                          _passwordField(
                            controller: _password,
                            label: isAr ? 'كلمة المرور' : 'Password',
                            obscure: _obscure1,
                            onToggle: () =>
                                setState(() => _obscure1 = !_obscure1),
                            validator: _validatePassword,
                          ),
                          const SizedBox(height: 14),
                          _passwordField(
                            controller: _confirmPassword,
                            label: isAr
                                ? 'تأكيد كلمة المرور'
                                : 'Confirm password',
                            obscure: _obscure2,
                            onToggle: () =>
                                setState(() => _obscure2 = !_obscure2),
                            validator: _validateConfirmPassword,
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            height: 54,
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _loading ? null : _submit,
                              style: ElevatedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: _loading
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.2,
                                      ),
                                    )
                                  : Text(
                                      isAr ? 'إنشاء الحساب' : 'Create account',
                                    ),
                            ),
                          ),
                        ],
                      ),
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

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Widget _passwordField({
    required TextEditingController controller,
    required String label,
    required bool obscure,
    required VoidCallback onToggle,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          icon: Icon(obscure ? Icons.visibility_off : Icons.visibility),
          onPressed: onToggle,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
