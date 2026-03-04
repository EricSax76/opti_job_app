import 'package:flutter/material.dart';
import 'package:opti_job_app/core/widgets/state_message.dart';

class CompanyDashboardAuthenticatedBody extends StatelessWidget {
  const CompanyDashboardAuthenticatedBody({
    super.key,
    required this.selectedIndex,
    required this.tabPages,
  });

  final int selectedIndex;
  final List<Widget> tabPages;

  @override
  Widget build(BuildContext context) {
    if (tabPages.isEmpty) {
      return const StateMessage(
        title: 'Sin contenido de dashboard',
        message:
            'No hay secciones disponibles para esta cuenta en este momento.',
      );
    }

    return IndexedStack(index: selectedIndex, children: tabPages);
  }
}
