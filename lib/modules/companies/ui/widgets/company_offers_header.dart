import 'package:flutter/material.dart';

class CompanyOffersHeader extends StatelessWidget {
  const CompanyOffersHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      'Mis ofertas publicadas',
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
    );
  }
}
