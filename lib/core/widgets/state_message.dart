import 'package:flutter/material.dart';

import 'package:opti_job_app/core/theme/ui_tokens.dart';

class StateMessage extends StatelessWidget {
  const StateMessage({
    super.key,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.mutedColor = uiMuted,
  });

  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Color mutedColor;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compactHeight =
            constraints.maxHeight.isFinite && constraints.maxHeight < 240;
        final compactWidth = constraints.maxWidth < 320;
        final compactLayout = compactHeight || compactWidth;
        final cardMargin = EdgeInsets.all(compactLayout ? 8 : 24);
        final cardPadding = EdgeInsets.all(compactLayout ? 12 : 24);
        final titleStyle =
            (compactLayout
                    ? Theme.of(context).textTheme.titleMedium
                    : Theme.of(context).textTheme.titleLarge)
                ?.copyWith(fontWeight: FontWeight.bold);
        final messageStyle =
            (compactLayout
                    ? Theme.of(context).textTheme.bodySmall
                    : Theme.of(context).textTheme.bodyMedium)
                ?.copyWith(color: mutedColor);
        final titleMessageSpacing = compactLayout ? 8.0 : 12.0;
        final actionSpacing = compactLayout ? 10.0 : 16.0;

        final content = ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Card(
            margin: cardMargin,
            child: Padding(
              padding: cardPadding,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(title, style: titleStyle, textAlign: TextAlign.center),
                    SizedBox(height: titleMessageSpacing),
                    Text(
                      message,
                      style: messageStyle,
                      textAlign: TextAlign.center,
                    ),
                    if (actionLabel != null && onAction != null) ...[
                      SizedBox(height: actionSpacing),
                      TextButton(
                        onPressed: onAction,
                        child: Text(actionLabel!),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );

        return Center(child: content);
      },
    );
  }
}
