import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app/app_controller.dart';
import '../../core/localization/app_keys.dart';
import '../../core/localization/app_texts.dart';

/// Pharmacy home dashboard with system switch in the app bar.
class PharmacyHomeScreen extends StatelessWidget {
  const PharmacyHomeScreen({super.key});

  Future<void> _showSwitchDialog(BuildContext context) async {
    final t = (String key) => AppTexts.tr(context, key);

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(t(AppKeys.switchSystemTitle)),
          content: Text(t(AppKeys.switchSystemMessage)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(t(AppKeys.no)),
            ),
            ElevatedButton(
              onPressed: () async {
                await context.read<AppController>().toggleSystemMode();
                if (context.mounted) Navigator.pop(dialogContext);
              },
              child: Text(t(AppKeys.yes)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = (String key) => AppTexts.tr(context, key);
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(t(AppKeys.appName)),
          leading: IconButton(
            icon: const Icon(Icons.swap_horiz_rounded),
            onPressed: () => _showSwitchDialog(context),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.translate_rounded),
              onPressed: () => context.read<AppController>().toggleLocale(),
            ),
            IconButton(
              icon: const Icon(Icons.brightness_6_outlined),
              onPressed: () => context.read<AppController>().toggleTheme(),
            ),
          ],
        ),
        body: const Center(child: Text('Pharmacy Dashboard')),
      ),
    );
  }
}
