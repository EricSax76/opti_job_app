import 'package:flutter/material.dart';

import 'package:opti_job_app/core/widgets/app_nav_bar.dart';
import 'package:opti_job_app/modules/job_offers/ui/containers/job_offer_list_container.dart';

class JobOfferListScreen extends StatelessWidget {
  const JobOfferListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppNavBar(),
      body: const JobOfferListContainer(),
    );
  }
}
