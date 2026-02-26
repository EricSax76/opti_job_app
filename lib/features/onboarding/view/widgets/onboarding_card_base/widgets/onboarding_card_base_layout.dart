import 'package:flutter/material.dart';

import 'package:opti_job_app/core/theme/ui_tokens.dart';
import 'package:opti_job_app/features/onboarding/logic/onboarding_layout_logic.dart';
import 'package:opti_job_app/features/onboarding/logic/onboarding_motion.dart';
import 'package:opti_job_app/features/onboarding/models/onboarding_card_palette.dart';
import 'package:opti_job_app/features/onboarding/models/onboarding_step_info.dart';
import 'package:opti_job_app/features/onboarding/view/widgets/onboarding_card_base/widgets/onboarding_background_orbs.dart';
import 'package:opti_job_app/features/onboarding/view/widgets/onboarding_card_base/widgets/onboarding_header_medallion.dart';
import 'package:opti_job_app/features/onboarding/view/widgets/onboarding_card_base/widgets/onboarding_step_progress.dart';
import 'package:opti_job_app/features/onboarding/view/widgets/onboarding_card_base/widgets/onboarding_surface_card.dart';

class OnboardingCardBaseLayout extends StatelessWidget {
  const OnboardingCardBaseLayout({
    super.key,
    required this.title,
    required this.message,
    required this.primaryLabel,
    required this.onPrimaryPressed,
    required this.primaryIcon,
    required this.body,
    required this.secondaryLabel,
    required this.onSecondaryPressed,
    required this.secondaryIcon,
    required this.tertiaryLabel,
    required this.onTertiaryPressed,
    required this.primaryEnabled,
    required this.showHeaderMedallion,
    required this.stepIndex,
    required this.totalSteps,
    required this.stepLabel,
    required this.maxContentWidth,
  });

  final String title;
  final String message;
  final String primaryLabel;
  final VoidCallback onPrimaryPressed;
  final IconData primaryIcon;
  final Widget? body;
  final String? secondaryLabel;
  final VoidCallback? onSecondaryPressed;
  final IconData secondaryIcon;
  final String? tertiaryLabel;
  final VoidCallback? onTertiaryPressed;
  final bool primaryEnabled;
  final bool showHeaderMedallion;
  final int? stepIndex;
  final int? totalSteps;
  final String? stepLabel;
  final double maxContentWidth;

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final reduceMotion =
        mediaQuery.disableAnimations || mediaQuery.accessibleNavigation;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final stepInfo = OnboardingStepInfo.resolve(
      stepIndex: stepIndex,
      totalSteps: totalSteps,
    );
    final palette = OnboardingCardPalette.fromTheme(theme);

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableHeight = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : mediaQuery.size.height;
        final horizontalPadding = constraints.maxWidth < uiBreakpointMobile
            ? uiSpacing20
            : uiSpacing24;
        final topGap = showHeaderMedallion
            ? OnboardingLayoutLogic.resolveTopGap(
                availableHeight: availableHeight,
              )
            : 0.0;

        Widget? medallion;
        if (showHeaderMedallion) {
          medallion = OnboardingHeaderMedallion(
            palette: palette,
            iconColor: colorScheme.primary,
          );
          medallion = applyOnboardingEntranceMotion(
            child: medallion,
            enabled: !reduceMotion,
            delay: const Duration(milliseconds: 40),
            moveYBegin: -16,
            scaleBegin: 0.94,
          );
        }

        Widget card = OnboardingSurfaceCard(
          title: title,
          message: message,
          primaryLabel: primaryLabel,
          primaryIcon: primaryIcon,
          onPrimaryPressed: onPrimaryPressed,
          body: body,
          secondaryLabel: secondaryLabel,
          onSecondaryPressed: onSecondaryPressed,
          secondaryIcon: secondaryIcon,
          tertiaryLabel: tertiaryLabel,
          onTertiaryPressed: onTertiaryPressed,
          primaryEnabled: primaryEnabled,
          reduceMotion: reduceMotion,
          palette: palette,
        );
        card = applyOnboardingEntranceMotion(
          child: card,
          enabled: !reduceMotion,
          delay: const Duration(milliseconds: 180),
          moveYBegin: 22,
        );

        Widget? progress;
        if (stepInfo != null) {
          progress = OnboardingStepProgress(
            currentStep: stepInfo.currentStep,
            totalSteps: stepInfo.totalSteps,
            label: stepLabel,
          );
          progress = applyOnboardingEntranceMotion(
            child: progress,
            enabled: !reduceMotion,
            delay: const Duration(milliseconds: 120),
            moveYBegin: 12,
          );
        }

        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [palette.gradientStart, palette.gradientEnd],
            ),
          ),
          child: Stack(
            children: [
              OnboardingBackgroundOrbs(palette: palette),
              SafeArea(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    uiSpacing20,
                    horizontalPadding,
                    uiSpacing24,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: OnboardingLayoutLogic.resolveMinContentHeight(
                        availableHeight: availableHeight,
                        mediaVerticalPadding: mediaQuery.padding.vertical,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(height: topGap),
                        if (medallion != null)
                          Align(
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth: maxContentWidth,
                              ),
                              child: medallion,
                            ),
                          ),
                        if (progress != null) ...[
                          SizedBox(
                            height: medallion == null
                                ? uiSpacing8
                                : uiSpacing20,
                          ),
                          Align(
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth: maxContentWidth,
                              ),
                              child: progress,
                            ),
                          ),
                        ],
                        const SizedBox(height: uiSpacing24),
                        Align(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: maxContentWidth,
                            ),
                            child: card,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
