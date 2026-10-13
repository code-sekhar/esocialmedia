import 'onboarding_cosmic_identity_screen.dart';
import 'package:esocialmedia/screen/login_screen.dart';
import 'package:flutter/material.dart';

import '../shared/widgets/gradient_button.dart';
import 'onboarding_identity_screen.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0328),

      body: SafeArea(
        child: Stack(
          children: [
            // =========================
            // BACKGROUND
            // =========================
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF9B4DCC),
                      Color(0xFF4A1680),
                      Color(0xFF120633),
                    ],
                    stops: [0.0, 0.48, 1.0],
                  ),
                ),
              ),
            ),

            // =========================
            // BACKGROUND IMAGE
            // =========================
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Image.asset(
                'assets/images/onboarding_bg.png',
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
              ),
            ),

            // =========================
            // CONTENT
            // =========================
            SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 0),
                child: Column(
                  children: [
                    const SizedBox(height: 15),

                    // Zodiac image
                    SizedBox(
                      width: double.infinity,
                      child: Image.asset(
                        'assets/images/zodiac_circle.png',
                        fit: BoxFit.fitWidth,
                      ),
                    ),

                    // const Spacer(),

                    // =========================
                    // CONTENT WITH 24px PADDING
                    // =========================
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: [
                          // =========================
                          // TITLE
                          // =========================
                          RichText(
                            textAlign: TextAlign.center,
                            text: const TextSpan(
                              text: 'Written in the ',
                              style: TextStyle(
                                fontSize: 27,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontFamily: 'Serif',
                              ),
                              children: [
                                TextSpan(
                                  text: 'stars.',
                                  style: TextStyle(
                                    color: Color(0xFFD49BFF),
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 10),

                          // =========================
                          // DESCRIPTION
                          // =========================
                          const Text(
                            'Find your soul tribe based on deep cosmic\n'
                            'alignment and birth chart synastry.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white60,
                              fontSize: 14,
                              height: 1.5,
                            ),
                          ),

                          const SizedBox(height: 32),

                          // =========================
                          // GET STARTED BUTTON
                          // =========================
                          GradientButton(
                            text: 'Continue',
                            icon: Icons.arrow_forward,
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const OnboardingCosmicIdentityScreen(),
                                ),
                              );
                            },
                          ),
                          TextButton(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    const OnboardingIdentityScreen(),
                              ),
                            ),
                            child: const Text(
                              'Explore optional astrology',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),

                          const SizedBox(height: 18),

                          // =========================
                          // SIGN IN
                          // =========================
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                "Already have an account ? ",
                                style: TextStyle(
                                  color: Colors.white60,
                                  fontSize: 13,
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const LoginScreen(),
                                    ),
                                  );
                                },
                                child: const Text(
                                  "Sign In",
                                  style: TextStyle(
                                    color: Color(0xFFD49BFF),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 25),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
