import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opti_job_app/features/ai/models/ai_exceptions.dart';
import 'package:opti_job_app/features/ai/models/ai_job_offer_draft.dart';

import 'package:opti_job_app/modules/companies/controllers/offer_form_controllers.dart';
import 'package:opti_job_app/modules/companies/cubits/company_auth_cubit.dart';
import 'package:opti_job_app/modules/companies/cubits/company_offer_creation_cubit.dart';
import 'package:opti_job_app/modules/companies/logic/company_offer_creation_logic.dart';
import 'package:opti_job_app/modules/job_offers/cubits/job_offer_form_cubit.dart';
import 'package:opti_job_app/modules/job_offers/models/generate_offer_dialog.dart';

class CompanyOfferCreationController {
  const CompanyOfferCreationController._();

  static void handleJobOfferFormStatus({
    required JobOfferFormState state,
    required GlobalKey<FormState> formKey,
    required OfferFormControllers formControllers,
  }) {
    if (state.status != JobOfferFormStatus.success) return;
    formKey.currentState?.reset();
    formControllers.clear();
  }

  static void submit({
    required BuildContext context,
    required GlobalKey<FormState> formKey,
    required OfferFormControllers formControllers,
    String? pipelineId,
    List<dynamic>? pipelineStages,
    List<dynamic>? knockoutQuestions,
  }) {
    final company = context.read<CompanyAuthCubit>().state.company;
    final payload = CompanyOfferCreationLogic.buildSubmitPayload(
      formKey: formKey,
      formControllers: formControllers,
      company: company,
    );

    if (payload == null) {
      if (company == null) {
        _showMessage(
          context,
          'Debes iniciar sesión como empresa para publicar.',
        );
      }
      return;
    }

    context.read<JobOfferFormCubit>().submit(
      payload,
      pipelineId: pipelineId,
      pipelineStages: pipelineStages,
      knockoutQuestions: knockoutQuestions,
    );
  }

  static Future<void> generateWithAi({
    required BuildContext context,
    required OfferFormControllers formControllers,
  }) async {
    final cubit = context.read<CompanyOfferCreationCubit>();
    if (cubit.state.isGeneratingOffer) return;

    final company = context.read<CompanyAuthCubit>().state.company;
    if (company == null) {
      _showMessage(
        context,
        'Debes iniciar sesión como empresa para generar ofertas.',
      );
      return;
    }

    final criteria = await showDialog<Map<String, dynamic>>(
      context: context,
      useRootNavigator: false,
      builder: (_) => GenerateOfferDialog(
        companyName: company.name,
        initialRole: formControllers.title.text.trim(),
        initialLocation: formControllers.location.text.trim(),
        initialJobType: formControllers.jobType.text.trim(),
        initialSalaryMin: formControllers.salaryMin.text.trim(),
        initialSalaryMax: formControllers.salaryMax.text.trim(),
        initialEducation: formControllers.education.text.trim(),
        initialKeyIndicators: formControllers.keyIndicators.text.trim(),
      ),
    );

    if (criteria == null || !context.mounted) return;

    try {
      final draft = await cubit.generateJobOffer(criteria: criteria);
      if (draft == null || !context.mounted) return;
      _applyDraft(formControllers: formControllers, draft: draft);
      _showMessage(context, 'Borrador generado. Revisa y publica.');
    } on AiConfigurationException catch (error) {
      if (!context.mounted) return;
      _showMessage(context, error.message);
    } on AiRequestException catch (error) {
      if (!context.mounted) return;
      _showMessage(context, error.message);
    } catch (_) {
      if (!context.mounted) return;
      _showMessage(context, 'No se pudo generar la oferta con IA.');
    }
  }

  static void _applyDraft({
    required OfferFormControllers formControllers,
    required AiJobOfferDraft draft,
  }) {
    formControllers.title.text = draft.title;
    formControllers.description.text = draft.description;
    formControllers.location.text = draft.location;
    formControllers.jobType.text =
        draft.jobType ?? formControllers.jobType.text;
    formControllers.education.text =
        draft.education ?? formControllers.education.text;
    formControllers.salaryMin.text =
        draft.salaryMin ?? formControllers.salaryMin.text;
    formControllers.salaryMax.text =
        draft.salaryMax ?? formControllers.salaryMax.text;
    formControllers.keyIndicators.text =
        draft.keyIndicators ?? formControllers.keyIndicators.text;
  }

  static void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
