import 'dart:ui';

import 'package:flutter/material.dart';

import 'PharmaAidGazaLanguageModeScreen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  int _currentIndex = 0;

  final List<String> _images = [
    'assets/image/Onboarding1.jpg',
    'assets/image/Onboarding2.jpg',
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _goNext() {
    if (_currentIndex < _images.length - 1) {
      setState(() {
        _currentIndex++;
      });
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const PharmaAidGazaLanguageModeScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 700),
            switchInCurve: Curves.easeInOut,
            switchOutCurve: Curves.easeInOut,
            child: AnimatedBuilder(
              key: ValueKey(_currentIndex),
              animation: _controller,
              builder: (context, child) {
                final t = _controller.value;

                return Transform.scale(
                  scale: 1.05 + (t * 0.04),
                  child: Transform.translate(
                    offset: Offset(0, -t * 10),
                    child: child,
                  ),
                );
              },
              child: Image.asset(_images[_currentIndex], fit: BoxFit.cover),
            ),
          ),

          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.18),
                  Colors.black.withOpacity(0.25),
                  Colors.black.withOpacity(0.55),
                  Colors.black.withOpacity(0.72),
                ],
              ),
            ),
          ),

          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 1.2, sigmaY: 1.2),
            child: Container(color: Colors.transparent),
          ),

          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final t = _controller.value;

              return Stack(
                children: [
                  Positioned(
                    top: 120 + (t * 18),
                    right: 30,
                    child: _GlowDot(size: 18, opacity: 0.12 + (t * 0.12)),
                  ),
                  Positioned(
                    top: 240 + ((1 - t) * 20),
                    left: 24,
                    child: _GlowDot(size: 12, opacity: 0.10 + (t * 0.10)),
                  ),
                  Positioned(
                    top: 470 + (t * 16),
                    right: 60,
                    child: _GlowDot(size: 10, opacity: 0.08 + (t * 0.08)),
                  ),
                ],
              );
            },
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: Column(
                children: [
                  const Spacer(flex: 5),

                  AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      final t = _controller.value;
                      return Opacity(
                        opacity: 0.9 + (t * 0.1),
                        child: Transform.translate(
                          offset: Offset(0, -t * 4),
                          child: child,
                        ),
                      );
                    },
                    child: Text(
                      _currentIndex == 0
                          ? 'تسوق من جميع الصيدليات\nفي البلاد'
                          : 'اكتشف كل ما تحتاجه\nفي مكان واحد',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        height: 1.25,
                        color: Colors.white,
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  Text(
                    _currentIndex == 0
                        ? 'أنواع مختلفة من الأدوية العالمية ذات الجودات العالية'
                        : 'واجهة سهلة وسريعة لتجربة أفضل',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      height: 1.5,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 18),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _Indicator(
                        active: _currentIndex == 0,
                        width: size.width * 0.22,
                      ),
                      const SizedBox(width: 14),
                      _Indicator(
                        active: _currentIndex == 1,
                        width: size.width * 0.22,
                      ),
                      const SizedBox(width: 14),
                      _Indicator(active: false, width: size.width * 0.22),
                    ],
                  ),

                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    height: 58,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF19D97B), Color(0xFF11C96D)],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF19D97B).withOpacity(0.35),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: _goNext,
                          child: Center(
                            child: Text(
                              'التالي',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Indicator extends StatelessWidget {
  const _Indicator({required this.active, required this.width});

  final bool active;
  final double width;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      width: width,
      height: 3.5,
      decoration: BoxDecoration(
        color: active
            ? const Color(0xFF18D47A)
            : Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(50),
      ),
    );
  }
}

class _GlowDot extends StatelessWidget {
  const _GlowDot({required this.size, required this.opacity});

  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(opacity),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withOpacity(opacity * 1.8),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
    );
  }
}
