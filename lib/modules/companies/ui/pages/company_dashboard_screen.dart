import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:opti_job_app/modules/ai/models/ai_exceptions.dart';
import 'package:opti_job_app/modules/ai/models/ai_job_offer_draft.dart';
import 'package:opti_job_app/modules/ai/repositories/ai_repository.dart';
import 'package:opti_job_app/modules/companies/cubits/company_auth_cubit.dart';
import 'package:opti_job_app/modules/job_offers/cubit/job_offer_form_cubit.dart';
import 'package:opti_job_app/modules/job_offers/models/job_offer_service.dart';
import 'package:opti_job_app/modules/job_offers/cubit/company_job_offers_cubit.dart';
import 'package:opti_job_app/modules/companies/ui/widgets/company_dashboard_widgets.dart';

class CompanyDashboardScreen extends StatefulWidget {
  const CompanyDashboardScreen({super.key});

  @override
  State<CompanyDashboardScreen> createState() => _CompanyDashboardScreenState();
}

class _CompanyDashboardScreenState extends State<CompanyDashboardScreen> {
  final _formKey = GlobalKey<FormState>();
  final _formControllers = OfferFormControllers();
  String? _loadedCompanyUid;
  var _isGeneratingOffer = false;

  static const _background = Color(0xFFF8FAFC);
  static const _ink = Color(0xFF0F172A);
  static const _border = Color(0xFFE2E8F0);

  @override
  void dispose() {
    _formControllers.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final companyUid = context.read<CompanyAuthCubit>().state.company?.uid;
    if (companyUid != null && companyUid != _loadedCompanyUid) {
      _loadedCompanyUid = companyUid;
      context.read<CompanyJobOffersCubit>().loadCompanyOffers(companyUid);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<CompanyAuthCubit>().state;

    return BlocListener<JobOfferFormCubit, JobOfferFormState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        if (state.status == JobOfferFormStatus.success) {
          _resetForm();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Oferta publicada con éxito.')),
          );
          final companyUid = _loadedCompanyUid;
          if (companyUid != null) {
            context.read<CompanyJobOffersCubit>().loadCompanyOffers(companyUid);
          }
        } else if (state.status == JobOfferFormStatus.failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error al publicar la oferta. Intenta nuevamente.'),
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: _background,
        appBar: AppBar(
          title: const Text(
            'OPTIJOB',
            style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 2),
          ),
          automaticallyImplyLeading: false,
          centerTitle: true,
          backgroundColor: Colors.white,
          foregroundColor: _ink,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          shape: const Border(bottom: BorderSide(color: _border, width: 1)),
        ),
        floatingActionButton: authState.isAuthenticated
            ? FloatingActionButton(
                backgroundColor: _ink,
                foregroundColor: Colors.white,
                onPressed: () => context.read<CompanyAuthCubit>().logout(),
                tooltip: 'Cerrar sesión',
                child: const Icon(Icons.logout),
              )
            : null,
        body: authState.company == null
            ? const UnauthenticatedCompanyMessage()
            : ListView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                children: [
                  CompanyDashboardHeader(companyName: authState.company!.name),
                  const SizedBox(height: 24),
                  CreateOfferCard(
                    formKey: _formKey,
                    controllers: _formControllers,
                    onSubmit: () => _submit(context),
                    onGenerateWithAi: () => _generateWithAi(context),
                    isGenerating: _isGeneratingOffer,
                  ),
                  const SizedBox(height: 32),
                  const CompanyOffersHeader(),
                  const SizedBox(height: 12),
                  const CompanyOffersSection(),
                ],
              ),
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

    final criteria = await _showGenerateOfferDialog(
      context,
      companyName: company.name,
      initialRole: _formControllers.title.text.trim(),
      initialLocation: _formControllers.location.text.trim(),
    );
    if (criteria == null) return;
    if (!context.mounted) return;

    setState(() => _isGeneratingOffer = true);
    try {
      final locale = Localizations.localeOf(context).toLanguageTag();
      final draft = await context.read<AiRepository>().generateJobOffer(
        criteria: criteria,
        locale: locale,
        quality: (criteria['quality'] as String?) ?? 'flash',
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

  Future<Map<String, dynamic>?> _showGenerateOfferDialog(
    BuildContext context, {
    required String companyName,
    String initialRole = '',
    String initialLocation = '',
  }) {
    return showDialog<Map<String, dynamic>>(
      context: context,
      useRootNavigator: false,
      builder: (dialogContext) {
        return _GenerateOfferDialog(
          companyName: companyName,
          initialRole: initialRole,
          initialLocation: initialLocation,
        );
      },
    );
  }
}

class _GenerateOfferDialog extends StatefulWidget {
  const _GenerateOfferDialog({
    required this.companyName,
    required this.initialRole,
    required this.initialLocation,
  });

  final String companyName;
  final String initialRole;
  final String initialLocation;

  @override
  State<_GenerateOfferDialog> createState() => _GenerateOfferDialogState();
}

class _GenerateOfferDialogState extends State<_GenerateOfferDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _role;
  late final TextEditingController _seniority;
  late final TextEditingController _location;
  late final TextEditingController _stack;
  late final TextEditingController _responsibilities;
  late final TextEditingController _requirements;
  late final TextEditingController _benefits;

  String _quality = 'flash';

  @override
  void initState() {
    super.initState();
    _role = TextEditingController(text: widget.initialRole);
    _seniority = TextEditingController();
    _location = TextEditingController(text: widget.initialLocation);
    _stack = TextEditingController();
    _responsibilities = TextEditingController();
    _requirements = TextEditingController();
    _benefits = TextEditingController();
  }

  @override
  void dispose() {
    _role.dispose();
    _seniority.dispose();
    _location.dispose();
    _stack.dispose();
    _responsibilities.dispose();
    _requirements.dispose();
    _benefits.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Generar oferta con IA'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _role,
                decoration: const InputDecoration(
                  labelText: 'Puesto (ej. Flutter Developer)',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'El puesto es obligatorio';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _seniority,
                decoration: const InputDecoration(
                  labelText: 'Seniority (junior/mid/senior)',
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _location,
                decoration: const InputDecoration(
                  labelText: 'Ubicación (o remoto/híbrido)',
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _stack,
                decoration: const InputDecoration(
                  labelText: 'Stack / habilidades clave',
                  hintText: 'Flutter, Firebase, BLoC, ...',
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _responsibilities,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Responsabilidades (opcional)',
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _requirements,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Requisitos (opcional)',
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _benefits,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Beneficios (opcional)',
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _quality,
                decoration: const InputDecoration(labelText: 'Calidad (costo)'),
                items: const [
                  DropdownMenuItem(
                    value: 'flash',
                    child: Text('Flash (más barato)'),
                  ),
                  DropdownMenuItem(
                    value: 'pro',
                    child: Text('Pro (mejor calidad)'),
                  ),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _quality = value);
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            final payload = <String, dynamic>{
              'companyName': widget.companyName,
              'role': _role.text.trim(),
              'seniority': _seniority.text.trim(),
              'location': _location.text.trim(),
              'mustHaveSkills': _stack.text
                  .split(',')
                  .map((s) => s.trim())
                  .where((s) => s.isNotEmpty)
                  .toList(),
              'responsibilities': _responsibilities.text.trim(),
              'requirements': _requirements.text.trim(),
              'benefits': _benefits.text.trim(),
              'quality': _quality,
            };

            Navigator.of(context).pop(payload);
          },
          child: const Text('Generar'),
        ),
      ],
    );
  }
}
