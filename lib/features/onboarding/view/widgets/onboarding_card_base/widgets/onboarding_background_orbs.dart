import 'package:flutter/material.dart';

import 'package:opti_job_app/features/onboarding/view/widgets/onboarding_card_base/models/onboarding_card_palette.dart';

class OnboardingBackgroundOrbs extends StatelessWidget {
  const OnboardingBackgroundOrbs({super.key, required this.palette});

  final OnboardingCardPalette palette;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: -120,
            right: -80,
            child: _Orb(size: 280, color: palette.topOrbColor),
          ),
          Positioned(
            top: 240,
            left: -95,
            child: _Orb(size: 220, color: palette.sideOrbColor),
          ),
        ],
      ),
    );
  }
}

class _Orb extends StatelessWidget {
  const _Orb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
      ),
    );
  }
}
