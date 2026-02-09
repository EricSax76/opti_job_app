import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:opti_job_app/modules/candidates/ui/widgets/filters/job_offer_filter_sidebar_components.dart';
import 'package:opti_job_app/modules/candidates/ui/widgets/filters/job_offer_filter_sidebar_models.dart';
import 'package:opti_job_app/modules/candidates/ui/widgets/filters/job_offer_filter_sidebar_tokens.dart';

void main() {
  testWidgets('JobOfferFilterTextField applies style and clear action', (
    tester,
  ) async {
    var clearPressed = false;
    final controller = TextEditingController(text: 'query');
    final palette = JobOfferFilterPalette.fromTheme(ThemeData.light());

    await tester.pumpWidget(
      _wrap(
        JobOfferFilterTextField(
          palette: palette,
          hintText: 'Buscar',
          controller: controller,
          onChanged: (_) {},
          onClear: () => clearPressed = true,
          inputStyle: const JobOfferFilterInputStyle(
            hintFontSize: 16,
            borderRadius: 14,
          ),
        ),
      ),
    );

    final textField = tester.widget<TextField>(find.byType(TextField));
    expect(textField.decoration?.hintStyle?.fontSize, 16);
    final border = textField.decoration?.border as OutlineInputBorder;
    expect(border.borderRadius, BorderRadius.circular(14));

    await tester.tap(find.byIcon(Icons.clear));
    expect(clearPressed, isTrue);
  });

  testWidgets('JobOfferFilterDropdownField renders configured value', (
    tester,
  ) async {
    String? selected = 'Remoto';
    final palette = JobOfferFilterPalette.fromTheme(ThemeData.light());

    await tester.pumpWidget(
      _wrap(
        JobOfferFilterDropdownField(
          palette: palette,
          fieldKey: const ValueKey('jobType'),
          initialValue: selected,
          items: const ['Presencial', 'Remoto'],
          onChanged: (value) => selected = value,
        ),
      ),
    );

    final dropdown = tester.widget<DropdownButtonFormField<String>>(
      find.byType(DropdownButtonFormField<String>),
    );
    expect(dropdown.initialValue, 'Remoto');
  });

  testWidgets('JobOfferSalaryRangeFilter uses shared salary tokens', (
    tester,
  ) async {
    final palette = JobOfferFilterPalette.fromTheme(ThemeData.light());

    await tester.pumpWidget(
      _wrap(
        JobOfferSalaryRangeFilter(
          palette: palette,
          minSalary: 1000,
          maxSalary: 5000,
          onChanged: (_) {},
          onChangeEnd: (_) {},
        ),
      ),
    );

    final slider = tester.widget<RangeSlider>(find.byType(RangeSlider));
    expect(slider.min, JobOfferFilterSidebarTokens.minSalary);
    expect(slider.max, JobOfferFilterSidebarTokens.maxSalary);
    expect(slider.divisions, JobOfferFilterSidebarTokens.salaryDivisions);
  });
}

Widget _wrap(Widget child) {
  return MaterialApp(
    home: Scaffold(body: Center(child: child)),
  );
}
