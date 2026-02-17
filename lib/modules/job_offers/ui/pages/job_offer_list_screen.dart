import 'package:flutter/material.dart';
import 'package:opti_job_app/core/shell/core_shell.dart';

import 'package:opti_job_app/modules/job_offers/ui/containers/job_offer_list_container.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opti_job_app/modules/job_offers/cubits/job_offers_cubit.dart';

class JobOfferListScreen extends StatelessWidget {
  const JobOfferListScreen({super.key, required this.cubit});

  final JobOffersCubit cubit;

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: cubit,
      child: const CoreShell(
        variant: CoreShellVariant.public,
        body: JobOfferListContainer(),
      ),
    );
  }
}
