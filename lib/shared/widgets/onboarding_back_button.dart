import 'package:flutter/material.dart';

class OnboardingBackButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const OnboardingBackButton({
    super.key,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed ?? () => Navigator.pop(context),
      child: const Icon(
        Icons.arrow_back,
        color: Colors.white,
        size: 28,
      ),
    );
  }
}