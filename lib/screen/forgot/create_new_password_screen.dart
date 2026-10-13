import '../../core/auth/auth_scope.dart';
import '../../core/auth/auth_models.dart';
import '../../core/l10n/auth_copy.dart';
import '../login_screen.dart';
import 'package:flutter/material.dart';

import '../../shared/widgets/gradient_button.dart';

class CreateNewPasswordScreen extends StatefulWidget {
  final String resetToken;
  const CreateNewPasswordScreen({super.key, this.resetToken = ''});

  @override
  State<CreateNewPasswordScreen> createState() =>
      _CreateNewPasswordScreenState();
}

class _CreateNewPasswordScreenState extends State<CreateNewPasswordScreen> {
  // =========================================================
  // CONTROLLERS
  // =========================================================

  final TextEditingController newPasswordController = TextEditingController();

  final TextEditingController confirmPasswordController =
      TextEditingController();

  // =========================================================
  // VALUES
  // =========================================================

  bool obscureNewPassword = true;

  bool obscureConfirmPassword = true;

  // =========================================================
  // DISPOSE
  // =========================================================

  @override
  void dispose() {
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  // =========================================================
  // UPDATE PASSWORD
  // =========================================================

  bool busy = false;
  Future<void> _updatePassword() async {
    if (busy) return;
    final password = newPasswordController.text;
    if (!validPassword(password) ||
        password != confirmPasswordController.text) {
      _showMessage(AuthCopy.text('policy'));
      return;
    }
    if (widget.resetToken.isEmpty) {
      _showMessage('Request and verify a new reset code first.');
      return;
    }
    final session = AuthScope.of(context);
    setState(() => busy = true);
    try {
      await session.reset(widget.resetToken, password);
      newPasswordController.clear();
      confirmPasswordController.clear();
      if (!mounted) return;
      _showMessage('Password updated. Sign in with your new password.');
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    } catch (error) {
      if (mounted) _showMessage(AuthCopy.error(error));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
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
                        'Create new password',
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
                        'Create a new password to secure your account.\n'
                        'Make sure it is strong and easy to remember.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white60,
                          fontSize: 16,
                          height: 1.5,
                        ),
                      ),
                    ),

                    // =================================================
                    // NEW PASSWORD
                    // =================================================
                    const SizedBox(height: 92),

                    const Text('New Password', style: _labelStyle),

                    const SizedBox(height: 12),

                    _passwordField(
                      controller: newPasswordController,
                      hint: 'Enter new password',
                      obscureText: obscureNewPassword,
                      onToggle: () {
                        setState(() {
                          obscureNewPassword = !obscureNewPassword;
                        });
                      },
                    ),

                    // =================================================
                    // CONFIRM PASSWORD
                    // =================================================
                    const SizedBox(height: 23),

                    const Text('Confirm Password', style: _labelStyle),

                    const SizedBox(height: 12),

                    _passwordField(
                      controller: confirmPasswordController,
                      hint: 'Confirm new password',
                      obscureText: obscureConfirmPassword,
                      onToggle: () {
                        setState(() {
                          obscureConfirmPassword = !obscureConfirmPassword;
                        });
                      },
                    ),

                    // =================================================
                    // PASSWORD HINT
                    // =================================================
                    const SizedBox(height: 12),

                    const Text(
                      'Password must be at least 8 characters.',
                      style: TextStyle(color: Colors.white54, fontSize: 12),
                    ),

                    // =================================================
                    // UPDATE BUTTON
                    // =================================================
                    const SizedBox(height: 42),

                    GradientButton(
                      text: 'Update Password',
                      icon: Icons.arrow_forward,
                      onPressed: busy ? null : _updatePassword,
                    ),

                    // =================================================
                    // BACK TO LOGIN
                    // =================================================
                    const SizedBox(height: 30),

                    Center(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.popUntil(context, (route) => route.isFirst);
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
  // PASSWORD FIELD
  // ===========================================================

  Widget _passwordField({
    required TextEditingController controller,
    required String hint,
    required bool obscureText,
    required VoidCallback onToggle,
  }) {
    return Container(
      width: double.infinity,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
        borderRadius: BorderRadius.circular(9),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,

        textInputAction: TextInputAction.done,

        style: const TextStyle(color: Colors.white, fontSize: 13),

        decoration: InputDecoration(
          border: InputBorder.none,

          // =====================================================
          // LOCK ICON
          // =====================================================
          prefixIcon: const Icon(
            Icons.lock_outline,
            color: Colors.white70,
            size: 20,
          ),

          // =====================================================
          // HINT
          // =====================================================
          hintText: hint,

          hintStyle: const TextStyle(color: Colors.white60, fontSize: 12),

          // =====================================================
          // PADDING
          // =====================================================
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 13,
          ),

          // =====================================================
          // SHOW / HIDE
          // =====================================================
          suffixIcon: IconButton(
            onPressed: onToggle,
            icon: Icon(
              obscureText
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
  // LABEL STYLE
  // ===========================================================

  static const TextStyle _labelStyle = TextStyle(
    color: Colors.white,
    fontSize: 11,
    fontWeight: FontWeight.w500,
  );
}
