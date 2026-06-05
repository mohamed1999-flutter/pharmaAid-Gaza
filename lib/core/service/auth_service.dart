import 'package:firebase_auth/firebase_auth.dart';

import '../models/pharmacy_models.dart';
import 'firestore_service.dart';

/// Thin wrapper over Firebase Auth to keep UI clean.
class AuthService {
  AuthService._();

  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static Stream<User?> authStateChanges() => _auth.authStateChanges();

  static User? get currentUser => _auth.currentUser;

  /// Sign in with email and password.
  static Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    return _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );
  }

  /// Create a pharmacy owner account and save the pharmacy profile in Firestore.
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
    if (password.trim() != confirmPassword.trim()) {
      throw FirebaseAuthException(
        code: 'password-mismatch',
        message: 'Password and confirmation do not match.',
      );
    }

    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );

    final user = credential.user!;
    final pharmacyUser = PharmacyUser(
      uid: user.uid,
      name: name.trim(),
      email: email.trim(),
      pharmacyName: pharmacyName.trim(),
      pharmacyAddress: pharmacyAddress.trim(),
      pharmacyLocation: pharmacyLocation.trim(),
      pharmacyImageUrl: pharmacyImageUrl?.trim().isEmpty == true
          ? null
          : pharmacyImageUrl?.trim(),
      role: 'pharmacy',
      createdAt: DateTime.now(),
    );

    await FirestoreService.createPharmacyAccount(user: pharmacyUser);
    return credential;
  }

  static Future<void> signOut() => _auth.signOut();
}
