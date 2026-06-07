import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/app/app_controller.dart';
import 'core/localization/app_texts.dart';
import 'core/providers/cart_provider.dart';
import 'core/service/auth_service.dart';
import 'core/service/pharmacy_auth_service.dart';
import 'core/theme/app_theme.dart';
import 'firebase_options.dart';
import 'screens/splash/splash.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Default App (for Customers)
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize Secondary App (for Pharmacies)
  // This allows having two separate authentication sessions simultaneously.
  try {
    await Firebase.initializeApp(
      name: 'PharmacyApp',
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('PharmacyApp already initialized or failed: $e');
  }

  final appController = AppController();
  await appController.load();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: appController),
        // Stream for Customer Auth
        StreamProvider<User?>(
          create: (_) => AuthService.authStateChanges(),
          initialData: AuthService.currentUser,
        ),
        // Stream for Pharmacy Auth
        StreamProvider<PharmacyUserAuth?>(
          create: (_) => PharmacyAuthService.authStateChanges(),
          initialData: PharmacyAuthService.currentUser,
        ),
        ChangeNotifierProxyProvider<User?, CartProvider>(
          create: (_) => CartProvider(userId: ''),
          update: (_, user, previous) {
            if (user == null) return previous ?? CartProvider(userId: '');
            if (previous != null && previous.userId == user.uid)
              return previous;
            return CartProvider(userId: user.uid);
          },
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AppController>();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'PharmaAid Gaza',
      locale: controller.locale,
      supportedLocales: AppTexts.supportedLocales,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: controller.themeMode,
      home: const SplashScreen(),
    );
  }
}

// Simple wrapper to distinguish between User types in Provider
class PharmacyUserAuth {
  final User user;
  PharmacyUserAuth(this.user);
  String get uid => user.uid;
}
