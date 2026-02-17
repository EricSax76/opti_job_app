import 'package:flutter/material.dart';
import 'package:opti_job_app/core/theme/ui_tokens.dart';
import 'package:opti_job_app/core/widgets/app_nav_bar.dart';
import 'package:opti_job_app/modules/job_offers/ui/containers/job_offer_detail_container.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opti_job_app/modules/job_offers/cubits/job_offer_detail_cubit.dart';

class JobOfferDetailScreen extends StatelessWidget {
  const JobOfferDetailScreen({
    super.key,
    required this.offerId,
    required this.cubit,
  });

  final String offerId;
  final JobOfferDetailCubit cubit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final background = isDark ? uiDarkBackground : uiBackground;

    return BlocProvider.value(
      value: cubit,
      child: Scaffold(
        backgroundColor: background,
        appBar: const AppNavBar(),
        body: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          child: const JobOfferDetailContainer(),
        ),
      ),
    );
  }
}
