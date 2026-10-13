import '../../core/auth/auth_scope.dart';
import '../../core/auth/auth_models.dart';
import '../../core/l10n/auth_copy.dart';
import '../login_screen.dart';
import 'package:esocialmedia/screen/forgot/create_new_password_screen.dart';
import 'package:flutter/material.dart';

import '../../shared/widgets/gradient_button.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String email;
  final bool verification;

  const OtpVerificationScreen({
    super.key,
    required this.email,
    this.verification = false,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  // =========================================================
  // CONTROLLERS
  // =========================================================

  final List<TextEditingController> otpControllers = List.generate(
    6,
    (_) => TextEditingController(),
  );

  final List<FocusNode> otpFocusNodes = List.generate(6, (_) => FocusNode());

  // =========================================================
  // DISPOSE
  // =========================================================

  @override
  void dispose() {
    for (final controller in otpControllers) {
      controller.dispose();
    }

    for (final node in otpFocusNodes) {
      node.dispose();
    }

    super.dispose();
  }

  // =========================================================
  // OTP CHANGE
  // =========================================================

  void _onOtpChanged(String value, int index) {
    if (value.length == 1) {
      if (index < 5) {
        otpFocusNodes[index + 1].requestFocus();
      } else {
        otpFocusNodes[index].unfocus();
      }
    }
  }

  // =========================================================
  // GET OTP
  // =========================================================

  String get otp {
    return otpControllers.map((controller) => controller.text).join();
  }

  // =========================================================
  // VERIFY OTP
  // =========================================================

  bool busy = false;
  void _message(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _verifyOtp() async {
    if (busy) return;
    if (!validEmail(widget.email) || !RegExp(r'^[0-9]{6}$').hasMatch(otp)) {
      _message(AuthCopy.text('invalid'));
      return;
    }
    final session = AuthScope.of(context);
    setState(() => busy = true);
    try {
      if (widget.verification) {
        await session.verifyEmail(widget.email, otp);
        if (!mounted) return;
        _message('Email verified. Sign in to continue.');
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (_) => false,
        );
      } else {
        final token = await session.verifyReset(widget.email, otp);
        if (!mounted) return;
        for (final controller in otpControllers) {
          controller.clear();
        }
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => CreateNewPasswordScreen(resetToken: token),
          ),
        );
      }
    } catch (error) {
      if (mounted) _message(AuthCopy.error(error));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _resendOtp() async {
    if (busy) return;
    if (!validEmail(widget.email)) {
      _message('Return to sign in and enter your email first.');
      return;
    }
    final session = AuthScope.of(context);
    setState(() => busy = true);
    try {
      if (widget.verification) {
        await session.resend(widget.email);
      } else {
        await session.forgot(widget.email);
      }
      if (mounted) _message(AuthCopy.text('neutral'));
    } catch (error) {
      if (mounted) _message(AuthCopy.error(error));
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
            // BASE GRADIENT
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
            // COSMIC BACKGROUND
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
                padding: const EdgeInsets.symmetric(horizontal: 32),
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
                    // TITLE SPACE
                    // =================================================
                    const SizedBox(height: 145),

                    // =================================================
                    // TITLE
                    // =================================================
                    const Center(
                      child: Text(
                        'Verify your email',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.w400,
                          fontFamily: 'Serif',
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    // =================================================
                    // DESCRIPTION
                    // =================================================
                    Center(
                      child: Text(
                        'If eligible, check for a 6-digit code at\n'
                        '${widget.email}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 16,
                          height: 1.5,
                        ),
                      ),
                    ),

                    const SizedBox(height: 95),

                    // =================================================
                    // OTP LABEL
                    // =================================================
                    const Text('Verification code', style: _labelStyle),

                    const SizedBox(height: 14),

                    // =================================================
                    // OTP BOXES
                    // =================================================
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(6, (index) {
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            child: _otpBox(index),
                          ),
                        );
                      }),
                    ),

                    const SizedBox(height: 42),

                    // =================================================
                    // VERIFY BUTTON
                    // =================================================
                    GradientButton(
                      text: busy ? AuthCopy.text('busy') : 'Verify OTP',
                      icon: Icons.arrow_forward,
                      onPressed: busy ? null : _verifyOtp,
                    ),

                    const SizedBox(height: 30),

                    // =================================================
                    // RESEND
                    // =================================================
                    Center(
                      child: GestureDetector(
                        onTap: busy ? null : _resendOtp,
                        child: const Text(
                          'Resend OTP',
                          style: TextStyle(
                            color: Color(0xFFD49BFF),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    // =================================================
                    // CHANGE EMAIL
                    // =================================================
                    Center(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                        },
                        child: const Text(
                          'Change email address',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
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
  // OTP BOX
  // ===========================================================

  Widget _otpBox(int index) {
    return SizedBox(
      width: 50,
      height: 50,
      child: TextField(
        controller: otpControllers[index],
        focusNode: otpFocusNodes[index],

        textAlign: TextAlign.center,

        keyboardType: TextInputType.number,

        textInputAction: TextInputAction.next,

        maxLength: 1,

        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w500,
        ),

        onChanged: (value) {
          _onOtpChanged(value, index);
        },

        decoration: InputDecoration(
          counterText: '',

          filled: true,

          fillColor: Colors.white.withValues(alpha: 0.16),

          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(9),
            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.35)),
          ),

          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(9),
            borderSide: const BorderSide(color: Color(0xFFD49BFF), width: 1.5),
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
