import 'package:flutter/material.dart';

class CompanyDashboardNavBar extends StatelessWidget {
  const CompanyDashboardNavBar({super.key, required this.controller});

  final TabController controller;

  @override
  Widget build(BuildContext context) {
    const muted = Color(0xFF64748B);
    const accent = Color(0xFF3FA7A0);
    const border = Color(0xFFE2E8F0);
    const ink = Color(0xFF0F172A);

    return Material(
      color: Colors.white,
      child: Container(
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: border, width: 1)),
        ),
        child: TabBar(
          controller: controller,
          labelColor: ink,
          unselectedLabelColor: muted,
          indicatorColor: accent,
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
