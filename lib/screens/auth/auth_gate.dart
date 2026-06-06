import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../pharmacy/pharmacy_shell_screen.dart';
import '../user/user_shell_screen.dart';
import 'login_screen.dart';

/// Decides whether the user sees login or the appropriate dashboard based on role.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _SplashLoader();
        }

        if (snapshot.hasData) {
          return _RoleBasedRouter(userId: snapshot.data!.uid);
        }

        return const LoginScreen();
      },
    );
  }
}

class _RoleBasedRouter extends StatelessWidget {
  const _RoleBasedRouter({required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _SplashLoader();
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          // If user document doesn't exist, default to login
          return const LoginScreen();
        }

        final userData = snapshot.data!.data() as Map<String, dynamic>;
        final role = userData['role'] ?? 'user';

        if (role == 'pharmacy') {
          return const PharmacyShellScreen();
        } else {
          return const UserShellScreen();
        }
      },
    );
  }
}

class _SplashLoader extends StatelessWidget {
  const _SplashLoader();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
