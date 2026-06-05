import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app/app_controller.dart';
import '../../core/localization/app_keys.dart';
import '../../core/localization/app_texts.dart';
import '../intor/intor.dart';

class PharmaAidGazaLanguageModeScreen extends StatefulWidget {
  const PharmaAidGazaLanguageModeScreen({super.key});

  @override
  State<PharmaAidGazaLanguageModeScreen> createState() =>
      _PharmaAidGazaLanguageModeScreenState();
}

class _PharmaAidGazaLanguageModeScreenState
    extends State<PharmaAidGazaLanguageModeScreen> {
  String _selectedLanguage = 'ar';
  String _selectedMode = 'morning';
  bool _initialized = false;

  static const Color _primaryBlue = Color(0xFF1F45D6);
  static const Color _activeGreen = Color(0xFF10D67A);
  static const Color _inactiveMint = Color(0xFFC7F7E4);
  static const Color _buttonGreen = Color(0xFF12D47B);
  static const Color _blackText = Color(0xFF111111);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_initialized) return;

    final controller = context.read<AppController>();
    _selectedLanguage = controller.locale.languageCode;
    _selectedMode = controller.themeMode == ThemeMode.dark
        ? 'night'
        : 'morning';

    _initialized = true;
  }

  Future<void> _onNext() async {
    final controller = context.read<AppController>();

    await controller.setLocale(Locale(_selectedLanguage));
    await controller.setThemeMode(
      _selectedMode == 'night' ? ThemeMode.dark : ThemeMode.light,
    );

    if (!mounted) return;

    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const IntorScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isArabic = _selectedLanguage == 'ar';
    final textDirection = isArabic ? TextDirection.rtl : TextDirection.ltr;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Directionality(
          textDirection: textDirection,
          child: SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: Stack(
              children: [
                SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight:
                          size.height - MediaQuery.of(context).padding.top,
                    ),
                    child: IntrinsicHeight(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          children: [
                            const SizedBox(height: 10),

                            Column(
                              children: [
                                Text(
                                  'PharmaAid Gaza',
                                  style: TextStyle(
                                    color: _primaryBlue,
                                    fontSize: 28,
                                    fontWeight: FontWeight.w800,
                                    height: 1.1,
                                  ),
                                ),
                                const SizedBox(height: 34),
                                Image.asset(
                                  'assets/image/logo.png',
                                  width: 140,
                                  height: 140,
                                  fit: BoxFit.contain,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'PharmaAid Gaza',
                                  style: TextStyle(
                                    color: _primaryBlue,
                                    fontSize: 28,
                                    fontWeight: FontWeight.w800,
                                    height: 1.1,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 56),

                            Text(
                              AppTexts.tr(context, AppKeys.shoppingHeadline),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: _blackText,
                                fontSize: 31,
                                fontWeight: FontWeight.w900,
                                height: 1.28,
                              ),
                            ),

                            const SizedBox(height: 14),

                            Text(
                              AppTexts.tr(context, AppKeys.shoppingSubheadline),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: _blackText,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                height: 1.45,
                              ),
                            ),

                            const SizedBox(height: 34),

                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const Spacer(),
                                Text(
                                  AppTexts.tr(context, AppKeys.language),
                                  style: const TextStyle(
                                    color: _blackText,
                                    fontSize: 30,
                                    fontWeight: FontWeight.w800,
                                    height: 1,
                                  ),
                                ),
                                const SizedBox(width: 18),
                                _ChoicePill(
                                  label: AppTexts.tr(context, AppKeys.arabic),
                                  selected: _selectedLanguage == 'ar',
                                  selectedColor: _activeGreen,
                                  unselectedColor: _inactiveMint,
                                  textColorSelected: Colors.white,
                                  textColorUnselected: Colors.white,
                                  onTap: () {
                                    setState(() => _selectedLanguage = 'ar');
                                    context.read<AppController>().setLocale(
                                      const Locale('ar'),
                                    );
                                  },
                                ),
                                const SizedBox(width: 8),
                                _ChoicePill(
                                  label: AppTexts.tr(context, AppKeys.english),
                                  selected: _selectedLanguage == 'en',
                                  selectedColor: _activeGreen,
                                  unselectedColor: _inactiveMint,
                                  textColorSelected: Colors.white,
                                  textColorUnselected: Colors.white,
                                  onTap: () {
                                    setState(() => _selectedLanguage = 'en');
                                    context.read<AppController>().setLocale(
                                      const Locale('en'),
                                    );
                                  },
                                ),
                              ],
                            ),

                            const SizedBox(height: 28),

                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const Spacer(),
                                Text(
                                  AppTexts.tr(context, AppKeys.mode),
                                  style: const TextStyle(
                                    color: _blackText,
                                    fontSize: 30,
                                    fontWeight: FontWeight.w800,
                                    height: 1,
                                  ),
                                ),
                                const SizedBox(width: 18),
                                _ChoicePill(
                                  label: AppTexts.tr(context, AppKeys.morning),
                                  selected: _selectedMode == 'morning',
                                  selectedColor: _activeGreen,
                                  unselectedColor: _inactiveMint,
                                  textColorSelected: Colors.white,
                                  textColorUnselected: Colors.white,
                                  onTap: () {
                                    setState(() => _selectedMode = 'morning');
                                    context.read<AppController>().setThemeMode(
                                      ThemeMode.light,
                                    );
                                  },
                                ),
                                const SizedBox(width: 8),
                                _ChoicePill(
                                  label: AppTexts.tr(context, AppKeys.night),
                                  selected: _selectedMode == 'night',
                                  selectedColor: _activeGreen,
                                  unselectedColor: _inactiveMint,
                                  textColorSelected: Colors.white,
                                  textColorUnselected: Colors.white,
                                  onTap: () {
                                    setState(() => _selectedMode = 'night');
                                    context.read<AppController>().setThemeMode(
                                      ThemeMode.dark,
                                    );
                                  },
                                ),
                              ],
                            ),

                            const SizedBox(height: 28),

                            Row(
                              children: const [
                                Expanded(child: _ThinLine()),
                                SizedBox(width: 46),
                                Expanded(child: _ThinLine()),
                                SizedBox(width: 46),
                                Expanded(child: _ThinLine()),
                              ],
                            ),

                            const Spacer(),

                            Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: SizedBox(
                                width: double.infinity,
                                height: 56,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: _buttonGreen,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(10),
                                      onTap: _onNext,
                                      child: const Center(
                                        child: Text(
                                          'التالي',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 26,
                                            fontWeight: FontWeight.w400,
                                            height: 1,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ChoicePill extends StatelessWidget {
  const _ChoicePill({
    required this.label,
    required this.selected,
    required this.selectedColor,
    required this.unselectedColor,
    required this.textColorSelected,
    required this.textColorUnselected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color selectedColor;
  final Color unselectedColor;
  final Color textColorSelected;
  final Color textColorUnselected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 84,
      height: 52,
      child: Material(
        color: selected ? selectedColor : unselectedColor,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: selected ? textColorSelected : textColorUnselected,
                fontSize: 18,
                fontWeight: FontWeight.w400,
                height: 1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ThinLine extends StatelessWidget {
  const _ThinLine();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 2,
      decoration: BoxDecoration(
        color: const Color(0xFF17D47A),
        borderRadius: BorderRadius.circular(99),
      ),
    );
  }
}
