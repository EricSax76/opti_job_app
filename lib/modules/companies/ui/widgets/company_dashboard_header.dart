import 'package:flutter/material.dart';

class CompanyDashboardHeader extends StatelessWidget {
  const CompanyDashboardHeader({super.key, required this.companyName});

  final String companyName;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Bienvenida, $companyName',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Publica nuevas vacantes y gestiona tus ofertas fácilmente.',
        ),
      ],
    );
  }
}
