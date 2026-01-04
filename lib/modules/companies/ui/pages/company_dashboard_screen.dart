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
import 'package:opti_job_app/modules/companies/ui/widgets/company_account_avatar_menu.dart';

class CompanyDashboardScreen extends StatefulWidget {
  const CompanyDashboardScreen({super.key});

  @override
  State<CompanyDashboardScreen> createState() => _CompanyDashboardScreenState();
}

class _CompanyDashboardScreenState extends State<CompanyDashboardScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _formControllers = OfferFormControllers();
  String? _loadedCompanyUid;
  var _isGeneratingOffer = false;
  late final TabController _tabController;

  static const _background = Color(0xFFF8FAFC);
  static const _ink = Color(0xFF0F172A);
  static const _border = Color(0xFFE2E8F0);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
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
          actions: authState.isAuthenticated
              ? const [CompanyAccountAvatarMenu()]
              : null,
        ),
        body: authState.company == null
            ? const UnauthenticatedCompanyMessage()
            : Column(
                children: [
                  _CompanyDashboardNavBar(controller: _tabController),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        const CompanyHomeDashboard(),
                        ListView(
                          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                          children: [
                            CompanyDashboardHeader(
                              companyName: authState.company!.name,
                            ),
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
                        ListView(
                          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                          children: const [
                            CompanyOffersHeader(),
                            SizedBox(height: 12),
                            CompanyOffersRepositorySection(),
                          ],
                        ),
                        ListView(
                          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                          children: const [
                            CompanyCandidatesHeader(),
                            SizedBox(height: 12),
                            CompanyCandidatesSection(),
                          ],
                        ),
                      ],
                    ),
                  ),
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

    final criteria = await _showGenerateOfferDialog(
      context,
      companyName: company.name,
      initialRole: _formControllers.title.text.trim(),
      initialLocation: _formControllers.location.text.trim(),
      initialJobType: _formControllers.jobType.text.trim(),
      initialSalaryMin: _formControllers.salaryMin.text.trim(),
      initialSalaryMax: _formControllers.salaryMax.text.trim(),
      initialEducation: _formControllers.education.text.trim(),
      initialKeyIndicators: _formControllers.keyIndicators.text.trim(),
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

  Future<Map<String, dynamic>?> _showGenerateOfferDialog(
    BuildContext context, {
    required String companyName,
    String initialRole = '',
    String initialLocation = '',
    String initialJobType = '',
    String initialSalaryMin = '',
    String initialSalaryMax = '',
    String initialEducation = '',
    String initialKeyIndicators = '',
  }) {
    return showDialog<Map<String, dynamic>>(
      context: context,
      useRootNavigator: false,
      builder: (dialogContext) {
        return _GenerateOfferDialog(
          companyName: companyName,
          initialRole: initialRole,
          initialLocation: initialLocation,
          initialJobType: initialJobType,
          initialSalaryMin: initialSalaryMin,
          initialSalaryMax: initialSalaryMax,
          initialEducation: initialEducation,
          initialKeyIndicators: initialKeyIndicators,
        );
      },
    );
  }
}

class _CompanyDashboardNavBar extends StatelessWidget {
  const _CompanyDashboardNavBar({required this.controller});

  final TabController controller;

  @override
  Widget build(BuildContext context) {
    const muted = Color(0xFF64748B);
    const accent = Color(0xFF3FA7A0);
    const border = Color(0xFFE2E8F0);
    const ink = Color(0xFF0F172A);

    return Material(
      color: Colors.white,
      child: Container(
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: border, width: 1)),
        ),
        child: TabBar(
          controller: controller,
          labelColor: ink,
          unselectedLabelColor: muted,
          indicatorColor: accent,
          tabs: const [
            Tab(icon: Icon(Icons.home_outlined), text: 'Home'),
            Tab(icon: Icon(Icons.add_circle_outline), text: 'Publicar oferta'),
            Tab(icon: Icon(Icons.work_outline), text: 'Mis ofertas'),
            Tab(icon: Icon(Icons.people_outline), text: 'Candidatos'),
          ],
        ),
      ),
    );
  }
}

class _GenerateOfferDialog extends StatefulWidget {
  const _GenerateOfferDialog({
    required this.companyName,
    required this.initialRole,
    required this.initialLocation,
    required this.initialJobType,
    required this.initialSalaryMin,
    required this.initialSalaryMax,
    required this.initialEducation,
    required this.initialKeyIndicators,
  });

  final String companyName;
  final String initialRole;
  final String initialLocation;
  final String initialJobType;
  final String initialSalaryMin;
  final String initialSalaryMax;
  final String initialEducation;
  final String initialKeyIndicators;

  @override
  State<_GenerateOfferDialog> createState() => _GenerateOfferDialogState();
}

class _GenerateOfferDialogState extends State<_GenerateOfferDialog> {
  final _formKey = GlobalKey<FormState>();

  static const _fieldBackground = Color(0xFFF8FAFC);
  static const _fieldBorder = Color(0xFFE2E8F0);

  late final TextEditingController _role;
  late final TextEditingController _location;
  late final TextEditingController _jobType;
  late final TextEditingController _salaryMin;
  late final TextEditingController _salaryMax;
  late final TextEditingController _education;
  late final TextEditingController _keyIndicators;

  @override
  void initState() {
    super.initState();
    _role = TextEditingController(text: widget.initialRole);
    _location = TextEditingController(text: widget.initialLocation);
    _jobType = TextEditingController(text: widget.initialJobType);
    _salaryMin = TextEditingController(text: widget.initialSalaryMin);
    _salaryMax = TextEditingController(text: widget.initialSalaryMax);
    _education = TextEditingController(text: widget.initialEducation);
    _keyIndicators = TextEditingController(text: widget.initialKeyIndicators);
  }

  @override
  void dispose() {
    _role.dispose();
    _location.dispose();
    _jobType.dispose();
    _salaryMin.dispose();
    _salaryMax.dispose();
    _education.dispose();
    _keyIndicators.dispose();
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
                decoration: _inputDecoration(labelText: 'Título'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'El título es obligatorio';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _location,
                decoration: _inputDecoration(labelText: 'Ubicación'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'La ubicación es obligatoria';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _jobType,
                decoration: _inputDecoration(labelText: 'Tipología'),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _salaryMin,
                      keyboardType: TextInputType.number,
                      decoration: _inputDecoration(labelText: 'Salario mínimo'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _salaryMax,
                      keyboardType: TextInputType.number,
                      decoration: _inputDecoration(labelText: 'Salario máximo'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _education,
                decoration: _inputDecoration(labelText: 'Educación requerida'),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _keyIndicators,
                maxLines: 2,
                decoration: _inputDecoration(labelText: 'Indicadores clave'),
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
              'location': _location.text.trim(),
              'jobType': _jobType.text.trim(),
              'salaryMin': _salaryMin.text.trim(),
              'salaryMax': _salaryMax.text.trim(),
              'education': _education.text.trim(),
              'keyIndicators': _keyIndicators.text.trim(),
            };

            Navigator.of(context).pop(payload);
          },
          child: const Text('Generar'),
        ),
      ],
    );
  }

  static InputDecoration _inputDecoration({required String labelText}) {
    return InputDecoration(
      labelText: labelText,
      filled: true,
      fillColor: _fieldBackground,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _fieldBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _fieldBorder),
      ),
    );
  }
}
