import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:opti_job_app/features/ai/models/ai_exceptions.dart';
import 'package:opti_job_app/features/ai/models/ai_job_offer_draft.dart';
import 'package:opti_job_app/features/ai/repositories/ai_repository.dart';
import 'package:opti_job_app/modules/companies/cubits/company_auth_cubit.dart';
import 'package:opti_job_app/modules/companies/ui/widgets/company_dashboard_widgets.dart';
import 'package:opti_job_app/modules/job_offers/models/generate_offer_dialog.dart';
import 'package:opti_job_app/modules/job_offers/cubit/job_offer_form_cubit.dart';
import 'package:opti_job_app/modules/job_offers/models/job_offer_service.dart';

class CompanyOfferCreationTab extends StatefulWidget {
  const CompanyOfferCreationTab({super.key});

  @override
  State<CompanyOfferCreationTab> createState() =>
      _CompanyOfferCreationTabState();
}

class _CompanyOfferCreationTabState extends State<CompanyOfferCreationTab> {
  final _formKey = GlobalKey<FormState>();
  final _formControllers = OfferFormControllers();
  var _isGeneratingOffer = false;

  @override
  void dispose() {
    _formControllers.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final company = context.watch<CompanyAuthCubit>().state.company;

    return BlocListener<JobOfferFormCubit, JobOfferFormState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        if (state.status == JobOfferFormStatus.success) {
          _resetForm();
        }
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        children: [
          if (company != null)
            CompanyDashboardHeader(companyName: company.name),
          const SizedBox(height: 24),
          CreateOfferCard(
            formKey: _formKey,
            controllers: _formControllers,
            onSubmit: () => _submit(context),
            onGenerateWithAi: () => _generateWithAi(context),
            isGenerating: _isGeneratingOffer,
          ),
        ],
      ),
    );
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _formControllers.clear();
  }

  void _submit(BuildContext context) {
    if (!_formKey.currentState!.validate()) return;

    final company = context.read<CompanyAuthCubit>().state.company;
    if (company == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes iniciar sesión como empresa para publicar.'),
        ),
      );
      return;
    }

    context.read<JobOfferFormCubit>().submit(
      JobOfferPayload(
        title: _formControllers.title.text.trim(),
        description: _formControllers.description.text.trim(),
        location: _formControllers.location.text.trim(),
        companyId: company.id,
        companyUid: company.uid,
        companyName: company.name,
        companyAvatarUrl: company.avatarUrl,
        jobType: _formControllers.jobType.text.trim().isEmpty
            ? null
            : _formControllers.jobType.text.trim(),
        salaryMin: _formControllers.salaryMin.text.trim().isEmpty
            ? null
            : _formControllers.salaryMin.text.trim(),
        salaryMax: _formControllers.salaryMax.text.trim().isEmpty
            ? null
            : _formControllers.salaryMax.text.trim(),
        education: _formControllers.education.text.trim().isEmpty
            ? null
            : _formControllers.education.text.trim(),
        keyIndicators: _formControllers.keyIndicators.text.trim().isEmpty
            ? null
            : _formControllers.keyIndicators.text.trim(),
      ),
    );
  }

  Future<void> _generateWithAi(BuildContext context) async {
    if (_isGeneratingOffer) return;

    final company = context.read<CompanyAuthCubit>().state.company;
    if (company == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Debes iniciar sesión como empresa para generar ofertas.',
          ),
        ),
      );
      return;
    }

    final criteria = await showDialog<Map<String, dynamic>>(
      context: context,
      useRootNavigator: false,
      builder: (dialogContext) {
        return GenerateOfferDialog(
          companyName: company.name,
          initialRole: _formControllers.title.text.trim(),
          initialLocation: _formControllers.location.text.trim(),
          initialJobType: _formControllers.jobType.text.trim(),
          initialSalaryMin: _formControllers.salaryMin.text.trim(),
          initialSalaryMax: _formControllers.salaryMax.text.trim(),
          initialEducation: _formControllers.education.text.trim(),
          initialKeyIndicators: _formControllers.keyIndicators.text.trim(),
        );
      },
    );

    if (criteria == null) return;
    if (!context.mounted) return;

    setState(() => _isGeneratingOffer = true);
    try {
      final draft = await context.read<AiRepository>().generateJobOffer(
        criteria: criteria,
      );
      if (!context.mounted) return;
      _applyDraftToForm(draft);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Borrador generado. Revisa y publica.')),
      );
    } on AiConfigurationException catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } on AiRequestException catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo generar la oferta con IA.')),
      );
    } finally {
      if (mounted) setState(() => _isGeneratingOffer = false);
    }
  }

  void _applyDraftToForm(AiJobOfferDraft draft) {
    _formControllers.title.text = draft.title;
    _formControllers.description.text = draft.description;
    _formControllers.location.text = draft.location;
    _formControllers.jobType.text =
        draft.jobType ?? _formControllers.jobType.text;
    _formControllers.education.text =
        draft.education ?? _formControllers.education.text;
    _formControllers.salaryMin.text =
        draft.salaryMin ?? _formControllers.salaryMin.text;
    _formControllers.salaryMax.text =
        draft.salaryMax ?? _formControllers.salaryMax.text;
    _formControllers.keyIndicators.text =
        draft.keyIndicators ?? _formControllers.keyIndicators.text;
  }
}
