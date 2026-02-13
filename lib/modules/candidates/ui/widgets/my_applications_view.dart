import 'package:flutter/material.dart';

import 'package:opti_job_app/modules/candidates/ui/widgets/generic_applications_view.dart';

class MyApplicationsView extends StatelessWidget {
  const MyApplicationsView({super.key});

  @override
  Widget build(BuildContext context) {
    return const GenericApplicationsView(
      heroTagPrefix: 'my-applications',
      emptyTitle: 'Sin postulaciones',
      emptyMessage: 'Aún no te has postulado a ninguna oferta.',
    );
  }
}
