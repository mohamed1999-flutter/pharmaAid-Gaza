import 'package:firebase_auth/firebase_auth.dart';

import '../models/pharmacy_models.dart';
import 'app_exception.dart';
import 'firestore_service.dart';

class AuthService {
  AuthService._();

  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static Stream<User?> authStateChanges() => _auth.authStateChanges();

  static User? get currentUser => _auth.currentUser;

  static String _clean(String value) => value.trim();

  static bool _isValidEmail(String value) {
    final email = value.trim();
    return RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(email);
  }

  static String _mapAuthError(FirebaseAuthException e) {
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
      default:
        return e.message ?? 'Authentication failed. Please try again.';
    }
  }

  static String _mapFirestoreError(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return 'You do not have permission to do this.';
      case 'not-found':
        return 'Your pharmacy profile was not found in the database.';
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

  static AppException _friendlyError(Object error) {
    if (error is AppException) return error;

    if (error is FirebaseAuthException) {
      return AppException(_mapAuthError(error), error.code);
    }

    if (error is FirebaseException) {
      return AppException(_mapFirestoreError(error), error.code);
    }

    return const AppException('Something went wrong. Please try again.');
  }

  static Future<UserCredential> signInPharmacy({
    required String email,
    required String password,
  }) async {
    final cleanEmail = _clean(email);
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

      final user = credential.user;
      if (user == null) {
        await _auth.signOut();
        throw const AppException('Login failed. Please try again.');
      }

      final userDoc = await FirestoreService.getUserProfile(user.uid);
      if (!userDoc.exists) {
        await _auth.signOut();
        throw const AppException(
          'Your account was found in Firebase Auth, but no pharmacy profile exists in Firestore. Please register the pharmacy account first.',
        );
      }

      final userData = userDoc.data() ?? {};
      final role = (userData['role'] ?? '').toString().trim();

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
      throw AppException(_mapAuthError(e), e.code);
    } on FirebaseException catch (e) {
      throw AppException(_mapFirestoreError(e), e.code);
    } catch (e) {
      throw _friendlyError(e);
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
  }) async {
    final cleanName = _clean(name);
    final cleanEmail = _clean(email);
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
        );
      }

      return credential;
    } on FirebaseAuthException catch (e) {
      throw AppException(_mapAuthError(e), e.code);
    } on FirebaseException catch (e) {
      throw AppException(_mapFirestoreError(e), e.code);
    } catch (e) {
      throw _friendlyError(e);
    }
  }

  static Future<void> signOut() => _auth.signOut();
}
