import 'package:flutter/material.dart';
import 'package:opti_job_app/core/widgets/section_header.dart';

class DashboardHomeHeader extends StatelessWidget {
  const DashboardHomeHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return const SectionHeader(
      tagline: 'HOME',
      title: 'Dashboard',
      subtitle: 'Resumen rápido de tus ofertas y candidatos.',
    );
  }
}
