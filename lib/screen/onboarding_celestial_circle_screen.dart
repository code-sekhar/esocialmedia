import 'package:esocialmedia/screen/dashboard/home_screen.dart';
import 'package:flutter/material.dart';

import '../../../../shared/widgets/celestial_compatibility_card.dart';
import '../../../../shared/widgets/gradient_button.dart';
import '../../../../shared/widgets/onboarding_back_button.dart';
import '../../../../shared/widgets/onboarding_progress.dart';

class OnboardingCelestialCircleScreen
    extends StatefulWidget {
  const OnboardingCelestialCircleScreen({
    super.key,
  });

  @override
  State<OnboardingCelestialCircleScreen> createState() =>
      _OnboardingCelestialCircleScreenState();
}

class _OnboardingCelestialCircleScreenState
    extends State<OnboardingCelestialCircleScreen> {
  // =========================================================
  // DATA
  // =========================================================

  final List<CelestialUser> users = [
    CelestialUser(
      name: 'Gemini',
      username: '@salena.cosmos',
      imagePath: null,
    ),

    CelestialUser(
      name: 'Gemini',
      username: '@salena.cosmos',
      imagePath: null,
    ),

    CelestialUser(
      name: 'Gemini',
      username: '@salena.cosmos',
      imagePath: null,
    ),

    CelestialUser(
      name: 'Gemini',
      username: '@salena.cosmos',
      imagePath: null,
    ),
    CelestialUser(
      name: 'Gemini',
      username: '@salena.cosmos',
      imagePath: null,
    ),

    CelestialUser(
      name: 'Gemini',
      username: '@salena.cosmos',
      imagePath: null,
    ),

    CelestialUser(
      name: 'Gemini',
      username: '@salena.cosmos',
      imagePath: null,
    ),

    CelestialUser(
      name: 'Gemini',
      username: '@salena.cosmos',
      imagePath: null,
    ),
    CelestialUser(
      name: 'Gemini',
      username: '@salena.cosmos',
      imagePath: null,
    ),

    CelestialUser(
      name: 'Gemini',
      username: '@salena.cosmos',
      imagePath: null,
    ),

    CelestialUser(
      name: 'Gemini',
      username: '@salena.cosmos',
      imagePath: null,
    ),

    CelestialUser(
      name: 'Gemini',
      username: '@salena.cosmos',
      imagePath: null,
    ),
  ];

  // =========================================================
  // FOLLOW STATE
  // =========================================================

  final Set<int> followingUsers = {};

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
                    stops: [
                      0.0,
                      0.48,
                      1.0,
                    ],
                  ),
                ),
              ),
            ),

            // =====================================================
            // CONTENT
            // =====================================================

            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 18,
              ),
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [

                  // =================================================
                  // TOP BAR
                  // =================================================

                  Row(
                    children: [
                      const OnboardingBackButton(),

                      const Spacer(),

                      GestureDetector(
                        onTap: () {
                          // Skip
                        },
                        child: const Text(
                          'Skip',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // =================================================
                  // PROGRESS
                  // =================================================

                  const OnboardingProgress(
                    currentStep: 5,
                    totalSteps: 5,
                  ),

                  const SizedBox(height: 28),

                  // =================================================
                  // TITLE
                  // =================================================

                  const Text(
                    'Find your celestial circle',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Serif',
                    ),
                  ),

                  const SizedBox(height: 5),

                  const Text(
                    'Find your soul tribe based on deep cosmic\n'
                        'alignment and birth chart synastry.',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      height: 1.35,
                    ),
                  ),

                  const SizedBox(height: 38),

                  // =================================================
                  // SORT TITLE
                  // =================================================

                  const Text(
                    'Sorted by Cosmic Compatibility',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // =================================================
                  // USER CARDS
                  // =================================================

                  Expanded(
                    child: SingleChildScrollView(
                      physics:
                      const BouncingScrollPhysics(),
                      child: Column(
                        children: [
                          ...List.generate(
                            users.length,
                                (index) {
                              final user = users[index];

                              return Padding(
                                padding:
                                const EdgeInsets.only(
                                  bottom: 10,
                                ),
                                child:
                                CelestialCompatibilityCard(
                                  name: user.name,
                                  username:
                                  user.username,
                                  imagePath:
                                  user.imagePath,
                                  isFollowing:
                                  followingUsers
                                      .contains(index),
                                  onFollow: () {
                                    setState(() {
                                      if (followingUsers
                                          .contains(index)) {
                                        followingUsers
                                            .remove(index);
                                      } else {
                                        followingUsers
                                            .add(index);
                                      }
                                    });
                                  },
                                ),
                              );
                            },
                          ),

                          const SizedBox(height: 30),

                          // =================================================
                          // COMPLETE
                          // =================================================

                          GradientButton(
                            text: 'Complete',
                            icon: Icons.arrow_forward,
                            onPressed: () {
                              debugPrint(
                                'Following users: '
                                    '$followingUsers',
                              );

                              // Navigate to home
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const HomeScreen(),
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
}

// =============================================================
// USER MODEL
// =============================================================

class CelestialUser {
  final String name;
  final String username;
  final String? imagePath;

  const CelestialUser({
    required this.name,
    required this.username,
    this.imagePath,
  });
}