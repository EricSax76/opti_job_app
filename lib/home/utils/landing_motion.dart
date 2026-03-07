import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:opti_job_app/core/theme/ui_tokens.dart';

class LandingSectionReveal extends StatelessWidget {
  const LandingSectionReveal({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.slideOffset = 24.0,
  });

  final Widget child;
  final Duration delay;
  final double slideOffset;

  @override
  Widget build(BuildContext context) {
    final disabled = MediaQuery.disableAnimationsOf(context);
    if (disabled) return child;

    return child
        .animate(delay: delay)
        .fadeIn(duration: uiDurationNormal, curve: Curves.easeOutCubic)
        .moveY(
          begin: slideOffset,
          end: 0,
          duration: uiDurationSlow,
          curve: Curves.easeOutCubic,
        );
  }
}

Duration landingStaggerDelay(int index) =>
    Duration(milliseconds: 80 * index);

class LandingCardHover extends StatefulWidget {
  const LandingCardHover({super.key, required this.child});

  final Widget child;

  @override
  State<LandingCardHover> createState() => _LandingCardHoverState();
}

class _LandingCardHoverState extends State<LandingCardHover> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: AnimatedScale(
        scale: _hovering ? 1.02 : 1.0,
        duration: uiDurationFast,
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}
