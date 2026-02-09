import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:opti_job_app/modules/candidates/models/job_offer_filters.dart';
import 'package:opti_job_app/modules/candidates/ui/widgets/job_offer_filter_sidebar.dart';

void main() {
  testWidgets(
    'syncs search, location and company fields when currentFilters changes',
    (tester) async {
      final emittedFilters = <JobOfferFilters>[];

      await tester.pumpWidget(
        _buildSidebar(
          filters: const JobOfferFilters(
            searchQuery: 'Backend',
            location: 'Madrid',
            companyName: 'Acme',
          ),
          onFiltersChanged: emittedFilters.add,
        ),
      );

      expect(_fieldText(tester, 'Buscar ofertas...'), 'Backend');
      expect(_fieldText(tester, 'Ej: Madrid, Barcelona'), 'Madrid');
      expect(_fieldText(tester, 'Nombre de la empresa'), 'Acme');

      await tester.pumpWidget(
        _buildSidebar(
          filters: const JobOfferFilters(
            searchQuery: 'Flutter',
            location: 'Sevilla',
            companyName: 'Globex',
          ),
          onFiltersChanged: emittedFilters.add,
        ),
      );
      await tester.pump();

      expect(_fieldText(tester, 'Buscar ofertas...'), 'Flutter');
      expect(_fieldText(tester, 'Ej: Madrid, Barcelona'), 'Sevilla');
      expect(_fieldText(tester, 'Nombre de la empresa'), 'Globex');
    },
  );

  testWidgets('clear button resets all text fields and emits empty filters', (
    tester,
  ) async {
    final emittedFilters = <JobOfferFilters>[];

    await tester.pumpWidget(
      _buildSidebar(
        filters: const JobOfferFilters(
          searchQuery: 'Data',
          location: 'Barcelona',
          companyName: 'Initech',
        ),
        onFiltersChanged: emittedFilters.add,
      ),
    );

    await tester.ensureVisible(find.text('Limpiar filtros'));
    await tester.tap(find.text('Limpiar filtros'));
    await tester.pump();

    expect(_fieldText(tester, 'Buscar ofertas...'), isEmpty);
    expect(_fieldText(tester, 'Ej: Madrid, Barcelona'), isEmpty);
    expect(_fieldText(tester, 'Nombre de la empresa'), isEmpty);
    expect(emittedFilters, isNotEmpty);
    expect(emittedFilters.last, const JobOfferFilters());
  });
}

Widget _buildSidebar({
  required JobOfferFilters filters,
  required ValueChanged<JobOfferFilters> onFiltersChanged,
}) {
  return MaterialApp(
    home: Scaffold(
      body: JobOfferFilterSidebar(
        currentFilters: filters,
        onFiltersChanged: onFiltersChanged,
      ),
    ),
  );
}

String _fieldText(WidgetTester tester, String hint) {
  final finder = find.byWidgetPredicate(
    (widget) => widget is TextField && widget.decoration?.hintText == hint,
  );
  final field = tester.widget<TextField>(finder);
  return field.controller?.text ?? '';
}
