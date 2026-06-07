import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/pharmacy_models.dart';
import 'app_exception.dart';
import 'firestore_service.dart';

class AuthService {
  AuthService._();

  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static Stream<User?> authStateChanges() => _auth.authStateChanges();

  static User? get currentUser => _auth.currentUser;

  static String _clean(String value, {bool isEmail = false}) {
    final text = value.trim();
    return isEmail ? text.toLowerCase() : text;
  }

  static bool _isValidEmail(String value) {
    final email = value.trim();
    return RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(email);
  }

  static String _mapAuthError(FirebaseAuthException e, bool isAr) {
    if (isAr) {
      switch (e.code) {
        case 'invalid-email':
          return 'البريد الإلكتروني غير صحيح.';
        case 'user-not-found':
          return 'لا يوجد حساب بهذا البريد.';
        case 'wrong-password':
          return 'كلمة المرور غير صحيحة.';
        case 'invalid-credential':
          return 'البريد الإلكتروني أو كلمة المرور غير صحيحة.';
        case 'too-many-requests':
          return 'محاولات كثيرة جداً، حاول لاحقاً.';
        case 'network-request-failed':
          return 'فشل الاتصال بالشبكة.';
        case 'email-already-in-use':
          return 'هذا البريد مستخدم بالفعل.';
        case 'weak-password':
          return 'كلمة المرور ضعيفة جداً.';
        default:
          return 'حدث خطأ في التسجيل: ${e.message}';
      }
    }

    switch (e.code) {
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-not-found':
        return 'No account found for this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'invalid-credential':
        return 'Invalid email or password.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Please check your connection.';
      case 'email-already-in-use':
        return 'This email is already used.';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'operation-not-allowed':
        return 'Email/password sign-in is not enabled.';
      case 'requires-recent-login':
        return 'Please log in again to continue.';
      case 'user-disabled':
        return 'This account has been disabled.';
      default:
        return e.message ?? 'Authentication failed. Please try again.';
    }
  }

  static String _mapFirestoreError(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return 'You do not have permission to do this.';
      case 'not-found':
        return 'Your profile was not found in the database.';
      case 'unavailable':
        return 'Firestore is currently unavailable. Please try again.';
      case 'deadline-exceeded':
        return 'The request timed out. Please try again.';
      case 'cancelled':
        return 'The request was cancelled.';
      default:
        return e.message ?? 'Database error. Please try again.';
    }
  }

  static AppException _friendlyError(Object error, [bool isAr = false]) {
    if (error is AppException) return error;

    if (error is FirebaseAuthException) {
      return AppException(_mapAuthError(error, isAr), error.code);
    }

    if (error is FirebaseException) {
      return AppException(_mapFirestoreError(error), error.code);
    }

    return AppException(
      isAr
          ? 'حدث خطأ ما. يرجى المحاولة مرة أخرى.'
          : 'Something went wrong. Please try again.',
    );
  }

  static String _fallbackNameFromEmail(String email) {
    final localPart = email.split('@').first.trim();
    if (localPart.isEmpty) return 'Customer';
    return localPart.replaceAll(RegExp(r'[._-]+'), ' ');
  }

  static String _normalizeRole(Map<String, dynamic> data) {
    return (data['role'] ?? '').toString().trim().toLowerCase();
  }

  static Future<UserCredential> signInCustomer({
    required String email,
    required String password,
    bool isAr = false,
  }) async {
    final cleanEmail = _clean(email, isEmail: true);
    final cleanPassword = _clean(password);

    print('--- CUSTOMER LOGIN ATTEMPT ---');
    print('Email: $cleanEmail');
    print('Password Length: ${cleanPassword.length}');

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

      print('Auth sign-in successful for UID: ${credential.user?.uid}');

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
        print('User document not found for UID: ${user.uid}');
        await _auth.signOut();
        throw AppException(
          isAr
              ? 'لم يتم العثور على حساب العميل، يرجى التسجيل أولاً.'
              : 'Customer profile not found. Please sign up first.',
        );
      }

      final userData = userDoc.data() ?? {};
      final role = _normalizeRole(userData);
      print('Login Success. Role: $role');

      if (role == 'pharmacy') {
        print('Conflict: Pharmacy account trying to login as customer');
        await _auth.signOut();
        throw AppException(
          isAr
              ? 'هذا الحساب خاص بصيدلية، يرجى الدخول من تبويب الصيدليات.'
              : 'This account is a pharmacy account. Please use pharmacy login.',
        );
      }

      return credential;
    } on FirebaseAuthException catch (e) {
      print('FirebaseAuthException during login: ${e.code} - ${e.message}');
      throw AppException(_mapAuthError(e, isAr), e.code);
    } on FirebaseException catch (e) {
      print('FirebaseException during login: ${e.code} - ${e.message}');
      throw AppException(_mapFirestoreError(e), e.code);
    } catch (e) {
      print('Unexpected error during login: $e');
      rethrow;
    }
  }

  static Future<UserCredential> signInPharmacy({
    required String email,
    required String password,
    bool isAr = false,
  }) async {
    final cleanEmail = _clean(email, isEmail: true);
    final cleanPassword = _clean(password);

    if (cleanEmail.isEmpty || cleanPassword.isEmpty) {
      throw const AppException('Please fill in email and password.');
    }

    if (!_isValidEmail(cleanEmail)) {
      throw const AppException('Please enter a valid email address.');
    }

    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: cleanEmail,
        password: cleanPassword,
      );

      print('Auth sign-in successful for UID: ${credential.user?.uid}');

      final user = credential.user;
      if (user == null) {
        await _auth.signOut();
        throw const AppException('Login failed. Please try again.');
      }

      final userDoc = await FirestoreService.getUserProfile(user.uid);
      if (!userDoc.exists) {
        await _auth.signOut();
        throw const AppException(
          'Pharmacy profile not found. Please create the pharmacy account first.',
        );
      }

      final userData = userDoc.data() ?? {};
      final role = _normalizeRole(userData);

      if (role != 'pharmacy') {
        await _auth.signOut();
        throw const AppException(
          'This account is not authorized as a pharmacy account.',
        );
      }

      final pharmacyDoc = await FirestoreService.getPharmacyProfile(user.uid);
      if (!pharmacyDoc.exists) {
        await _auth.signOut();
        throw const AppException(
          'Pharmacy profile not found in Firestore. Please complete registration again or contact support.',
        );
      }

      return credential;
    } on FirebaseAuthException catch (e) {
      throw AppException(_mapAuthError(e, isAr), e.code);
    } on FirebaseException catch (e) {
      throw AppException(_mapFirestoreError(e), e.code);
    } catch (e) {
      throw _friendlyError(e, isAr);
    }
  }

  static Future<UserCredential> signUpCustomer({
    required String name,
    required String email,
    required String password,
    required String confirmPassword,
    bool isAr = false,
  }) async {
    final cleanName = _clean(name);
    final cleanEmail = _clean(email, isEmail: true);
    final cleanPassword = _clean(password);
    final cleanConfirm = _clean(confirmPassword);

    print('--- CUSTOMER SIGN UP ATTEMPT ---');
    print('Email: $cleanEmail');
    print('Password Length: ${cleanPassword.length}');

    if (cleanName.isEmpty ||
        cleanEmail.isEmpty ||
        cleanPassword.isEmpty ||
        cleanConfirm.isEmpty) {
      throw AppException(
        isAr
            ? 'يرجى ملء جميع الحقول المطلوبة.'
            : 'Please fill in all required fields.',
      );
    }

    if (!_isValidEmail(cleanEmail)) {
      throw const AppException('Please enter a valid email address.');
    }

    if (cleanPassword.length < 6) {
      throw const AppException('Password must be at least 6 characters.');
    }

    if (cleanPassword != cleanConfirm) {
      throw const AppException('Password and confirmation do not match.');
    }

    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: cleanEmail,
        password: cleanPassword,
      );

      final user = credential.user;
      if (user == null) {
        await _auth.signOut();
        throw const AppException('Account creation failed. Please try again.');
      }

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'name': cleanName,
        'fullName': cleanName,
        'email': cleanEmail,
        'role': 'user',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return credential;
    } on FirebaseAuthException catch (e) {
      throw AppException(_mapAuthError(e, isAr), e.code);
    } on FirebaseException catch (e) {
      throw AppException(_mapFirestoreError(e), e.code);
    } catch (e) {
      throw _friendlyError(e, isAr);
    }
  }

  static Future<UserCredential> signUpPharmacy({
    required String name,
    required String email,
    required String password,
    required String confirmPassword,
    required String pharmacyName,
    required String pharmacyAddress,
    required String pharmacyLocation,
    String? pharmacyImageUrl,
    bool isAr = false,
  }) async {
    final cleanName = _clean(name);
    final cleanEmail = _clean(email, isEmail: true);
    final cleanPassword = _clean(password);
    final cleanConfirm = _clean(confirmPassword);
    final cleanPharmacyName = _clean(pharmacyName);
    final cleanPharmacyAddress = _clean(pharmacyAddress);
    final cleanPharmacyLocation = _clean(pharmacyLocation);
    final cleanImageUrl = pharmacyImageUrl == null
        ? null
        : _clean(pharmacyImageUrl);

    if (cleanName.isEmpty ||
        cleanEmail.isEmpty ||
        cleanPassword.isEmpty ||
        cleanConfirm.isEmpty ||
        cleanPharmacyName.isEmpty ||
        cleanPharmacyAddress.isEmpty ||
        cleanPharmacyLocation.isEmpty) {
      throw const AppException('Please fill in all required fields.');
    }

    if (!_isValidEmail(cleanEmail)) {
      throw const AppException('Please enter a valid email address.');
    }

    if (cleanPassword.length < 6) {
      throw const AppException('Password must be at least 6 characters.');
    }

    if (cleanPassword != cleanConfirm) {
      throw const AppException('Password and confirmation do not match.');
    }

    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: cleanEmail,
        password: cleanPassword,
      );

      final user = credential.user;
      if (user == null) {
        await _auth.signOut();
        throw const AppException('Account creation failed. Please try again.');
      }

      final pharmacyUser = PharmacyUser(
        uid: user.uid,
        name: cleanName,
        email: cleanEmail,
        pharmacyName: cleanPharmacyName,
        pharmacyAddress: cleanPharmacyAddress,
        pharmacyLocation: cleanPharmacyLocation,
        pharmacyImageUrl: cleanImageUrl?.isEmpty == true ? null : cleanImageUrl,
        role: 'pharmacy',
        createdAt: DateTime.now(),
      );

      try {
        await FirestoreService.createPharmacyAccount(user: pharmacyUser);
        // CRITICAL: Sign out from the default app after registration.
        // This ensures the pharmacy account doesn't stay as the "currentUser" for customers.
        await _auth.signOut();
      } catch (e) {
        try {
          await user.delete();
        } catch (_) {}
        await _auth.signOut();
        throw _friendlyError(
          e is Exception
              ? e
              : const AppException(
                  'Account was created, but pharmacy profile could not be saved.',
                ),
          isAr,
        );
      }

      return credential;
    } on FirebaseAuthException catch (e) {
      throw AppException(_mapAuthError(e, isAr), e.code);
    } on FirebaseException catch (e) {
      throw AppException(_mapFirestoreError(e), e.code);
    } catch (e) {
      throw _friendlyError(e, isAr);
    }
  }

  static Future<void> signOut() => _auth.signOut();
}
