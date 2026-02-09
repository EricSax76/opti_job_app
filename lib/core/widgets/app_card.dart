import 'package:flutter/material.dart';
import 'package:opti_job_app/core/theme/ui_tokens.dart';

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.margin,
    this.backgroundColor,
    this.gradient,
    this.borderColor,
    this.borderWidth = 1,
    this.borderRadius,
    this.boxShadow,
    this.clipBehavior = Clip.none,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;
  final Gradient? gradient;
  final Color? borderColor;
  final double borderWidth;
  final double? borderRadius;
  final List<BoxShadow>? boxShadow;
  final Clip clipBehavior;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final cardTheme = theme.cardTheme;
    final cardShape = cardTheme.shape;
    final resolvedRadius = borderRadius != null
        ? BorderRadius.circular(borderRadius!)
        : cardShape is RoundedRectangleBorder
        ? cardShape.borderRadius
        : BorderRadius.circular(uiCardRadius);
    final resolvedBorderColor =
        borderColor ??
        (cardShape is RoundedRectangleBorder
            ? cardShape.side.color
            : colorScheme.outline);

    Widget content = Padding(
      padding: padding ?? const EdgeInsets.all(uiSpacing20),
      child: child,
    );

    if (onTap != null) {
      content = InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius ?? uiCardRadius),
        child: content,
      );
    }

    final shouldClip = onTap != null || clipBehavior != Clip.none;
    final resolvedClipBehavior = clipBehavior == Clip.none
        ? Clip.antiAlias
        : clipBehavior;
    final decoratedContent = shouldClip
        ? ClipRRect(
            borderRadius: resolvedRadius,
            clipBehavior: resolvedClipBehavior,
            child: content,
          )
        : content;

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: gradient == null
            ? (backgroundColor ?? cardTheme.color ?? colorScheme.surface)
            : null,
        gradient: gradient,
        borderRadius: resolvedRadius,
        border: Border.all(color: resolvedBorderColor, width: borderWidth),
        boxShadow: boxShadow,
      ),
      child: decoratedContent,
    );
  }
}

class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.child,
    this.title,
    this.action,
    this.padding,
  });

  final Widget child;
  final String? title;
  final Widget? action;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final titleColor =
        Theme.of(context).textTheme.titleMedium?.color ?? colorScheme.onSurface;

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null || action != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                uiSpacing20,
                uiSpacing20,
                uiSpacing20,
                uiSpacing12,
              ),
              child: Row(
                children: [
                  if (title != null)
                    Expanded(
                      child: Text(
                        title!,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: titleColor,
                        ),
                      ),
                    ),
                  if (action != null) action!,
                ],
              ),
            ),
          Padding(
            padding:
                padding ??
                const EdgeInsets.fromLTRB(
                  uiSpacing20,
                  0,
                  uiSpacing20,
                  uiSpacing20,
                ),
            child: child,
          ),
        ],
      ),
    );
  }
}
