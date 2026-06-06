import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app/app_controller.dart';
import '../../core/localization/app_keys.dart';
import '../../core/localization/app_texts.dart';

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
            FilledButton(
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
    final cs = Theme.of(context).colorScheme;

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(t(AppKeys.appName)),
          centerTitle: false,
          leading: IconButton(
            icon: const Icon(Icons.swap_horiz_rounded),
            tooltip: t(AppKeys.switchSystemTitle),
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
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 520),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: cs.outlineVariant),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 34,
                    backgroundColor: cs.primary.withOpacity(0.10),
                    child: Icon(
                      Icons.local_pharmacy_rounded,
                      color: cs.primary,
                      size: 34,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    t(AppKeys.appName),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isAr
                        ? 'واجهة صيدلية احترافية، نظيفة، وسريعة'
                        : 'A clean, fast, and professional pharmacy experience',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                      height: 1.45,
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
