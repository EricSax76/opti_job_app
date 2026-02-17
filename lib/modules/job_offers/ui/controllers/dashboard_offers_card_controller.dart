import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opti_job_app/modules/companies/cubits/company_auth_cubit.dart';
import 'package:opti_job_app/modules/job_offers/cubits/company_job_offers_cubit.dart';

class DashboardOffersCardController {
  const DashboardOffersCardController._();

  static void retryLoad(BuildContext context) {
    final companyUid = context.read<CompanyAuthCubit>().state.company?.uid;
    if (companyUid == null || companyUid.trim().isEmpty) return;
    context.read<CompanyJobOffersCubit>().start(companyUid);
  }
}
