import 'package:flutter/material.dart';

class OnboardingProgress extends StatelessWidget {
  final int currentStep;
  final int totalSteps;

  const OnboardingProgress({
    super.key,
    required this.currentStep,
    this.totalSteps = 5,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(
        totalSteps,
            (index) => Expanded(
          child: Container(
            height: 6,
            margin: EdgeInsets.only(
              right: index == totalSteps - 1 ? 0 : 8,
            ),
            decoration: BoxDecoration(
              color: index < currentStep
                  ? const Color(0xFF8A2BE2)
                  : Colors.white24,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ),
    );
  }
}