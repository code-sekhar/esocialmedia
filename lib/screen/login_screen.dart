import '../core/auth/auth_scope.dart';
import '../core/auth/auth_models.dart';
import '../core/l10n/auth_copy.dart';
import 'dashboard/home_screen.dart';
import 'forgot/otp_verification_screen.dart';
import 'package:esocialmedia/screen/forgot/forgot_password_screen.dart';
import 'package:esocialmedia/screen/onboarding_cosmic_identity_screen.dart';
import 'package:flutter/material.dart';

import '../shared/widgets/gradient_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // =========================================================
  // CONTROLLERS
  // =========================================================

  final TextEditingController emailController = TextEditingController();

  final TextEditingController passwordController = TextEditingController();

  // =========================================================
  // VALUES
  // =========================================================

  bool obscurePassword = true;
  bool rememberMe = false;

  // =========================================================
  // DISPOSE
  // =========================================================

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  bool busy = false;
  Future<void> _login() async {
    if (busy) return;
    if (!validEmail(emailController.text) ||
        !validPassword(passwordController.text, minimum: 8)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AuthCopy.text('invalid'))));
      return;
    }
    final session = AuthScope.of(context);
    setState(() => busy = true);
    try {
      await session.login(
        emailController.text,
        passwordController.text,
        remember: rememberMe,
      );
      passwordController.clear();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (_) => false,
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
              height: MediaQuery.of(context).size.height * 0.72,
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
                    // TOP SPACE
                    // =================================================
                    SizedBox(height: MediaQuery.of(context).size.height * 0.25),

                    // =================================================
                    // LOGO / TITLE
                    // =================================================
                    Center(
                      child: RichText(
                        text: const TextSpan(
                          children: [
                            TextSpan(
                              text: 'Cosmic',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 35,
                                fontWeight: FontWeight.w400,
                                fontFamily: 'Serif',
                              ),
                            ),
                            TextSpan(
                              text: 'Match',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 35,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Serif',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: MediaQuery.of(context).size.height * 0.08),

                    // =================================================
                    // EMAIL
                    // =================================================
                    const Text('Email', style: _labelStyle),

                    const SizedBox(height: 10),

                    _textField(
                      controller: emailController,
                      hint: 'Enter your email',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                    ),

                    const SizedBox(height: 16),

                    // =================================================
                    // PASSWORD
                    // =================================================
                    const Text('Password', style: _labelStyle),

                    const SizedBox(height: 10),

                    _passwordField(),

                    const SizedBox(height: 18),

                    // =================================================
                    // REMEMBER + FORGOT
                    // =================================================
                    Wrap(
                      spacing: 24,
                      runSpacing: 12,
                      children: [
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              if (AuthScope.of(context).supportsPersistence) {
                                rememberMe = !rememberMe;
                              }
                            });
                          },
                          child: Row(
                            children: [
                              Container(
                                width: 15,
                                height: 15,
                                decoration: BoxDecoration(
                                  color: rememberMe
                                      ? const Color(0xFFB52EFF)
                                      : Colors.transparent,
                                  border: Border.all(color: Colors.white70),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                child: rememberMe
                                    ? const Icon(
                                        Icons.check,
                                        color: Colors.white,
                                        size: 11,
                                      )
                                    : null,
                              ),

                              const SizedBox(width: 7),

                              const Text(
                                'Remember me',
                                style: TextStyle(
                                  color: Colors.white60,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),

                        GestureDetector(
                          onTap: () {
                            // Forgot password
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const ForgotPasswordScreen(),
                              ),
                            );
                          },

                          child: const Text(
                            'Forgot password?',
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 52),

                    // =================================================
                    // LOGIN
                    // =================================================
                    GradientButton(
                      text: busy ? AuthCopy.text('busy') : 'Log in',
                      onPressed: busy ? null : _login,
                    ),

                    if (AuthScope.of(context).logoutUnconfirmed)
                      Text(
                        AuthCopy.text('logoutUnconfirmed'),
                        style: const TextStyle(color: Colors.white70),
                      ),
                    if (!AuthScope.of(context).supportsPersistence)
                      Text(
                        AuthCopy.text('memory'),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    TextButton(
                      onPressed: busy
                          ? null
                          : () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => OtpVerificationScreen(
                                    email: emailController.text
                                        .trim()
                                        .toLowerCase(),
                                    verification: true,
                                  ),
                                ),
                              );
                            },
                      child: const Text(
                        'Verify email / request a code',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 22),

                    // =================================================
                    // SIGN UP
                    // =================================================
                    Center(
                      child: RichText(
                        text: TextSpan(
                          children: [
                            const TextSpan(
                              text: "Didn't have account ? ",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),

                            WidgetSpan(
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const OnboardingCosmicIdentityScreen(),
                                    ),
                                  );
                                },
                                child: const Text(
                                  'Sign Up',
                                  style: TextStyle(
                                    color: Color(0xFFD49BFF),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

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
  // TEXT FIELD
  // ===========================================================

  Widget _textField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
        borderRadius: BorderRadius.circular(9),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white, fontSize: 13),
        decoration: InputDecoration(
          border: InputBorder.none,

          prefixIcon: Icon(icon, color: Colors.white70, size: 18),

          hintText: hint,

          hintStyle: const TextStyle(color: Colors.white60, fontSize: 12),

          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  // ===========================================================
  // PASSWORD FIELD
  // ===========================================================

  Widget _passwordField() {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
        borderRadius: BorderRadius.circular(9),
      ),
      child: TextField(
        controller: passwordController,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _login(),
        autofillHints: const [AutofillHints.password],
        obscureText: obscurePassword,
        style: const TextStyle(color: Colors.white, fontSize: 13),
        decoration: InputDecoration(
          border: InputBorder.none,

          prefixIcon: const Icon(
            Icons.lock_outline,
            color: Colors.white70,
            size: 18,
          ),

          hintText: 'Password',

          hintStyle: const TextStyle(color: Colors.white60, fontSize: 12),

          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),

          suffixIcon: IconButton(
            tooltip: obscurePassword ? 'Show password' : 'Hide password',
            onPressed: () {
              setState(() {
                obscurePassword = !obscurePassword;
              });
            },
            icon: Icon(
              obscurePassword
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: Colors.white70,
              size: 18,
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================
  // LABEL
  // ===========================================================

  static const TextStyle _labelStyle = TextStyle(
    color: Colors.white,
    fontSize: 11,
    fontWeight: FontWeight.w500,
  );
}
