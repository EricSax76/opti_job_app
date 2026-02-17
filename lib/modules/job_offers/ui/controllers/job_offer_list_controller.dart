import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opti_job_app/modules/job_offers/cubits/job_offers_cubit.dart';
import 'package:opti_job_app/modules/job_offers/logic/job_offer_list_logic.dart';

class JobOfferListController {
  const JobOfferListController._();

  static void showRefreshErrorMessage(
    BuildContext context,
    JobOffersState state,
  ) {
    final message = JobOfferListLogic.nonBlockingErrorMessage(state);
    if (message == null) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));

    context.read<JobOffersCubit>().clearErrorMessage();
  }
}
