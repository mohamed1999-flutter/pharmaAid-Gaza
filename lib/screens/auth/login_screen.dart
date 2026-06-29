import 'package:flutter/material.dart';
import 'package:pharmaaid_gaza/screens/auth/register_user_screen.dart';
import 'package:provider/provider.dart';

import '../../core/app/app_controller.dart';
import '../../core/service/app_exception.dart';
import '../../core/service/auth_service.dart';
import 'auth_gate.dart';
import 'register_pharmacy_screen.dart';

enum LoginTarget { customer, pharmacy }

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.initialTarget = LoginTarget.customer});

  final LoginTarget initialTarget;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  bool _loading = false;
  bool _obscure = true;
  late LoginTarget _target;

  @override
  void initState() {
    super.initState();
    _target = widget.initialTarget;
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Email is required';
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    if (!emailRegex.hasMatch(text)) return 'Enter a valid email';
    return null;
  }

  String? _validatePassword(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Password is required';
    if (text.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  void _switchTarget() {
    setState(() {
      _target = _target == LoginTarget.customer
          ? LoginTarget.pharmacy
          : LoginTarget.customer;
      _obscure = true;
    });
  }

  Future<void> _login() async {
    FocusScope.of(context).unfocus();

    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _loading = true);

    try {
      final isAr = Localizations.localeOf(context).languageCode == 'ar';
      final appController = context.read<AppController>();

      if (_target == LoginTarget.customer) {
        await AuthService.signInCustomer(
          email: _email.text,
          password: _password.text,
          isAr: isAr,
        );
        // Ensure AppMode matches the login type
        await appController.setAppMode(AppMode.customer);
      } else {
        await AuthService.signInPharmacy(
          email: _email.text,
          password: _password.text,
          isAr: isAr,
        );
        // Ensure AppMode matches the login type
        await appController.setAppMode(AppMode.pharmacy);
      }

      if (!mounted) return;

      // Navigate to AuthGate which will decide which screen to show based on AppMode.
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
    final isPharmacyMode = _target == LoginTarget.pharmacy;

    return Directionality(
      textDirection: direction,
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                cs.primary.withOpacity(0.12),
                theme.scaffoldBackgroundColor,
              ],
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      IconButton(
                        onPressed: Navigator.of(context).canPop()
                            ? () => Navigator.of(context).pop()
                            : null,
                        icon: const Icon(Icons.arrow_back_ios_new_rounded),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: _switchTarget,
                        tooltip: isPharmacyMode
                            ? (isAr
                                  ? 'التحويل إلى دخول العميل'
                                  : 'Switch to customer login')
                            : (isAr
                                  ? 'التحويل إلى دخول الصيدلية'
                                  : 'Switch to pharmacy login'),
                        icon: Icon(
                          isPharmacyMode
                              ? Icons.person_rounded
                              : Icons.local_pharmacy_rounded,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      gradient: LinearGradient(
                        colors: [cs.primary, cs.secondary],
                      ),
                      boxShadow: [
                        BoxShadow(
                          blurRadius: 24,
                          offset: const Offset(0, 10),
                          color: cs.primary.withOpacity(0.25),
                        ),
                      ],
                    ),
                    child: Icon(
                      isPharmacyMode
                          ? Icons.local_pharmacy_rounded
                          : Icons.person_rounded,
                      size: 48,
                      color: cs.onPrimary,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    isPharmacyMode
                        ? (isAr ? 'تسجيل دخول الصيدلية' : 'Pharmacy Login')
                        : (isAr ? 'تسجيل دخول المستخدم' : 'Customer Login'),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isPharmacyMode
                        ? (isAr
                              ? 'سجّل دخولك كصيدلي للوصول إلى لوحة التحكم'
                              : 'Sign in as a pharmacy to access your dashboard')
                        : (isAr
                              ? 'سجّل دخولك كمستخدم عادي للشراء والطلبات'
                              : 'Sign in as a customer to browse and place orders'),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 28),
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
                            TextFormField(
                              controller: _email,
                              keyboardType: TextInputType.emailAddress,
                              validator: _validateEmail,
                              decoration: InputDecoration(
                                labelText: isAr ? 'البريد الإلكتروني' : 'Email',
                                prefixIcon: const Icon(Icons.email_outlined),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _password,
                              obscureText: _obscure,
                              validator: _validatePassword,
                              decoration: InputDecoration(
                                labelText: isAr ? 'كلمة المرور' : 'Password',
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscure
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                  ),
                                  onPressed: () =>
                                      setState(() => _obscure = !_obscure),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                            const SizedBox(height: 18),
                            SizedBox(
                              height: 54,
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _loading ? null : _login,
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
                                        isPharmacyMode
                                            ? (isAr
                                                  ? 'دخول الصيدلية'
                                                  : 'Sign in as pharmacy')
                                            : (isAr
                                                  ? 'دخول المستخدم'
                                                  : 'Sign in'),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextButton(
                              onPressed: _loading
                                  ? null
                                  : () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => isPharmacyMode
                                              ? const RegisterPharmacyScreen()
                                              : const RegisterUserScreen(),
                                        ),
                                      );
                                    },
                              child: Text(
                                isPharmacyMode
                                    ? (isAr
                                          ? 'إنشاء حساب صيدلية جديد'
                                          : 'Create pharmacy account')
                                    : (isAr
                                          ? 'إنشاء حساب مستخدم جديد'
                                          : 'Create customer account'),
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
      ),
    );
  }
}
