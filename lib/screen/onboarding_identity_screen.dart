import 'package:esocialmedia/screen/onboarding_cosmic_identity_screen.dart';
import 'package:flutter/material.dart';

import '../../../../shared/widgets/gradient_button.dart';
import '../shared/widgets/date_picker_field.dart';
import '../shared/widgets/onboarding_back_button.dart';
import '../shared/widgets/onboarding_progress.dart';

class OnboardingIdentityScreen extends StatefulWidget {
  const OnboardingIdentityScreen({super.key});

  @override
  State<OnboardingIdentityScreen> createState() =>
      _OnboardingIdentityScreenState();
}

class _OnboardingIdentityScreenState extends State<OnboardingIdentityScreen> {
  // =========================================================
  // CONTROLLERS
  // =========================================================

  final TextEditingController locationController = TextEditingController();

  // =========================================================
  // VALUES
  // =========================================================

  DateTime? selectedBirthDate;

  String? selectedGender;

  String? selectedBirthTimeType;

  TimeOfDay? selectedExactTime;

  // =========================================================
  // DISPOSE
  // =========================================================

  @override
  void dispose() {
    locationController.dispose();
    super.dispose();
  }

  // =========================================================
  // EXACT TIME PICKER
  // =========================================================

  Future<void> selectBirthTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: selectedExactTime ?? const TimeOfDay(hour: 12, minute: 0),
    );

    if (picked != null) {
      setState(() {
        selectedExactTime = picked;
        selectedBirthTimeType = 'Exact';
      });
    }
  }

  // =========================================================
  // FORMAT TIME
  // =========================================================

  String formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;

    final minute = time.minute.toString().padLeft(2, '0');

    final period = time.period == DayPeriod.am ? 'AM' : 'PM';

    return '$hour:$minute $period';
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
            // BACKGROUND GRADIENT
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
            // MAIN CONTENT
            // =====================================================
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // =================================================
                  // TOP SECTION
                  // FIXED AT TOP
                  // =================================================
                  const OnboardingBackButton(),

                  const SizedBox(height: 28),

                  // =================================================
                  // PROGRESS
                  // =================================================
                  const OnboardingProgress(currentStep: 2),

                  const SizedBox(height: 28),

                  // =================================================
                  // TITLE
                  // =================================================
                  const Text(
                    'When were you born?',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Serif',
                    ),
                  ),

                  const SizedBox(height: 4),

                  // =================================================
                  // DESCRIPTION
                  // =================================================
                  const Text(
                    'Your name holds vibrational frequency.\n'
                    'Choose with intention.',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                      height: 1.35,
                    ),
                  ),

                  const SizedBox(height: 25),

                  // =================================================
                  // FORM AREA
                  //
                  // Remaining available space-এর মধ্যে form
                  // vertically center হবে।
                  //
                  // Form বড় হলে scroll করবে।
                  // =================================================
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
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
                                  // DATE OF BIRTH
                                  // =================================
                                  const Text(
                                    'Date of birth',
                                    style: _labelStyle,
                                  ),

                                  const SizedBox(height: 14),

                                  DatePickerField(
                                    value: selectedBirthDate,
                                    onChanged: (date) {
                                      setState(() {
                                        selectedBirthDate = date;
                                      });
                                    },
                                  ),

                                  const SizedBox(height: 23),

                                  // =================================
                                  // BIRTH LOCATION
                                  // =================================
                                  const Text(
                                    'Birth location',
                                    style: _labelStyle,
                                  ),

                                  const SizedBox(height: 14),

                                  _textField(
                                    controller: locationController,
                                    hint: 'Country / State',
                                    suffixIcon: Icons.location_on_outlined,
                                  ),

                                  const SizedBox(height: 23),

                                  // =================================
                                  // GENDER
                                  // =================================
                                  const Text('Gender', style: _labelStyle),

                                  const SizedBox(height: 14),

                                  _genderField(),

                                  const SizedBox(height: 23),

                                  // =================================
                                  // TIME OF BIRTH
                                  // =================================
                                  const Text(
                                    'Time of birth',
                                    style: _labelStyle,
                                  ),

                                  const SizedBox(height: 14),

                                  _birthTimeSection(),

                                  const SizedBox(height: 23),

                                  // =================================
                                  // HELP TEXT
                                  // =================================
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        selectedBirthTimeType = null;
                                        selectedExactTime = null;
                                      });
                                    },
                                    child: const Text(
                                      "I don't know my exact birth time",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        decoration: TextDecoration.underline,
                                        decorationColor: Colors.white70,
                                      ),
                                    ),
                                  ),

                                  const Text(
                                    'Optional preview only. Save private birth information after sign-in from Account → Optional astrology, with explicit consent.',
                                    style: TextStyle(color: Colors.white70),
                                  ),
                                  const SizedBox(height: 30),

                                  // =================================
                                  // CONTINUE BUTTON
                                  // =================================
                                  GradientButton(
                                    text: 'Continue',
                                    icon: Icons.arrow_forward,
                                    onPressed: () {
                                      // Navigator.push(...)
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const OnboardingCosmicIdentityScreen(),
                                        ),
                                      );
                                    },
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
  // PROGRESS ITEM
  // ===========================================================

  // ===========================================================
  // TEXT FIELD
  // ===========================================================

  Widget _textField({
    required TextEditingController controller,
    required String hint,
    IconData? suffixIcon,
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

        style: const TextStyle(color: Colors.white, fontSize: 14),

        decoration: InputDecoration(
          hintText: hint,

          hintStyle: const TextStyle(color: Colors.white60, fontSize: 12),

          suffixIcon: suffixIcon != null
              ? Icon(suffixIcon, color: Colors.white70, size: 18)
              : null,

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
  // GENDER FIELD
  // ===========================================================

  Widget _genderField() {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 14),

      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.30)),
        borderRadius: BorderRadius.circular(8),
      ),

      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedGender,

          isExpanded: true,

          dropdownColor: const Color(0xFF4A1680),

          icon: const Icon(
            Icons.keyboard_arrow_down,
            color: Colors.white70,
            size: 18,
          ),

          hint: const Text(
            'Select gender',
            style: TextStyle(color: Colors.white60, fontSize: 12),
          ),

          style: const TextStyle(color: Colors.white, fontSize: 12),

          items: const [
            DropdownMenuItem(value: 'Male', child: Text('Male')),

            DropdownMenuItem(value: 'Female', child: Text('Female')),

            DropdownMenuItem(value: 'Non-binary', child: Text('Non-binary')),

            DropdownMenuItem(
              value: 'Prefer not to say',
              child: Text('Prefer not to say'),
            ),
          ],

          onChanged: (value) {
            setState(() {
              selectedGender = value;
            });
          },
        ),
      ),
    );
  }

  // ===========================================================
  // BIRTH TIME SECTION
  // ===========================================================

  Widget _birthTimeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // =====================================================
        // EXACT TIME
        // =====================================================
        GestureDetector(
          onTap: selectBirthTime,

          child: Container(
            height: 48,

            padding: const EdgeInsets.symmetric(horizontal: 14),

            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),

              border: Border.all(
                color: selectedBirthTimeType == 'Exact'
                    ? const Color(0xFFD49BFF)
                    : Colors.white.withValues(alpha: 0.30),
              ),

              borderRadius: BorderRadius.circular(8),
            ),

            child: Row(
              children: [
                Expanded(
                  child: Text(
                    selectedExactTime != null
                        ? formatTime(selectedExactTime!)
                        : 'I know my exact birth time',

                    style: TextStyle(
                      color: selectedExactTime != null
                          ? Colors.white
                          : Colors.white70,

                      fontSize: 12,
                    ),
                  ),
                ),

                const Icon(Icons.access_time, color: Colors.white70, size: 18),
              ],
            ),
          ),
        ),

        const SizedBox(height: 8),

        // =====================================================
        // APPROXIMATE TIME OPTIONS
        // =====================================================
        Column(
          children: [
            Row(
              children: [
                Expanded(child: _timeOption('Morning')),
                const SizedBox(width: 8),
                Expanded(child: _timeOption('Afternoon')),
              ],
            ),

            const SizedBox(height: 8),

            Row(
              children: [
                Expanded(child: _timeOption('Evening')),
                const SizedBox(width: 8),
                Expanded(child: _timeOption('Night')),
              ],
            ),
          ],
        ),
      ],
    );
  }

  // ===========================================================
  // TIME OPTION
  // ===========================================================

  Widget _timeOption(String value) {
    final bool selected = selectedBirthTimeType == value;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedBirthTimeType = value;
          selectedExactTime = null;
        });
      },

      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),

        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFFB55EE6)
              : Colors.white.withValues(alpha: 0.10),

          border: Border.all(
            color: selected
                ? const Color(0xFFD49BFF)
                : Colors.white.withValues(alpha: 0.25),
          ),

          borderRadius: BorderRadius.circular(8),
        ),

        child: Row(
          mainAxisSize: MainAxisSize.min,

          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,

              color: Colors.white,

              size: 15,
            ),

            const SizedBox(width: 6),

            Text(
              value,

              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ],
        ),
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
