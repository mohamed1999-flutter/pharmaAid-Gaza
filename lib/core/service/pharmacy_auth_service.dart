import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../main.dart';
import 'app_exception.dart';
import 'firestore_service.dart';

class PharmacyAuthService {
  PharmacyAuthService._();

  static FirebaseAuth get _auth =>
      FirebaseAuth.instanceFor(app: Firebase.app('PharmacyApp'));

  static Stream<PharmacyUserAuth?> authStateChanges() => _auth
      .authStateChanges()
      .map((user) => user != null ? PharmacyUserAuth(user) : null);

  static PharmacyUserAuth? get currentUser {
    final user = _auth.currentUser;
    return user != null ? PharmacyUserAuth(user) : null;
  }

  static String _clean(String value, {bool isEmail = false}) {
    final text = value.trim();
    return isEmail ? text.toLowerCase() : text;
  }

  static bool _isValidEmail(String value) {
    final email = value.trim();
    return RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(email);
  }

  static Future<UserCredential> signInPharmacy({
    required String email,
    required String password,
    bool isAr = false,
  }) async {
    final cleanEmail = _clean(email, isEmail: true);
    final cleanPassword = _clean(password);

    if (cleanEmail.isEmpty || cleanPassword.isEmpty) {
      throw AppException(
        isAr
            ? 'يرجى إدخال البريد الإلكتروني وكلمة المرور.'
            : 'Please fill in email and password.',
      );
    }

    if (!_isValidEmail(cleanEmail)) {
      throw AppException(
        isAr
            ? 'يرجى إدخال بريد إلكتروني صحيح.'
            : 'Please enter a valid email address.',
      );
    }

    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: cleanEmail,
        password: cleanPassword,
      );

      final user = credential.user;
      if (user == null) {
        await _auth.signOut();
        throw AppException(
          isAr
              ? 'فشل تسجيل الدخول، حاول مرة أخرى.'
              : 'Login failed. Please try again.',
        );
      }

      final userDoc = await FirestoreService.getUserProfile(user.uid);
      if (!userDoc.exists) {
        await _auth.signOut();
        throw AppException(
          isAr
              ? 'ملف الصيدلية غير موجود. يرجى إنشاء الحساب أولاً.'
              : 'Pharmacy profile not found. Please create the pharmacy account first.',
        );
      }

      final userData = userDoc.data() ?? {};
      final role = (userData['role'] ?? '').toString().trim().toLowerCase();

      if (role != 'pharmacy') {
        await _auth.signOut();
        throw AppException(
          isAr
              ? 'هذا الحساب غير مصرح له كحساب صيدلية.'
              : 'This account is not authorized as a pharmacy account.',
        );
      }

      return credential;
    } on FirebaseAuthException catch (e) {
      throw AppException(e.message ?? 'Auth failed', e.code);
    } catch (e) {
      throw AppException(e.toString());
    }
  }

  static Future<void> signOut() => _auth.signOut();
}
