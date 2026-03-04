import 'package:flutter/material.dart';
import 'package:opti_job_app/core/theme/ui_tokens.dart';
import 'package:opti_job_app/core/widgets/app_card.dart';

class ScorecardCriteriaSlider extends StatelessWidget {
  const ScorecardCriteriaSlider({
    super.key,
    required this.name,
    required this.description,
    required this.rating,
    required this.onChanged,
    this.notes,
    this.onNotesChanged,
  });

  final String name;
  final String description;
  final int rating;
  final ValueChanged<int> onChanged;
  final String? notes;
  final ValueChanged<String>? onNotesChanged;

  @override
  Widget build(BuildContext context) {
    final ratingColor = _getRatingColor(context, rating);
    final textTheme = Theme.of(context).textTheme;
    final ratingTextColor =
        ThemeData.estimateBrightnessForColor(ratingColor) == Brightness.dark
        ? Theme.of(context).colorScheme.onPrimary
        : Theme.of(context).colorScheme.onSurface;

    return AppCard(
      margin: const EdgeInsets.only(bottom: uiSpacing16),
      padding: const EdgeInsets.all(uiSpacing16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          if (description.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: uiSpacing4),
              child: Text(
                description,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          const SizedBox(height: uiSpacing16),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: rating.toDouble(),
                  min: 1,
                  max: 5,
                  divisions: 4,
                  label: rating.toString(),
                  onChanged: (value) => onChanged(value.round()),
                ),
              ),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: ratingColor,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    rating.toString(),
                    style: textTheme.labelLarge?.copyWith(
                      color: ratingTextColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (onNotesChanged != null) ...[
            const SizedBox(height: uiSpacing8),
            TextField(
              decoration: const InputDecoration(
                hintText: 'Add notes for this criterion...',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: uiSpacing12,
                  vertical: uiSpacing8,
                ),
              ),
              maxLines: 2,
              onChanged: onNotesChanged,
              controller: TextEditingController(text: notes)
                ..selection = TextSelection.collapsed(
                  offset: notes?.length ?? 0,
                ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getRatingColor(BuildContext context, int rating) {
    final scheme = Theme.of(context).colorScheme;
    switch (rating) {
      case 1:
        return scheme.error;
      case 2:
        return scheme.secondary;
      case 3:
        return scheme.primary.withValues(alpha: 0.8);
      case 4:
        return scheme.tertiary.withValues(alpha: 0.9);
      case 5:
        return scheme.tertiary;
      default:
        return scheme.outline;
    }
  }
}
