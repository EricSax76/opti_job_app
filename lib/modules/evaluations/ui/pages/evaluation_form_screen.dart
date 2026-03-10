import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opti_job_app/modules/evaluations/cubits/evaluation_form_cubit.dart';
import 'package:opti_job_app/modules/evaluations/models/evaluation.dart';
import 'package:opti_job_app/modules/evaluations/models/scorecard_template.dart';
import 'package:opti_job_app/modules/evaluations/repositories/evaluation_repository.dart';
import 'package:opti_job_app/modules/evaluations/ui/widgets/evaluation_form_content.dart';

class EvaluationFormScreen extends StatelessWidget {
  const EvaluationFormScreen({
    super.key,
    required this.template,
    required this.applicationId,
    required this.jobOfferId,
    required this.companyId,
    required this.evaluatorUid,
    required this.evaluatorName,
    this.existingEvaluation,
  });

  final ScorecardTemplate template;
  final String applicationId;
  final String jobOfferId;
  final String companyId;
  final String evaluatorUid;
  final String evaluatorName;
  final Evaluation? existingEvaluation;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          EvaluationFormCubit(repository: context.read<EvaluationRepository>())
            ..init(template, existingEvaluation: existingEvaluation),
      child: BlocListener<EvaluationFormCubit, EvaluationFormState>(
        listener: (context, state) {
          if (state.status == EvaluationFormStatus.success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Evaluation submitted successfully'),
              ),
            );
            Navigator.pop(context);
          } else if (state.status == EvaluationFormStatus.failure) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to submit evaluation')),
            );
          }
        },
        child: Scaffold(
          appBar: AppBar(
            title: Text(
              existingEvaluation == null ? 'New Evaluation' : 'Edit Evaluation',
            ),
          ),
          body: EvaluationFormContent(
            applicationId: applicationId,
            jobOfferId: jobOfferId,
            companyId: companyId,
            evaluatorUid: evaluatorUid,
            evaluatorName: evaluatorName,
          ),
        ),
      ),
    );
  }
}
