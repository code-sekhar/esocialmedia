import '../core/auth/auth_scope.dart';
import 'dashboard/home_screen.dart';
import 'dart:async';
import 'package:esocialmedia/screen/onboarding_screen.dart';
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer;
  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    _timer = Timer(const Duration(seconds: 3), () async {
      if (!mounted) return;

      final session = AuthScope.maybeOf(context);
      if (session != null) await session.restore();
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => AuthScope.maybeOf(context)?.authenticated == true
              ? const HomeScreen()
              : const OnboardingScreen(),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF10002B),
      body: SizedBox.expand(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final height = constraints.maxHeight;

            final isLandscape = width > height;

            return Stack(
              fit: StackFit.expand,
              children: [
                // =========================
                // BACKGROUND
                // =========================
                Image.asset(
                  'assets/images/onboarding_bg.png',
                  width: width,
                  height: height,
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                ),

                // =========================
                // LOGO + TEXT
                // =========================
                Center(
                  child: Transform.translate(
                    offset: Offset(0, isLandscape ? 0 : height * 0.03),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // LOGO
                        Image.asset(
                          'assets/images/logo.png',
                          width: isLandscape ? height * 0.20 : width * 0.28,
                          height: isLandscape ? height * 0.20 : width * 0.28,
                          fit: BoxFit.contain,
                        ),

                        SizedBox(
                          height: isLandscape ? height * 0.015 : height * 0.018,
                        ),

                        // TEXT
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'Eastalya',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: isLandscape
                                  ? height * 0.075
                                  : width * 0.105,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
