import '../core/auth/auth_scope.dart';
import '../core/auth/auth_models.dart';
import '../core/l10n/auth_copy.dart';
import 'forgot/otp_verification_screen.dart';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../shared/widgets/gradient_button.dart';
import '../../../../shared/widgets/onboarding_back_button.dart';
import '../../../../shared/widgets/onboarding_progress.dart';

class OnboardingCosmicIdentityScreen extends StatefulWidget {
  const OnboardingCosmicIdentityScreen({super.key});

  @override
  State<OnboardingCosmicIdentityScreen> createState() =>
      _OnboardingCosmicIdentityScreenState();
}

class _OnboardingCosmicIdentityScreenState
    extends State<OnboardingCosmicIdentityScreen> {
  // =========================================================
  // CONTROLLERS
  // =========================================================

  final TextEditingController usernameController = TextEditingController();
  final TextEditingController nameController = TextEditingController();

  final TextEditingController emailController = TextEditingController();

  final TextEditingController passwordController = TextEditingController();

  // =========================================================
  // VALUES
  // =========================================================

  Uint8List? profileImageBytes;

  bool obscurePassword = true;

  // =========================================================
  // IMAGE PICKER
  // =========================================================

  final ImagePicker _imagePicker = ImagePicker();

  // =========================================================
  // DISPOSE
  // =========================================================

  @override
  void dispose() {
    usernameController.dispose();
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  // =========================================================
  // PICK PROFILE IMAGE
  // =========================================================

  //final ImagePicker _picker = ImagePicker();

  Future<void> pickProfileImage() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1000,
        maxHeight: 1000,
      );

      if (pickedFile == null) {
        debugPrint('User cancelled image picker');
        return;
      }

      final Uint8List bytes = await pickedFile.readAsBytes();

      if (!mounted) return;

      setState(() {
        profileImageBytes = bytes;
      });

      debugPrint('Profile image selected successfully');
    } catch (_) {
      debugPrint('Profile image selection failed');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Unable to select image. Please try again.'),
        ),
      );
    }
  }

  // =========================================================
  // BUILD
  // =========================================================

  bool busy = false;
  Future<void> _register() async {
    if (busy) return;
    if (!validEmail(emailController.text) ||
        !validPassword(passwordController.text) ||
        !RegExp(r'^[a-zA-Z0-9_]{3,30}$').hasMatch(usernameController.text) ||
        nameController.text.trim().length < 2 ||
        nameController.text.trim().length > 100) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AuthCopy.text('invalid'))));
      return;
    }
    final session = AuthScope.of(context);
    setState(() => busy = true);
    try {
      await session.register(
        Registration(
          email: emailController.text,
          username: usernameController.text,
          displayName: nameController.text.trim(),
          password: passwordController.text,
        ),
      );
      passwordController.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AuthCopy.text('neutral'))));
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OtpVerificationScreen(
            email: emailController.text.trim().toLowerCase(),
            verification: true,
          ),
        ),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // =================================================
                  // BACK BUTTON
                  // =================================================
                  const OnboardingBackButton(),

                  const SizedBox(height: 28),

                  // =================================================
                  // PROGRESS
                  // =================================================
                  const OnboardingProgress(currentStep: 3, totalSteps: 5),

                  const SizedBox(height: 28),

                  // =================================================
                  // TITLE
                  // =================================================
                  const Text(
                    'Your cosmic identity',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Serif',
                    ),
                  ),

                  const SizedBox(height: 4),

                  const Text(
                    'Your name holds vibrational frequency.\n'
                    'Choose with intention.',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      height: 1.35,
                    ),
                  ),

                  //const SizedBox(height: 25),

                  // =================================================
                  // FORM
                  // =================================================
                  Expanded(
                    child: LayoutBuilder(
                      builder: (BuildContext context, BoxConstraints constraints) {
                        return SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: constraints.maxHeight,
                            ),
                            child: IntrinsicHeight(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // =================================
                                  // PROFILE CARD
                                  // =================================
                                  _profileCard(),

                                  const SizedBox(height: 23),

                                  // =================================
                                  // NAME
                                  // =================================
                                  const Text('Your name', style: _labelStyle),

                                  const SizedBox(height: 14),

                                  _textField(
                                    controller: nameController,
                                    hint: 'Your name',
                                    onChanged: (_) {
                                      setState(() {});
                                    },
                                  ),

                                  const SizedBox(height: 23),

                                  // =================================
                                  // EMAIL
                                  // =================================
                                  const Text('Username', style: _labelStyle),
                                  const SizedBox(height: 14),
                                  _textField(
                                    controller: usernameController,
                                    hint:
                                        '3–30 letters, numbers or underscores',
                                  ),
                                  const SizedBox(height: 23),
                                  const Text(
                                    'Email Address',
                                    style: _labelStyle,
                                  ),

                                  const SizedBox(height: 14),

                                  _textField(
                                    controller: emailController,
                                    hint: 'Enter your email',
                                    keyboardType: TextInputType.emailAddress,
                                  ),

                                  const SizedBox(height: 23),

                                  // =================================
                                  // PASSWORD
                                  // =================================
                                  const Text('Password', style: _labelStyle),

                                  const SizedBox(height: 14),

                                  _passwordField(),
                                  Text(
                                    AuthCopy.text('policy'),
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),

                                  const SizedBox(height: 23),

                                  // =================================
                                  // PROFILE IMAGE
                                  // =================================
                                  const Text(
                                    'Profile Image',
                                    style: _labelStyle,
                                  ),

                                  const SizedBox(height: 14),

                                  _uploadField(),
                                  const Text(
                                    'Preview only. Add your image after signing in.',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),

                                  const SizedBox(height: 30),

                                  // =================================
                                  // CONTINUE
                                  // =================================
                                  GradientButton(
                                    text: busy
                                        ? AuthCopy.text('busy')
                                        : 'Create account',
                                    icon: Icons.arrow_forward,
                                    onPressed: busy ? null : _register,
                                  ),

                                  const SizedBox(height: 20),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
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
  // PROFILE CARD
  // ===========================================================

  Widget _profileCard() {
    final String name = nameController.text.trim();

    return Container(
      width: double.infinity,
      height: 66,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.30)),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        children: [
          // =============================================
          // PROFILE IMAGE
          // =============================================
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 1.5),
            ),
            child: ClipOval(
              child: profileImageBytes != null
                  ? Image.memory(profileImageBytes!, fit: BoxFit.cover)
                  : Image.asset(
                      'assets/images/default_profile.png',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.white12,
                          child: const Icon(
                            Icons.person,
                            color: Colors.white70,
                            size: 24,
                          ),
                        );
                      },
                    ),
            ),
          ),

          const SizedBox(width: 12),

          // =============================================
          // USER INFO
          // =============================================
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.isEmpty ? 'Your Name' : name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 3),

                const Text(
                  'Profile preview',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.white70, fontSize: 9),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================
  // TEXT FIELD
  // ===========================================================

  Widget _textField({
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
    ValueChanged<String>? onChanged,
  }) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.30)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        onChanged: onChanged,

        style: const TextStyle(color: Colors.white, fontSize: 14),

        decoration: InputDecoration(
          hintText: hint,

          hintStyle: const TextStyle(color: Colors.white60, fontSize: 12),

          border: InputBorder.none,

          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 13,
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
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.30)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextField(
        controller: passwordController,
        obscureText: obscurePassword,

        style: const TextStyle(color: Colors.white, fontSize: 14),

        decoration: InputDecoration(
          hintText: 'Password',

          hintStyle: const TextStyle(color: Colors.white60, fontSize: 12),

          border: InputBorder.none,

          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 13,
          ),

          suffixIcon: IconButton(
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
  // UPLOAD FIELD
  // ===========================================================

  Widget _uploadField() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.30)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Text(
                profileImageBytes != null
                    ? 'Image selected'
                    : 'No file selected',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: profileImageBytes != null
                      ? Colors.white
                      : Colors.white54,
                  fontSize: 12,
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.only(right: 3),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: pickProfileImage,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  height: 42,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF9C00E8), Color(0xFFD25BFF)],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.cloud_upload_outlined,
                        color: Colors.white,
                        size: 16,
                      ),
                      SizedBox(width: 5),
                      Text(
                        'Upload',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
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
    );
  }

  // ===========================================================
  // LABEL STYLE
  // ===========================================================

  static const TextStyle _labelStyle = TextStyle(
    color: Colors.white,
    fontSize: 12,
    fontWeight: FontWeight.w500,
  );
}
