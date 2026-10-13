import 'package:esocialmedia/screen/onboarding_celestial_circle_screen.dart';
import 'package:flutter/material.dart';

import '../../../../shared/widgets/gradient_button.dart';
import '../../../../shared/widgets/onboarding_back_button.dart';
import '../../../../shared/widgets/onboarding_progress.dart';

class OnboardingSignScreen extends StatefulWidget {
  const OnboardingSignScreen({super.key});

  @override
  State<OnboardingSignScreen> createState() => _OnboardingSignScreenState();
}

class _OnboardingSignScreenState extends State<OnboardingSignScreen> {
  // =========================================================
  // VALUES
  // =========================================================

  final List<String> traits = [
    'Intuitive',
    'Passionate',
    'Loyal',
    'Intense',
    'Perceptive',
    'Transformative',
  ];

  final Set<String> selectedTraits = {'Intuitive', 'Passionate'};

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0328),

      body: SafeArea(
        child: Stack(
          children: [
            // =====================================================
            // BACKGROUND
            // =====================================================
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFFD178EF),
                      Color(0xFF7D1FD1),
                      Color(0xFF0D0328),
                    ],
                    stops: [0.0, 0.48, 1.0],
                  ),
                ),
              ),
            ),

            // =====================================================
            // CONTENT
            // =====================================================
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              child: Column(
                children: [
                  // =================================================
                  // TOP
                  // =================================================
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const OnboardingBackButton(),

                      const Spacer(),

                      GestureDetector(
                        onTap: () {
                          // Skip action
                        },
                        child: const Text(
                          'Skip',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // =================================================
                  // PROGRESS
                  // =================================================
                  const OnboardingProgress(currentStep: 4, totalSteps: 5),

                  const SizedBox(height: 28),

                  // =================================================
                  // SCROLLABLE CONTENT
                  // =================================================
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        children: [
                          // =========================================
                          // TITLE
                          // =========================================
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Your sign has arrived',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Serif',
                              ),
                            ),
                          ),

                          const SizedBox(height: 5),

                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Find your soul tribe based on deep cosmic\n'
                              'alignment and birth chart synastry.',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                height: 1.35,
                              ),
                            ),
                          ),

                          const SizedBox(height: 25),

                          // =========================================
                          // ZODIAC ICON
                          // =========================================
                          _zodiacIcon(),

                          const SizedBox(height: 14),

                          // =========================================
                          // SIGN NAME
                          // =========================================
                          const Text(
                            'Scorpio',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w500,
                              fontFamily: 'Serif',
                            ),
                          ),

                          const SizedBox(height: 7),

                          // =========================================
                          // SIGN INFO
                          // =========================================
                          const Text(
                            'Water  •  Pluto  •  Oct 23 – Nov 21',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white, fontSize: 14),
                          ),

                          const SizedBox(height: 28),

                          // =========================================
                          // CORE TRAITS
                          // =========================================
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Core traits',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),

                          const SizedBox(height: 9),

                          _traitsGrid(),

                          const SizedBox(height: 38),

                          // =========================================
                          // CONTINUE
                          // =========================================
                          GradientButton(
                            text: 'Continue',
                            icon: Icons.arrow_forward,
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const OnboardingCelestialCircleScreen(),
                                ),
                              );
                            },
                          ),

                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================
  // ZODIAC ICON
  // ===========================================================

  Widget _zodiacIcon() {
    return Container(
      width: 119,
      height: 119,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1.5),
      ),
      child: Container(
        width: 100,
        height: 100,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
        ),
        child: ClipOval(
          child: Image.asset(
            'assets/images/scorpio.png',
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return const Icon(
                Icons.auto_awesome,
                color: Color(0xFFB88B42),
                size: 42,
              );
            },
          ),
        ),
      ),
    );
  }

  // ===========================================================
  // TRAITS GRID
  // ===========================================================

  Widget _traitsGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: traits.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 14,
        childAspectRatio: 3.7,
      ),
      itemBuilder: (context, index) {
        final String trait = traits[index];

        return _traitItem(trait);
      },
    );
  }

  // ===========================================================
  // TRAIT ITEM
  // ===========================================================

  Widget _traitItem(String trait) {
    final bool selected = selectedTraits.contains(trait);

    return GestureDetector(
      onTap: () {
        setState(() {
          if (selected) {
            selectedTraits.remove(trait);
          } else {
            selectedTraits.add(trait);
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          gradient: selected
              ? const LinearGradient(
                  colors: [Color(0xFF9C00E8), Color(0xFFD25BFF)],
                )
              : null,
          color: selected ? null : Colors.white.withValues(alpha: 0.10),
          border: Border.all(
            color: selected
                ? const Color(0xFFD49BFF)
                : Colors.white.withValues(alpha: 0.25),
          ),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Center(
          child: Text(
            trait,
            style: TextStyle(
              color: selected ? Colors.white : Colors.white38,
              fontSize: 12,
              fontWeight: selected ? FontWeight.w500 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}
