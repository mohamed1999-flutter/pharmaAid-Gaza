import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../pharmacy/pharmacy_shell_screen.dart';
import 'login_screen.dart';

/// Decides whether the user sees login or the pharmacy dashboard.
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
          return const PharmacyShellScreen();
        }

        return const LoginScreen();
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
