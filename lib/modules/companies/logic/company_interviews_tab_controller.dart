import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opti_job_app/modules/companies/cubits/company_auth_cubit.dart';
import 'package:opti_job_app/modules/interviews/cubits/interview_list_cubit.dart';

class CompanyInterviewsTabController {
  const CompanyInterviewsTabController._();

  static String? resolveCompanyUid(BuildContext context) {
    final companyUid = context.read<CompanyAuthCubit>().state.company?.uid;
    if (companyUid == null) return null;
    final normalized = companyUid.trim();
    if (normalized.isEmpty) return null;
    return normalized;
  }

  static Future<void> refresh(BuildContext context) {
    return context.read<InterviewListCubit>().refresh();
  }
}
