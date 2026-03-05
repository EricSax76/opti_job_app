import 'package:flutter/material.dart';

import 'package:opti_job_app/core/theme/ui_tokens.dart';

class AiGeneratedLabel extends StatelessWidget {
  const AiGeneratedLabel({
    super.key,
    this.compact = false,
    this.text = 'Contenido generado por IA',
    this.hint,
  });

  final bool compact;
  final String text;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = scheme.primary;
    final labelStyle = compact
        ? Theme.of(context).textTheme.labelSmall
        : Theme.of(context).textTheme.labelMedium;

    final chip = Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? uiSpacing8 : uiSpacing12,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(uiPillRadius),
        border: Border.all(color: accent.withValues(alpha: 0.32)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.auto_awesome_outlined,
            size: compact ? 14 : 16,
            color: accent,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: labelStyle?.copyWith(
                color: accent,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.1,
              ),
            ),
          ),
        ],
      ),
    );

    return Semantics(
      container: true,
      label: text,
      hint:
          hint ??
          'Resultado asistido por inteligencia artificial. Requiere validación humana.',
      child: chip,
    );
  }
}
