import 'package:flutter/material.dart';

import 'package:opti_job_app/core/theme/ui_tokens.dart';

class OnboardingPrimaryButton extends StatefulWidget {
  const OnboardingPrimaryButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    required this.reduceMotion,
    this.enabled = true,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool reduceMotion;
  final bool enabled;

  @override
  State<OnboardingPrimaryButton> createState() =>
      _OnboardingPrimaryButtonState();
}

class _OnboardingPrimaryButtonState extends State<OnboardingPrimaryButton> {
  bool _isPressed = false;

  void _handleHighlightChanged(bool value) {
    if (!widget.enabled || widget.reduceMotion || _isPressed == value) return;
    setState(() => _isPressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final backgroundColor = widget.enabled
        ? colorScheme.primary
        : colorScheme.surfaceContainerHighest;
    final foregroundColor = widget.enabled
        ? colorScheme.onPrimary
        : colorScheme.onSurfaceVariant;
    final targetScale = widget.reduceMotion ? 1.0 : (_isPressed ? 0.97 : 1.0);

    return AnimatedScale(
      duration: const Duration(milliseconds: 100),
      curve: Curves.easeOutCubic,
      scale: targetScale,
      child: Material(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: widget.enabled ? widget.onPressed : null,
          onHighlightChanged: _handleHighlightChanged,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 172, minHeight: 56),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(widget.icon, size: 20, color: foregroundColor),
                  const SizedBox(width: uiSpacing8),
                  Flexible(
                    child: Text(
                      widget.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: foregroundColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
