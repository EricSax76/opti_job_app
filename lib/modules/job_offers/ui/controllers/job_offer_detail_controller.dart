import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:opti_job_app/modules/ats/models/knockout_question.dart';
import 'package:opti_job_app/modules/applications/logic/application_service.dart';
import 'package:opti_job_app/modules/applications/models/qualified_signature_models.dart';
import 'package:opti_job_app/modules/compliance/models/consent_record.dart';
import 'package:opti_job_app/modules/compliance/repositories/compliance_repository.dart';
import 'package:opti_job_app/modules/job_offers/cubits/job_offer_detail_cubit.dart';
import 'package:opti_job_app/modules/job_offers/logic/job_offer_detail_logic.dart';
import 'package:opti_job_app/modules/job_offers/logic/job_offer_match_logic.dart';
import 'package:opti_job_app/modules/job_offers/models/job_offer.dart';
import 'package:opti_job_app/modules/job_offers/models/job_offer_detail_view_model.dart';
import 'package:opti_job_app/modules/job_offers/ui/widgets/job_offer_match_dialog.dart';
import 'package:opti_job_app/modules/job_offers/ui/widgets/job_offer_pre_apply_verdict_dialog.dart';

class JobOfferDetailController {
  const JobOfferDetailController._();

  static const String _defaultAiConsentTextVersion = '2026.04';
  static const String _defaultAiConsentText =
      'Autorizo el uso de sistemas de IA para test y entrevistas de esta candidatura. '
      'Entiendo que puedo solicitar revisión humana y revocar en el portal de privacidad.';

  static void handleDetailMessages(
    BuildContext context,
    JobOfferDetailState state,
  ) {
    if (state.matchOutcome != null) {
      _handleMatchOutcome(context, state.matchOutcome!);
      context.read<JobOfferDetailCubit>().clearMatchOutcome();
      return;
    }

    final successMessage = JobOfferDetailLogic.successMessage(state);
    if (successMessage != null) {
      _showSnackBar(
        context,
        message: successMessage,
        backgroundColor: Theme.of(context).colorScheme.tertiary,
      );
      context.read<JobOfferDetailCubit>().clearMessages();
      return;
    }

    final errorMessage = JobOfferDetailLogic.errorMessage(state);
    if (errorMessage == null) return;

    _showSnackBar(
      context,
      message: errorMessage,
      backgroundColor: Theme.of(context).colorScheme.error,
    );
    context.read<JobOfferDetailCubit>().clearMessages();
  }

  static void _handleMatchOutcome(
    BuildContext context,
    JobOfferMatchOutcome outcome,
  ) {
    if (outcome is JobOfferMatchSuccess) {
      showDialog<void>(
        context: context,
        builder: (dialogContext) =>
            JobOfferMatchResultDialog(result: outcome.result),
      );
    } else if (outcome is JobOfferMatchFailure) {
      _showSnackBar(context, message: outcome.message);
    }
  }

  static Future<void> showMatchResult(BuildContext context) async {
    final rootNavigator = Navigator.of(context, rootNavigator: true);
    var isLoadingDialogOpen = true;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return const AlertDialog(
          title: Text('Calculando match'),
          content: Row(
            children: [
              SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 12),
              Expanded(child: Text('Analizando tu CV contra la oferta...')),
            ],
          ),
        );
      },
    ).whenComplete(() {
      isLoadingDialogOpen = false;
    });

    await context.read<JobOfferDetailCubit>().computeMatch();

    if (isLoadingDialogOpen && rootNavigator.mounted) {
      rootNavigator.pop();
    }
  }

  static Future<void> apply(
    BuildContext context,
    JobOfferApplyRequest? request,
  ) async {
    if (request == null) return;

    final outcome = await _evaluateBeforeApplying(context, request);
    if (!context.mounted) return;

    final shouldProceed = await _confirmApplyWithOutcome(context, outcome);
    if (shouldProceed != true || !context.mounted) return;

    final consentGranted = await _requestAiConsent(context, request);
    if (!context.mounted || !consentGranted) return;

    final knockoutResponses = await _collectKnockoutResponses(
      context,
      request.offer,
    );
    if (knockoutResponses == null || !context.mounted) return;

    await context.read<JobOfferDetailCubit>().apply(
      candidate: request.candidate,
      offer: request.offer,
      knockoutResponses: knockoutResponses,
    );
  }

  static Future<bool> _requestAiConsent(
    BuildContext context,
    JobOfferApplyRequest request,
  ) async {
    final companyUid = request.offer.companyUid?.trim() ?? '';
    if (companyUid.isEmpty) {
      _showSnackBar(
        context,
        message:
            'No se pudo registrar consentimiento IA porque falta la empresa propietaria.',
        backgroundColor: Theme.of(context).colorScheme.error,
      );
      return false;
    }

    final scopes = _requiredAiConsentScopes(request.offer);
    final consentTextVersion =
        request.offer.companyAiConsentTextVersion?.trim().isNotEmpty == true
        ? request.offer.companyAiConsentTextVersion!.trim()
        : _defaultAiConsentTextVersion;
    final consentText =
        request.offer.companyAiConsentText?.trim().isNotEmpty == true
        ? request.offer.companyAiConsentText!.trim()
        : _defaultAiConsentText;

    final accepted = await _showAiConsentDialog(
      context,
      scopes: scopes,
      consentTextVersion: consentTextVersion,
      consentText: consentText,
      privacyContactEmail: request.offer.companyPrivacyContactEmail,
      dpoEmail: request.offer.companyDpoEmail,
      privacyPolicyUrl: request.offer.companyPrivacyPolicyUrl,
    );
    if (accepted != true || !context.mounted) return false;

    try {
      await _withLoadingDialog<void>(
        context: context,
        title: 'Registrando consentimiento IA',
        message: 'Guardando evidencia auditable del consentimiento...',
        action: () => context.read<ConsentRepository>().saveConsent(
          ConsentRecord(
            id: '',
            candidateUid: request.candidate.uid,
            companyId: companyUid,
            type: 'ai_granular',
            granted: true,
            legalBasis: LegalBasis.consent,
            informationNoticeVersion: consentTextVersion,
            consentTextVersion: consentTextVersion,
            consentTextSnapshot: consentText,
            scope: scopes,
            immutable: true,
          ),
        ),
      );
      return true;
    } on FirebaseFunctionsException catch (error) {
      final message = error.message?.trim().isNotEmpty == true
          ? error.message!.trim()
          : 'No se pudo registrar el consentimiento IA.';
      if (!context.mounted) return false;
      _showSnackBar(
        context,
        message: '$message (${error.code})',
        backgroundColor: Theme.of(context).colorScheme.error,
      );
      return false;
    } catch (_) {
      if (!context.mounted) return false;
      _showSnackBar(
        context,
        message: 'No se pudo registrar el consentimiento IA.',
        backgroundColor: Theme.of(context).colorScheme.error,
      );
      return false;
    }
  }

  static List<String> _requiredAiConsentScopes(JobOffer offer) {
    final scopes = <String>{'ai_interview'};
    final hasKnockout = (offer.knockoutQuestions?.isNotEmpty ?? false);
    if (hasKnockout) {
      scopes.add('ai_test');
    }
    return scopes.toList(growable: false)..sort();
  }

  static String _scopeLabel(String scope) {
    return switch (scope) {
      'ai_interview' => 'Entrevista IA',
      'ai_test' => 'Test IA',
      _ => scope,
    };
  }

  static Future<bool?> _showAiConsentDialog(
    BuildContext context, {
    required List<String> scopes,
    required String consentTextVersion,
    required String consentText,
    String? privacyContactEmail,
    String? dpoEmail,
    String? privacyPolicyUrl,
  }) {
    final scopeLabels = scopes.map(_scopeLabel).join(', ');
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Consentimiento IA'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Ámbito: $scopeLabels'),
                const SizedBox(height: 8),
                Text('Versión del texto: $consentTextVersion'),
                const SizedBox(height: 12),
                Text(consentText),
                if (privacyContactEmail != null &&
                    privacyContactEmail.trim().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text('Contacto privacidad: ${privacyContactEmail.trim()}'),
                ],
                if (dpoEmail != null && dpoEmail.trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text('Encargado/DPO: ${dpoEmail.trim()}'),
                ],
                if (privacyPolicyUrl != null &&
                    privacyPolicyUrl.trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text('Política de privacidad: ${privacyPolicyUrl.trim()}'),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('No acepto'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Acepto y continuar'),
            ),
          ],
        );
      },
    );
  }

  static Future<JobOfferMatchOutcome> _evaluateBeforeApplying(
    BuildContext context,
    JobOfferApplyRequest request,
  ) async {
    final rootNavigator = Navigator.of(context, rootNavigator: true);
    var isLoadingDialogOpen = true;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return const AlertDialog(
          title: Text('Evaluando encaje'),
          content: Row(
            children: [
              SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 12),
              Expanded(child: Text('Contrastando tu CV con esta oferta...')),
            ],
          ),
        );
      },
    ).whenComplete(() {
      isLoadingDialogOpen = false;
    });

    final outcome = await context
        .read<JobOfferDetailCubit>()
        .evaluateFitForApplication(
          candidateUid: request.candidate.uid,
          offer: request.offer,
        );

    if (isLoadingDialogOpen && rootNavigator.mounted) {
      rootNavigator.pop();
    }

    return outcome;
  }

  static Future<bool?> _confirmApplyWithOutcome(
    BuildContext context,
    JobOfferMatchOutcome outcome,
  ) {
    if (outcome is JobOfferMatchSuccess) {
      return showDialog<bool>(
        context: context,
        builder: (dialogContext) =>
            JobOfferPreApplyVerdictDialog(result: outcome.result),
      );
    }

    if (outcome is JobOfferMatchFailure) {
      return showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('No se pudo evaluar el encaje'),
            content: Text(
              '${outcome.message}\n\nPuedes continuar igualmente o cancelar la postulación.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                ),
                child: const Text('Continuar postulación'),
              ),
            ],
          );
        },
      );
    }

    return Future.value(false);
  }

  static void navigateBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go('/job-offer');
  }

  static Future<void> signQualifiedOffer(
    BuildContext context, {
    required String applicationId,
  }) async {
    final service = context.read<ApplicationService>();
    final normalizedApplicationId = applicationId.trim();
    if (normalizedApplicationId.isEmpty) return;

    try {
      final currentStatus = await service.getQualifiedOfferSignatureStatus(
        applicationId: normalizedApplicationId,
      );
      if (!context.mounted) return;
      final signatureMap = currentStatus.contractSignature;
      final signatureStatus =
          (signatureMap['status'] as String?)?.trim().toLowerCase() ?? '';
      if (signatureStatus == 'signed' || currentStatus.status == 'accepted') {
        _showSnackBar(
          context,
          message: 'La oferta ya está firmada cualificadamente.',
          backgroundColor: Theme.of(context).colorScheme.tertiary,
        );
        return;
      }

      final startResult =
          await _withLoadingDialog<QualifiedSignatureStartResult>(
            context: context,
            title: 'Iniciando firma cualificada',
            message: 'Preparando el documento y el reto de firma...',
            action: () => service.startQualifiedOfferSignature(
              applicationId: normalizedApplicationId,
            ),
          );
      if (!context.mounted) return;

      final confirmation = await _showQualifiedSignatureDialog(
        context,
        startResult,
      );
      if (!context.mounted || confirmation == null) return;

      await _withLoadingDialog<void>(
        context: context,
        title: 'Validando firma',
        message: 'Confirmando OTP y certificado cualificado...',
        action: () => service.confirmQualifiedOfferSignature(
          requestId: startResult.requestId,
          otpCode: confirmation.otpCode,
          certificateFingerprint: confirmation.certificateFingerprint,
          providerReference: confirmation.providerReference,
        ),
      );
      if (!context.mounted) return;

      await context.read<JobOfferDetailCubit>().refresh();
      if (!context.mounted) return;
      _showSnackBar(
        context,
        message: 'Oferta firmada con firma electrónica cualificada (eIDAS).',
        backgroundColor: Theme.of(context).colorScheme.tertiary,
      );
    } on FirebaseFunctionsException catch (error) {
      final message = (error.message ?? '').trim();
      _showSnackBar(
        context,
        message: message.isEmpty
            ? 'No se pudo completar la firma (${error.code}).'
            : '$message (${error.code})',
        backgroundColor: Theme.of(context).colorScheme.error,
      );
    } catch (_) {
      _showSnackBar(
        context,
        message: 'No se pudo completar la firma cualificada.',
        backgroundColor: Theme.of(context).colorScheme.error,
      );
    }
  }

  static Future<T> _withLoadingDialog<T>({
    required BuildContext context,
    required String title,
    required String message,
    required Future<T> Function() action,
  }) async {
    final rootNavigator = Navigator.of(context, rootNavigator: true);
    var isLoadingDialogOpen = true;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return AlertDialog(
          title: Text(title),
          content: Row(
            children: [
              const SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(message)),
            ],
          ),
        );
      },
    ).whenComplete(() {
      isLoadingDialogOpen = false;
    });

    try {
      return await action();
    } finally {
      if (isLoadingDialogOpen && rootNavigator.mounted) {
        rootNavigator.pop();
      }
    }
  }

  static Future<_QualifiedSignatureInput?> _showQualifiedSignatureDialog(
    BuildContext context,
    QualifiedSignatureStartResult startResult,
  ) {
    final otpController = TextEditingController();
    final certController = TextEditingController();
    final providerRefController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    return showDialog<_QualifiedSignatureInput>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Completar firma cualificada'),
          content: SizedBox(
            width: 520,
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    startResult.signingChallengeHint ??
                        'Introduce OTP y referencia del proveedor de firma.',
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: otpController,
                    decoration: const InputDecoration(
                      labelText: 'OTP de firma',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      final raw = (value ?? '').trim();
                      if (raw.length < 4 || raw.length > 10) {
                        return 'OTP inválido.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: certController,
                    decoration: const InputDecoration(
                      labelText: 'Huella certificado cualificado',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if ((value ?? '').trim().isEmpty) {
                        return 'Indica la huella del certificado.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: providerRefController,
                    decoration: const InputDecoration(
                      labelText: 'Referencia proveedor',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if ((value ?? '').trim().isEmpty) {
                        return 'Indica la referencia del proveedor.';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                if (!formKey.currentState!.validate()) return;
                Navigator.of(dialogContext).pop(
                  _QualifiedSignatureInput(
                    otpCode: otpController.text.trim(),
                    certificateFingerprint: certController.text.trim(),
                    providerReference: providerRefController.text.trim(),
                  ),
                );
              },
              child: const Text('Firmar oferta'),
            ),
          ],
        );
      },
    );
  }

  static void _showSnackBar(
    BuildContext context, {
    required String message,
    Color? backgroundColor,
  }) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), backgroundColor: backgroundColor),
      );
  }

  static List<KnockoutQuestion> _parseKnockoutQuestions(JobOffer offer) {
    final rawQuestions = offer.knockoutQuestions ?? const <dynamic>[];
    final parsed = <KnockoutQuestion>[];

    for (final raw in rawQuestions) {
      if (raw is Map<String, dynamic>) {
        parsed.add(KnockoutQuestion.fromFirestore(raw));
        continue;
      }
      if (raw is Map) {
        final normalizedMap = raw.map(
          (key, value) => MapEntry(key.toString(), value),
        );
        parsed.add(KnockoutQuestion.fromFirestore(normalizedMap));
      }
    }

    return parsed
        .where((question) => question.id.trim().isNotEmpty)
        .where((question) => question.question.trim().isNotEmpty)
        .toList(growable: false);
  }

  static Future<Map<String, dynamic>?> _collectKnockoutResponses(
    BuildContext context,
    JobOffer offer,
  ) async {
    final questions = _parseKnockoutQuestions(offer);
    if (questions.isEmpty) {
      return <String, dynamic>{};
    }

    final responses = <String, dynamic>{};

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) {
        String? errorMessage;
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Preguntas previas'),
              content: SizedBox(
                width: 560,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Antes de enviar tu postulación, responde estas preguntas.',
                      ),
                      const SizedBox(height: 16),
                      for (final question in questions) ...[
                        Text(
                          question.question,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 8),
                        _KnockoutAnswerField(
                          question: question,
                          value: responses[question.id],
                          onChanged: (value) {
                            responses[question.id] = value;
                            setState(() => errorMessage = null);
                          },
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (errorMessage != null)
                        Text(
                          errorMessage!,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.error,
                              ),
                        ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(null),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () {
                    final unanswered = questions
                        .where(
                          (question) => _isMissingAnswer(
                            question,
                            responses[question.id],
                          ),
                        )
                        .length;

                    if (unanswered > 0) {
                      setState(() {
                        errorMessage =
                            'Responde todas las preguntas para continuar.';
                      });
                      return;
                    }

                    Navigator.of(
                      dialogContext,
                    ).pop(Map<String, dynamic>.from(responses));
                  },
                  child: const Text('Continuar postulación'),
                ),
              ],
            );
          },
        );
      },
    );

    return result;
  }

  static bool _isMissingAnswer(KnockoutQuestion question, dynamic value) {
    if (question.requiredAnswer == null) {
      return false;
    }
    switch (question.type) {
      case KnockoutQuestionType.boolean:
        return value is! bool;
      case KnockoutQuestionType.multipleChoice:
      case KnockoutQuestionType.text:
        final text = value?.toString().trim() ?? '';
        return text.isEmpty;
    }
  }
}

class _QualifiedSignatureInput {
  const _QualifiedSignatureInput({
    required this.otpCode,
    required this.certificateFingerprint,
    required this.providerReference,
  });

  final String otpCode;
  final String certificateFingerprint;
  final String providerReference;
}

class _KnockoutAnswerField extends StatelessWidget {
  const _KnockoutAnswerField({
    required this.question,
    required this.value,
    required this.onChanged,
  });

  final KnockoutQuestion question;
  final dynamic value;
  final ValueChanged<dynamic> onChanged;

  @override
  Widget build(BuildContext context) {
    switch (question.type) {
      case KnockoutQuestionType.boolean:
        final boolValue = value is bool ? value : null;
        return SegmentedButton<bool>(
          segments: const [
            ButtonSegment<bool>(value: true, label: Text('Sí')),
            ButtonSegment<bool>(value: false, label: Text('No')),
          ],
          emptySelectionAllowed: true,
          selected: boolValue == null ? const <bool>{} : <bool>{boolValue},
          onSelectionChanged: (selection) {
            if (selection.isEmpty) return;
            onChanged(selection.first);
          },
        );
      case KnockoutQuestionType.multipleChoice:
        final options = question.options ?? const <String>[];
        if (options.isEmpty) {
          return TextFormField(
            initialValue: value as String?,
            onChanged: onChanged,
            decoration: const InputDecoration(
              hintText: 'Tu respuesta',
              border: OutlineInputBorder(),
            ),
          );
        }
        return DropdownButtonFormField<String>(
          initialValue: value as String?,
          items: options
              .map(
                (option) => DropdownMenuItem<String>(
                  value: option,
                  child: Text(option),
                ),
              )
              .toList(growable: false),
          onChanged: onChanged,
          decoration: const InputDecoration(
            hintText: 'Selecciona una opción',
            border: OutlineInputBorder(),
          ),
        );
      case KnockoutQuestionType.text:
        return TextFormField(
          initialValue: value as String?,
          onChanged: onChanged,
          decoration: const InputDecoration(
            hintText: 'Tu respuesta',
            border: OutlineInputBorder(),
          ),
        );
    }
  }
}
