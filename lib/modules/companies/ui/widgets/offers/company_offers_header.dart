import 'package:flutter/material.dart';
import 'package:opti_job_app/core/widgets/section_header.dart';

class CompanyOffersHeader extends StatelessWidget {
  const CompanyOffersHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return const SectionHeader(
      tagline: 'OFERTAS',
      title: 'Mis ofertas publicadas',
      titleFontSize: 22,
    );
  }
}
