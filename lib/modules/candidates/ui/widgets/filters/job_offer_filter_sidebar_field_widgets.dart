import 'package:flutter/material.dart';
import 'package:opti_job_app/core/theme/ui_tokens.dart';

import 'package:opti_job_app/modules/candidates/ui/widgets/filters/job_offer_filter_field_decorators.dart';
import 'package:opti_job_app/modules/candidates/ui/widgets/filters/job_offer_filter_sidebar_models.dart';
import 'package:opti_job_app/modules/candidates/ui/widgets/filters/job_offer_filter_sidebar_tokens.dart';

class JobOfferFilterTextField extends StatelessWidget {
  const JobOfferFilterTextField({
    super.key,
    required this.palette,
    required this.hintText,
    required this.controller,
    required this.onChanged,
    this.prefixIcon,
    this.onClear,
    this.inputStyle = const JobOfferFilterInputStyle(),
  });

  final JobOfferFilterPalette palette;
  final String hintText;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final IconData? prefixIcon;
  final VoidCallback? onClear;
  final JobOfferFilterInputStyle inputStyle;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final baseHintStyle =
        textTheme.bodyMedium ?? DefaultTextStyle.of(context).style;
    return TextField(
      controller: controller,
      decoration: JobOfferFilterFieldDecorators.inputDecoration(
        palette: palette,
        hintText: hintText,
        hintStyle: baseHintStyle,
        style: inputStyle,
        prefixIcon: prefixIcon == null
            ? null
            : Icon(prefixIcon, color: palette.muted),
        suffixIcon: onClear != null && controller.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear, size: 18),
                onPressed: onClear,
              )
            : null,
      ),
      style: textTheme.bodyMedium?.copyWith(color: palette.ink),
      onChanged: onChanged,
    );
  }
}

class JobOfferFilterDropdownField extends StatelessWidget {
  const JobOfferFilterDropdownField({
    super.key,
    required this.palette,
    required this.fieldKey,
    required this.initialValue,
    required this.items,
    required this.onChanged,
    this.inputStyle = const JobOfferFilterInputStyle(),
    this.hintText = 'Seleccionar',
    this.enabled = true,
  });

  final JobOfferFilterPalette palette;
  final Key fieldKey;
  final String? initialValue;
  final List<String> items;
  final ValueChanged<String?>? onChanged;
  final JobOfferFilterInputStyle inputStyle;
  final String hintText;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final baseHintStyle =
        textTheme.bodyMedium ?? DefaultTextStyle.of(context).style;
    return DropdownButtonFormField<String>(
      key: fieldKey,
      initialValue: initialValue,
      isExpanded: true,
      dropdownColor: palette.surface,
      decoration: JobOfferFilterFieldDecorators.inputDecoration(
        palette: palette,
        hintText: hintText,
        hintStyle: baseHintStyle,
        style: inputStyle,
      ),
      items: items
          .map(
            (item) => DropdownMenuItem<String>(
              value: item,
              child: Text(
                item,
                style: textTheme.bodyMedium?.copyWith(color: palette.ink),
              ),
            ),
          )
          .toList(growable: false),
      onChanged: enabled ? onChanged : null,
    );
  }
}

class JobOfferSalaryRangeFilter extends StatelessWidget {
  const JobOfferSalaryRangeFilter({
    super.key,
    required this.palette,
    required this.minSalary,
    required this.maxSalary,
    required this.onChanged,
    required this.onChangeEnd,
  });

  final JobOfferFilterPalette palette;
  final double minSalary;
  final double maxSalary;
  final ValueChanged<RangeValues> onChanged;
  final ValueChanged<RangeValues> onChangeEnd;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${minSalary.toInt()}€ - ${maxSalary.toInt()}€',
          style: textTheme.bodyMedium?.copyWith(
            color: palette.accent,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: uiSpacing8),
        RangeSlider(
          values: RangeValues(minSalary, maxSalary),
          min: JobOfferFilterSidebarTokens.minSalary,
          max: JobOfferFilterSidebarTokens.maxSalary,
          divisions: JobOfferFilterSidebarTokens.salaryDivisions,
          activeColor: palette.accent,
          inactiveColor: palette.border,
          labels: RangeLabels('${minSalary.toInt()}€', '${maxSalary.toInt()}€'),
          onChanged: onChanged,
          onChangeEnd: onChangeEnd,
        ),
      ],
    );
  }
}
