import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opti_job_app/modules/candidates/ui/widgets/dashboard_offers_grid.dart';
import 'package:opti_job_app/modules/job_offers/models/job_offer.dart';

void main() {
  testWidgets('renders wide dashboard grid cards without overflow errors', (
    tester,
  ) async {
    final offers = <JobOffer>[
      const JobOffer(
        id: 'offer-1',
        title:
            'Senior Flutter Engineer con experiencia en arquitectura escalable y equipos distribuidos',
        description:
            'Buscamos una persona con experiencia en performance, monitoreo, testing automatizado y buenas practicas de accesibilidad para producto B2B.',
        location: 'Madrid',
        companyName:
            'Empresa con nombre deliberadamente largo para stress test',
        jobType: 'Remoto',
        salaryMin: '45000',
        salaryMax: '60000',
        education: 'Grado',
        keyIndicators: 'Flutter,Arquitectura,Testing',
      ),
      const JobOffer(
        id: 'offer-2',
        title: 'Backend Engineer',
        description: 'Descripcion',
        location: 'Barcelona',
        companyName: 'Acme',
        jobType: 'Hibrido',
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 980,
            child: DashboardOffersGrid(
              status: 'success',
              offers: offers,
              companiesById: const {},
              showTwoColumns: true,
              isLoadingMore: false,
              hasMore: false,
              hasActiveFilters: false,
              onRetry: () {},
              onClearFilters: () {},
              onLoadMore: () {},
              onOfferTap: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
