import '../../core/auth/auth_scope.dart';
import '../../core/auth/auth_models.dart';
import '../../core/l10n/auth_copy.dart';
import '../login_screen.dart';
import 'package:flutter/material.dart';

import '../../shared/widgets/gradient_button.dart';
import 'otp_verification_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  // =========================================================
  // CONTROLLER
  // =========================================================

  final TextEditingController emailController = TextEditingController();

  // =========================================================
  // DISPOSE
  // =========================================================

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  // =========================================================
  // BUILD
  // =========================================================

  bool busy = false;
  Future<void> _send() async {
    if (busy) return;
    final email = emailController.text.trim().toLowerCase();
    if (!validEmail(email)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AuthCopy.text('invalid'))));
      return;
    }
    final session = AuthScope.of(context);
    setState(() => busy = true);
    try {
      await session.forgot(email);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AuthCopy.text('neutral'))));
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => OtpVerificationScreen(email: email)),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(AuthCopy.error(error))));
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0328),

      body: SafeArea(
        child: Stack(
          children: [
            // =====================================================
            // BASE BACKGROUND
            // =====================================================
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF9B4DCC),
                      Color(0xFF4A1680),
                      Color(0xFF0D0328),
                    ],
                    stops: [0.0, 0.48, 1.0],
                  ),
                ),
              ),
            ),

            // =====================================================
            // COSMIC IMAGE
            // =====================================================
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: MediaQuery.of(context).size.height * 0.82,
              child: Image.asset(
                'assets/images/onboarding_bg.png',
                width: double.infinity,
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
              ),
            ),

            // =====================================================
            // DARK BOTTOM OVERLAY
            // =====================================================
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.transparent,
                        Color(0x330D0328),
                        Color(0xB30D0328),
                        Color(0xFF0D0328),
                      ],
                      stops: [0.0, 0.38, 0.55, 0.72, 1.0],
                    ),
                  ),
                ),
              ),
            ),

            // =====================================================
            // CONTENT
            // =====================================================
            SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // =================================================
                    // BACK BUTTON
                    // =================================================
                    const SizedBox(height: 28),

                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),

                    // =================================================
                    // SPACE BEFORE TITLE
                    // =================================================
                    const SizedBox(height: 170),

                    // =================================================
                    // TITLE
                    // =================================================
                    const Center(
                      child: Text(
                        'Forgot password?',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.w400,
                          fontFamily: 'Serif',
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // =================================================
                    // DESCRIPTION
                    // =================================================
                    const Center(
                      child: Text(
                        'If an account is eligible, check your email\n'
                        'for a password reset code.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white60,
                          fontSize: 16,
                          height: 1.5,
                        ),
                      ),
                    ),

                    const SizedBox(height: 90),

                    // =================================================
                    // EMAIL LABEL
                    // =================================================
                    const Text('Email', style: _labelStyle),

                    const SizedBox(height: 12),

                    // =================================================
                    // EMAIL FIELD
                    // =================================================
                    _emailField(),

                    const SizedBox(height: 48),

                    // =================================================
                    // SEND OTP BUTTON
                    // =================================================
                    GradientButton(
                      text: busy ? AuthCopy.text('busy') : 'Request code',
                      icon: Icons.arrow_forward,
                      onPressed: busy ? null : _send,
                    ),

                    const SizedBox(height: 34),

                    // =================================================
                    // BACK TO LOGIN
                    // =================================================
                    Center(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const LoginScreen(),
                            ),
                            (_) => false,
                          );
                        },
                        child: const Text(
                          'Back to Login',
                          style: TextStyle(
                            color: Color(0xFFD49BFF),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    // =================================================
                    // BOTTOM SPACE
                    // =================================================
                    const SizedBox(height: 50),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================
  // EMAIL FIELD
  // ===========================================================

  Widget _emailField() {
    return Container(
      width: double.infinity,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
        borderRadius: BorderRadius.circular(9),
      ),
      child: TextField(
        controller: emailController,
        keyboardType: TextInputType.emailAddress,
        textInputAction: TextInputAction.done,
        style: const TextStyle(color: Colors.white, fontSize: 13),
        decoration: const InputDecoration(
          border: InputBorder.none,

          // EMAIL ICON
          prefixIcon: Icon(
            Icons.email_outlined,
            color: Colors.white70,
            size: 20,
          ),

          // HINT
          hintText: 'Enter your email',

          hintStyle: TextStyle(color: Colors.white60, fontSize: 12),

          // PADDING
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 13),
        ),
      ),
    );
  }

  // ===========================================================
  // LABEL STYLE
  // ===========================================================

  static const TextStyle _labelStyle = TextStyle(
    color: Colors.white,
    fontSize: 11,
    fontWeight: FontWeight.w500,
  );
}
