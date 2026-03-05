import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:opti_job_app/core/theme/ui_tokens.dart';
import 'package:opti_job_app/features/onboarding/cubits/candidate_onboarding_cubit.dart';
import 'package:opti_job_app/features/onboarding/cubits/candidate_onboarding_state.dart';
import 'package:opti_job_app/features/onboarding/logic/candidate_onboarding_step_view_model_factory.dart';
import 'package:opti_job_app/features/onboarding/view/widgets/onboarding_card_base/widgets/onboarding_card_base_layout.dart';
import 'package:opti_job_app/l10n/app_localizations.dart';
import 'package:opti_job_app/modules/candidates/models/candidate.dart';
import 'package:opti_job_app/modules/candidates/cubits/candidate_auth_cubit.dart'
    show CandidateAuthCubit;
import 'package:opti_job_app/modules/companies/cubits/company_auth_cubit.dart'
    show CompanyAuthCubit;
import 'package:opti_job_app/modules/companies/models/company.dart';
import 'package:opti_job_app/modules/companies/models/company_compliance_profile.dart';
import 'package:opti_job_app/modules/companies/models/company_multiposting_settings.dart';
import 'package:opti_job_app/modules/profiles/cubits/profile_cubit.dart';
import 'package:opti_job_app/modules/profiles/repositories/profile_repository.dart';

class OnboardingContainer extends StatelessWidget {
  const OnboardingContainer({super.key});

  static const CandidateOnboardingStepViewModelFactory _viewModelFactory =
      CandidateOnboardingStepViewModelFactory();
  static const double _candidateOnboardingCardMaxWidth =
      uiBreakpointMobile + uiSpacing20;
  static const double _defaultOnboardingCardMaxWidth =
      uiBreakpointMobile - uiSpacing48 - uiSpacing32;

  @override
  Widget build(BuildContext context) {
    final isCandidate = context.select(
      (CandidateAuthCubit cubit) => cubit.state.isAuthenticated,
    );
    final candidateName = context.select(
      (ProfileCubit cubit) => cubit.state.candidate?.name,
    );
    final companyName = context.select(
      (ProfileCubit cubit) => cubit.state.company?.name,
    );
    final l10n = AppLocalizations.of(context)!;

    final name = isCandidate
        ? candidateName ?? l10n.onboardingDefaultCandidateName
        : companyName ?? l10n.onboardingDefaultCompanyName;

    if (isCandidate) {
      return BlocProvider(
        create: (_) => CandidateOnboardingCubit(),
        child: BlocConsumer<CandidateOnboardingCubit, CandidateOnboardingState>(
          listenWhen: (previous, current) =>
              previous.submissionStatus != current.submissionStatus,
          listener: (context, state) {
            if (state.submissionStatus ==
                CandidateOnboardingSubmissionStatus.completed) {
              _handleConfirm(
                context,
                isCandidate: true,
                onboardingState: state,
              );
            }
          },
          builder: (context, state) {
            final cubit = context.read<CandidateOnboardingCubit>();
            final stepViewModel = _viewModelFactory.build(
              state: state,
              cubit: cubit,
              candidateName: name,
              l10n: l10n,
            );

            return _buildOnboardingCard(
              title: stepViewModel.title,
              message: stepViewModel.message,
              body: AnimatedSwitcher(
                duration: const Duration(milliseconds: 280),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInOutCubic,
                child: KeyedSubtree(
                  key: ValueKey(state.currentStep),
                  child: stepViewModel.body,
                ),
              ),
              primaryLabel: stepViewModel.primaryLabel,
              primaryIcon: stepViewModel.primaryIcon,
              onPrimaryPressed: stepViewModel.onPrimaryPressed,
              primaryEnabled: stepViewModel.primaryEnabled,
              secondaryLabel: stepViewModel.secondaryLabel,
              onSecondaryPressed: stepViewModel.onSecondaryPressed,
              tertiaryLabel: stepViewModel.tertiaryLabel,
              onTertiaryPressed: stepViewModel.onTertiaryPressed,
              showHeaderMedallion: false,
              stepIndex: state.currentStepIndex,
              totalSteps: state.totalSteps,
              stepLabel: l10n.onboardingCandidateStepProgressLabel(
                state.currentStepIndex,
                state.totalSteps,
              ),
              maxContentWidth: _candidateOnboardingCardMaxWidth,
            );
          },
        ),
      );
    }

    return _CompanyOnboardingCard(
      companyName: name,
      maxContentWidth: _defaultOnboardingCardMaxWidth,
      onSubmit: (draft) => _handleConfirm(
        context,
        isCandidate: false,
        companyOnboardingDraft: draft,
      ),
    );
  }

  Widget _buildOnboardingCard({
    required String title,
    required String message,
    required String primaryLabel,
    required VoidCallback onPrimaryPressed,
    IconData primaryIcon = Icons.check_circle_outline_rounded,
    Widget? body,
    String? secondaryLabel,
    VoidCallback? onSecondaryPressed,
    IconData secondaryIcon = Icons.skip_next_rounded,
    String? tertiaryLabel,
    VoidCallback? onTertiaryPressed,
    bool primaryEnabled = true,
    bool showHeaderMedallion = true,
    int? stepIndex,
    int? totalSteps,
    String? stepLabel,
    double maxContentWidth = _defaultOnboardingCardMaxWidth,
  }) {
    return OnboardingCardBaseLayout(
      title: title,
      message: message,
      primaryLabel: primaryLabel,
      onPrimaryPressed: onPrimaryPressed,
      primaryIcon: primaryIcon,
      body: body,
      secondaryLabel: secondaryLabel,
      onSecondaryPressed: onSecondaryPressed,
      secondaryIcon: secondaryIcon,
      tertiaryLabel: tertiaryLabel,
      onTertiaryPressed: onTertiaryPressed,
      primaryEnabled: primaryEnabled,
      showHeaderMedallion: showHeaderMedallion,
      stepIndex: stepIndex,
      totalSteps: totalSteps,
      stepLabel: stepLabel,
      maxContentWidth: maxContentWidth,
    );
  }

  Future<void> _handleConfirm(
    BuildContext context, {
    required bool isCandidate,
    CandidateOnboardingState? onboardingState,
    _CompanyOnboardingDraft? companyOnboardingDraft,
  }) async {
    if (isCandidate) {
      final candidateAuthCubit = context.read<CandidateAuthCubit>();
      final uid = candidateAuthCubit.state.candidate?.uid;
      final resolvedOnboardingState =
          onboardingState ?? context.read<CandidateOnboardingCubit>().state;
      if (uid != null && uid.isNotEmpty) {
        final profileCubit = context.read<ProfileCubit>();
        final workStyleSkipped = resolvedOnboardingState.workStyleSkipped;
        final onboardingProfile = CandidateOnboardingProfile(
          targetRole: resolvedOnboardingState.targetRole.trim(),
          preferredLocation: resolvedOnboardingState.preferredLocation.trim(),
          preferredModality: resolvedOnboardingState.preferredModality.trim(),
          preferredSeniority: resolvedOnboardingState.preferredSeniority.trim(),
          workStyleSkipped: workStyleSkipped,
          startOfDayPreference: _normalizeOptional(
            resolvedOnboardingState.startOfDayPreference,
            workStyleSkipped: workStyleSkipped,
          ),
          feedbackPreference: _normalizeOptional(
            resolvedOnboardingState.feedbackPreference,
            workStyleSkipped: workStyleSkipped,
          ),
          structurePreference: _normalizeOptional(
            resolvedOnboardingState.structurePreference,
            workStyleSkipped: workStyleSkipped,
          ),
          taskPacePreference: _normalizeOptional(
            resolvedOnboardingState.taskPacePreference,
            workStyleSkipped: workStyleSkipped,
          ),
        );
        final repository = context.read<ProfileRepository>();
        final saved = await _persistCandidateOnboardingProfile(
          repository: repository,
          uid: uid,
          onboardingProfile: onboardingProfile,
        );
        if (saved) {
          unawaited(profileCubit.refresh());
        }
      }
      if (!context.mounted) return;
      candidateAuthCubit.completeOnboarding();
      if (uid != null && uid.isNotEmpty) {
        context.go('/candidate/$uid/dashboard');
      } else {
        context.go('/CandidateDashboard');
      }
      return;
    }

    final companyAuthCubit = context.read<CompanyAuthCubit>();
    final uid = companyAuthCubit.state.company?.uid;
    final company = companyAuthCubit.state.company;
    if (company != null &&
        uid != null &&
        uid.isNotEmpty &&
        companyOnboardingDraft != null) {
      final repository = context.read<ProfileRepository>();
      final updatedCompany = await _persistCompanyOnboardingProfile(
        repository: repository,
        company: company,
        draft: companyOnboardingDraft,
      );
      if (updatedCompany != null) {
        companyAuthCubit.updateCompany(updatedCompany);
      }
    }

    if (!context.mounted) return;
    companyAuthCubit.completeOnboarding();
    if (uid != null && uid.isNotEmpty) {
      context.go('/company/$uid/dashboard');
      return;
    }
    context.go('/DashboardCompany');
  }

  String? _normalizeOptional(String value, {required bool workStyleSkipped}) {
    if (workStyleSkipped) return null;
    final normalized = value.trim();
    if (normalized.isEmpty) return null;
    return normalized;
  }

  Future<bool> _persistCandidateOnboardingProfile({
    required ProfileRepository repository,
    required String uid,
    required CandidateOnboardingProfile onboardingProfile,
  }) async {
    try {
      await repository
          .saveCandidateOnboardingProfile(
            uid: uid,
            onboardingProfile: onboardingProfile,
          )
          .timeout(const Duration(seconds: 8));
      return true;
    } catch (_) {
      // If onboarding profile save fails, we still complete onboarding navigation.
      return false;
    }
  }

  Future<Company?> _persistCompanyOnboardingProfile({
    required ProfileRepository repository,
    required Company company,
    required _CompanyOnboardingDraft draft,
  }) async {
    try {
      final updated = await repository
          .updateCompanyProfile(
            uid: company.uid,
            name: company.name.trim(),
            website: draft.website,
            industry: draft.industry,
            teamSize: draft.teamSize,
            headquarters: draft.headquarters,
            description: draft.description,
            multipostingSettings: CompanyMultipostingSettings(
              enabledChannels: draft.enabledMultipostingChannels,
              costOverridesEur: company.multipostingSettings.costOverridesEur,
            ),
            complianceProfile: CompanyComplianceProfile(
              controllerLegalName: draft.controllerLegalName,
              controllerTaxId: draft.controllerTaxId,
              privacyContactEmail: draft.privacyContactEmail,
              dpoName: draft.dpoName,
              dpoEmail: draft.dpoEmail,
              privacyPolicyUrl: draft.privacyPolicyUrl,
              retentionPolicySummary: draft.retentionPolicySummary,
              internationalTransfersSummary:
                  draft.internationalTransfersSummary,
              aiConsentTextVersion: draft.aiConsentTextVersion,
              aiConsentText: draft.aiConsentText,
            ),
          )
          .timeout(const Duration(seconds: 8));

      return Company(
        id: updated.id,
        name: updated.name,
        email: updated.email,
        uid: updated.uid,
        role: updated.role,
        onboardingCompleted: company.onboardingCompleted,
        website: updated.website,
        industry: updated.industry,
        teamSize: updated.teamSize,
        headquarters: updated.headquarters,
        description: updated.description,
        multipostingSettings: updated.multipostingSettings,
        complianceProfile: updated.complianceProfile,
        token: company.token,
        avatarUrl: updated.avatarUrl,
      );
    } catch (_) {
      // If company profile save fails, onboarding keeps moving to avoid lockout.
      return null;
    }
  }
}

class _CompanyOnboardingDraft {
  const _CompanyOnboardingDraft({
    required this.website,
    required this.industry,
    required this.teamSize,
    required this.headquarters,
    required this.description,
    required this.controllerLegalName,
    required this.controllerTaxId,
    required this.privacyContactEmail,
    required this.dpoName,
    required this.dpoEmail,
    required this.privacyPolicyUrl,
    required this.retentionPolicySummary,
    required this.internationalTransfersSummary,
    required this.aiConsentTextVersion,
    required this.aiConsentText,
    required this.enabledMultipostingChannels,
  });

  final String website;
  final String industry;
  final String teamSize;
  final String headquarters;
  final String description;
  final String controllerLegalName;
  final String controllerTaxId;
  final String privacyContactEmail;
  final String dpoName;
  final String dpoEmail;
  final String privacyPolicyUrl;
  final String retentionPolicySummary;
  final String internationalTransfersSummary;
  final String aiConsentTextVersion;
  final String aiConsentText;
  final List<String> enabledMultipostingChannels;
}

class _CompanyOnboardingCard extends StatefulWidget {
  const _CompanyOnboardingCard({
    required this.companyName,
    required this.maxContentWidth,
    required this.onSubmit,
  });

  final String companyName;
  final double maxContentWidth;
  final Future<void> Function(_CompanyOnboardingDraft draft) onSubmit;

  @override
  State<_CompanyOnboardingCard> createState() => _CompanyOnboardingCardState();
}

class _CompanyOnboardingCardState extends State<_CompanyOnboardingCard> {
  static final RegExp _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  final _formKey = GlobalKey<FormState>();
  final _websiteController = TextEditingController();
  final _industryController = TextEditingController();
  final _teamSizeController = TextEditingController();
  final _headquartersController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _controllerLegalNameController = TextEditingController();
  final _controllerTaxIdController = TextEditingController();
  final _privacyContactEmailController = TextEditingController();
  final _dpoNameController = TextEditingController();
  final _dpoEmailController = TextEditingController();
  final _privacyPolicyUrlController = TextEditingController();
  final _retentionPolicySummaryController = TextEditingController();
  final _internationalTransfersSummaryController = TextEditingController();
  final _aiConsentTextVersionController = TextEditingController(
    text: '2026.04',
  );
  final _aiConsentTextController = TextEditingController(
    text: const CompanyComplianceProfile().aiConsentText,
  );
  late final Set<String> _enabledChannels;
  var _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _enabledChannels = {...companyDefaultMultipostingChannels};
  }

  @override
  void dispose() {
    _websiteController.dispose();
    _industryController.dispose();
    _teamSizeController.dispose();
    _headquartersController.dispose();
    _descriptionController.dispose();
    _controllerLegalNameController.dispose();
    _controllerTaxIdController.dispose();
    _privacyContactEmailController.dispose();
    _dpoNameController.dispose();
    _dpoEmailController.dispose();
    _privacyPolicyUrlController.dispose();
    _retentionPolicySummaryController.dispose();
    _internationalTransfersSummaryController.dispose();
    _aiConsentTextVersionController.dispose();
    _aiConsentTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingCardBaseLayout(
      title: 'Hola, ${widget.companyName} 👋',
      message:
          'Antes de continuar, necesitamos algunos datos para configurar tus ajustes de empresa.',
      primaryLabel: _isSubmitting ? 'Guardando...' : 'Completar configuracion',
      onPrimaryPressed: _handlePrimaryPressed,
      primaryIcon: Icons.settings_outlined,
      secondaryLabel: null,
      onSecondaryPressed: null,
      secondaryIcon: Icons.skip_next_rounded,
      tertiaryLabel: null,
      onTertiaryPressed: null,
      primaryEnabled: !_isSubmitting,
      showHeaderMedallion: false,
      stepIndex: null,
      totalSteps: null,
      stepLabel: null,
      maxContentWidth: widget.maxContentWidth,
      body: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _websiteController,
              decoration: const InputDecoration(
                labelText: 'Sitio web',
                hintText: 'https://tuempresa.com',
              ),
            ),
            const SizedBox(height: uiSpacing12),
            TextFormField(
              controller: _industryController,
              decoration: const InputDecoration(labelText: 'Sector'),
              validator: (value) {
                if ((value ?? '').trim().isEmpty) {
                  return 'Indica el sector de la empresa.';
                }
                return null;
              },
            ),
            const SizedBox(height: uiSpacing12),
            TextFormField(
              controller: _teamSizeController,
              decoration: const InputDecoration(
                labelText: 'Tamano del equipo',
                hintText: '1-10, 11-50, 51-200...',
              ),
              validator: (value) {
                if ((value ?? '').trim().isEmpty) {
                  return 'Indica el tamano aproximado del equipo.';
                }
                return null;
              },
            ),
            const SizedBox(height: uiSpacing12),
            TextFormField(
              controller: _headquartersController,
              decoration: const InputDecoration(labelText: 'Sede principal'),
              validator: (value) {
                if ((value ?? '').trim().isEmpty) {
                  return 'Indica la sede principal.';
                }
                return null;
              },
            ),
            const SizedBox(height: uiSpacing12),
            TextFormField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Descripcion breve',
                hintText: 'Describe cultura, producto y forma de trabajo.',
              ),
            ),
            const SizedBox(height: uiSpacing16),
            Text(
              'Cumplimiento LGPD',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: uiSpacing8),
            TextFormField(
              controller: _controllerLegalNameController,
              decoration: const InputDecoration(
                labelText: 'Razón social del responsable',
              ),
              validator: (value) {
                if ((value ?? '').trim().isEmpty) {
                  return 'Indica la razón social responsable del tratamiento.';
                }
                return null;
              },
            ),
            const SizedBox(height: uiSpacing12),
            TextFormField(
              controller: _controllerTaxIdController,
              decoration: const InputDecoration(
                labelText: 'Identificador fiscal (CNPJ/NIF)',
              ),
              validator: (value) {
                if ((value ?? '').trim().isEmpty) {
                  return 'Indica el identificador fiscal del responsable.';
                }
                return null;
              },
            ),
            const SizedBox(height: uiSpacing12),
            TextFormField(
              controller: _privacyContactEmailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email de privacidad',
              ),
              validator: (value) {
                final normalized = (value ?? '').trim();
                if (normalized.isEmpty || !_emailPattern.hasMatch(normalized)) {
                  return 'Introduce un email de privacidad válido.';
                }
                return null;
              },
            ),
            const SizedBox(height: uiSpacing12),
            TextFormField(
              controller: _dpoNameController,
              decoration: const InputDecoration(labelText: 'Encargado/DPO'),
              validator: (value) {
                if ((value ?? '').trim().isEmpty) {
                  return 'Indica el nombre del encargado/DPO.';
                }
                return null;
              },
            ),
            const SizedBox(height: uiSpacing12),
            TextFormField(
              controller: _dpoEmailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email del encargado/DPO',
              ),
              validator: (value) {
                final normalized = (value ?? '').trim();
                if (normalized.isEmpty || !_emailPattern.hasMatch(normalized)) {
                  return 'Introduce un email del encargado/DPO válido.';
                }
                return null;
              },
            ),
            const SizedBox(height: uiSpacing12),
            TextFormField(
              controller: _privacyPolicyUrlController,
              decoration: const InputDecoration(
                labelText: 'URL política de privacidad',
                hintText: 'https://tuempresa.com/privacidad',
              ),
              validator: (value) {
                if ((value ?? '').trim().isEmpty) {
                  return 'Indica la URL de la política de privacidad.';
                }
                return null;
              },
            ),
            const SizedBox(height: uiSpacing12),
            TextFormField(
              controller: _retentionPolicySummaryController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Resumen de retención',
              ),
              validator: (value) {
                if ((value ?? '').trim().isEmpty) {
                  return 'Indica la política de retención aplicable.';
                }
                return null;
              },
            ),
            const SizedBox(height: uiSpacing12),
            TextFormField(
              controller: _internationalTransfersSummaryController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Transferencias internacionales',
                hintText: 'Describe salvaguardas o indica que no aplican.',
              ),
            ),
            const SizedBox(height: uiSpacing12),
            TextFormField(
              controller: _aiConsentTextVersionController,
              decoration: const InputDecoration(
                labelText: 'Versión texto consentimiento IA',
                hintText: '2026.04',
              ),
              validator: (value) {
                if ((value ?? '').trim().isEmpty) {
                  return 'Indica la versión del texto de consentimiento IA.';
                }
                return null;
              },
            ),
            const SizedBox(height: uiSpacing12),
            TextFormField(
              controller: _aiConsentTextController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Texto consentimiento IA',
              ),
              validator: (value) {
                if ((value ?? '').trim().isEmpty) {
                  return 'Indica el texto de consentimiento IA.';
                }
                return null;
              },
            ),
            const SizedBox(height: uiSpacing16),
            Text(
              'Canales de multiposting por defecto (opcional)',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: uiSpacing8),
            ...companyMultipostingChannelCatalog.map((channel) {
              final enabled = _enabledChannels.contains(channel.id);
              return CheckboxListTile.adaptive(
                value: enabled,
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: Text(channel.label),
                subtitle: Text(
                  'Coste base estimado: €${channel.defaultCostEur.toStringAsFixed(0)}',
                ),
                onChanged: _isSubmitting
                    ? null
                    : (value) {
                        setState(() {
                          if (value == true) {
                            _enabledChannels.add(channel.id);
                          } else {
                            _enabledChannels.remove(channel.id);
                          }
                        });
                      },
              );
            }),
          ],
        ),
      ),
    );
  }

  void _handlePrimaryPressed() {
    if (_isSubmitting) return;
    unawaited(_submit());
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;

    final formState = _formKey.currentState;
    if (formState == null || !formState.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      await widget.onSubmit(
        _CompanyOnboardingDraft(
          website: _websiteController.text.trim(),
          industry: _industryController.text.trim(),
          teamSize: _teamSizeController.text.trim(),
          headquarters: _headquartersController.text.trim(),
          description: _descriptionController.text.trim(),
          controllerLegalName: _controllerLegalNameController.text.trim(),
          controllerTaxId: _controllerTaxIdController.text.trim(),
          privacyContactEmail: _privacyContactEmailController.text.trim(),
          dpoName: _dpoNameController.text.trim(),
          dpoEmail: _dpoEmailController.text.trim(),
          privacyPolicyUrl: _privacyPolicyUrlController.text.trim(),
          retentionPolicySummary: _retentionPolicySummaryController.text.trim(),
          internationalTransfersSummary:
              _internationalTransfersSummaryController.text.trim(),
          aiConsentTextVersion: _aiConsentTextVersionController.text.trim(),
          aiConsentText: _aiConsentTextController.text.trim(),
          enabledMultipostingChannels: _enabledChannels.toList(growable: false)
            ..sort(),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}
