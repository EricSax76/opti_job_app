import 'package:flutter/material.dart';

class CompanyDashboardNavBar extends StatelessWidget {
  const CompanyDashboardNavBar({super.key, required this.controller});

  final TabController controller;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: colorScheme.surface,
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: colorScheme.outline, width: 1),
          ),
        ),
        child: TabBar(
          controller: controller,
          labelColor: colorScheme.onSurface,
          unselectedLabelColor: colorScheme.onSurfaceVariant,
          indicatorColor: colorScheme.secondary,
          tabs: const [
            Tab(icon: Icon(Icons.home_outlined), text: 'Home'),
            Tab(icon: Icon(Icons.add_circle_outline), text: 'Publicar oferta'),
            Tab(icon: Icon(Icons.work_outline), text: 'Mis ofertas'),
            Tab(icon: Icon(Icons.people_outline), text: 'Candidatos'),
          ],
        ),
      ),
    );
  }
}
