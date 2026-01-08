import 'package:flutter/material.dart';
import 'package:opti_job_app/core/widgets/section_header.dart';

class CompanyDashboardHeader extends StatelessWidget {
  const CompanyDashboardHeader({super.key, required this.companyName});

  final String companyName;

  @override
  Widget build(BuildContext context) {
    return SectionHeader(
      tagline: 'EMPRESAS',
      title: 'Hola, $companyName',
      subtitle: 'Publica nuevas vacantes y gestiona tus ofertas fácilmente.',
    );
  }
}
