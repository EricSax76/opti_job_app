import 'package:flutter/material.dart';
import 'package:opti_job_app/core/widgets/section_header.dart';

class CompanyCandidatesHeader extends StatelessWidget {
  const CompanyCandidatesHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return const SectionHeader(
      tagline: 'CANDIDATOS',
      title: 'Postulaciones por oferta',
      subtitle:
          'Expande una oferta para ver los candidatos que se han postulado.',
      titleFontSize: 22,
      titleHeight: 1.3,
    );
  }
}
