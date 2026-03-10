import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opti_job_app/modules/job_offers/cubits/job_offer_detail_cubit.dart';
import 'package:opti_job_app/modules/job_offers/ui/controllers/detail/job_offer_detail_loading_dialog.dart';

class JobOfferDetailMatchFlow {
  const JobOfferDetailMatchFlow._();

  static Future<void> showMatchResult(BuildContext context) async {
    await JobOfferDetailLoadingDialog.run<void>(
      context: context,
      title: 'Calculando match',
      message: 'Analizando tu CV contra la oferta...',
      action: () => context.read<JobOfferDetailCubit>().computeMatch(),
    );
  }
}
