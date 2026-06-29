import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app/app_controller.dart';
import '../../main.dart';
import '../pharmacy/pharmacy_shell_screen.dart';
import '../user/user_shell_screen.dart';
import 'login_screen.dart';

/// Decides whether the user sees login or the appropriate dashboard based on app mode and session.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final appController = context.watch<AppController>();
    final isPharmacyMode = appController.isPharmacyMode;
    final userAuth = context.watch<User?>();

    if (isPharmacyMode) {
      if (userAuth != null) {
        return const PharmacyShellScreen();
      }
      return const LoginScreen(initialTarget: LoginTarget.pharmacy);
    } else {
      if (userAuth != null) {
        return const UserShellScreen();
      }
      return const LoginScreen(initialTarget: LoginTarget.customer);
    }
  }
}

class _SplashLoader extends StatelessWidget {
  const _SplashLoader();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
