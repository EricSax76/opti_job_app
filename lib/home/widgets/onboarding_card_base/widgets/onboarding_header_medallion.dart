import 'package:flutter/material.dart';

import 'package:opti_job_app/home/widgets/onboarding_card_base/models/onboarding_card_palette.dart';

class OnboardingHeaderMedallion extends StatelessWidget {
  const OnboardingHeaderMedallion({
    super.key,
    required this.palette,
    required this.iconColor,
  });

  final OnboardingCardPalette palette;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 78,
      height: 78,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: palette.medallionRing, width: 1.4),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [palette.medallionStart, palette.medallionEnd],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: palette.isDark ? 0.26 : 0.08,
              ),
              offset: const Offset(0, 10),
              blurRadius: 24,
              spreadRadius: -10,
            ),
          ],
        ),
        child: Icon(Icons.auto_awesome_rounded, size: 30, color: iconColor),
      ),
    );
  }
}
