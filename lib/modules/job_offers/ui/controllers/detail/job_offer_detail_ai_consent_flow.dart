import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opti_job_app/modules/compliance/models/consent_record.dart';
import 'package:opti_job_app/modules/compliance/repositories/compliance_repository.dart';
import 'package:opti_job_app/modules/job_offers/models/job_offer.dart';
import 'package:opti_job_app/modules/job_offers/models/job_offer_detail_view_model.dart';
import 'package:opti_job_app/modules/job_offers/ui/controllers/detail/job_offer_detail_feedback_handler.dart';
import 'package:opti_job_app/modules/job_offers/ui/controllers/detail/job_offer_detail_loading_dialog.dart';

class JobOfferDetailAiConsentFlow {
  const JobOfferDetailAiConsentFlow._();

  static const String _defaultAiConsentTextVersion = '2026.04';
  static const String _defaultAiConsentText =
      'Autorizo el uso de sistemas de IA para test y entrevistas de esta candidatura. '
      'Entiendo que puedo solicitar revisión humana y revocar en el portal de privacidad.';

  static Future<bool> requestAiConsent(
    BuildContext context,
    JobOfferApplyRequest request,
  ) async {
    final companyUid = request.offer.companyUid?.trim() ?? '';
    if (companyUid.isEmpty) {
      JobOfferDetailFeedbackHandler.showSnackBar(
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
      await JobOfferDetailLoadingDialog.run<void>(
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
      JobOfferDetailFeedbackHandler.showSnackBar(
        context,
        message: '$message (${error.code})',
        backgroundColor: Theme.of(context).colorScheme.error,
      );
      return false;
    } catch (_) {
      if (!context.mounted) return false;
      JobOfferDetailFeedbackHandler.showSnackBar(
        context,
        message: 'No se pudo registrar el consentimiento IA.',
        backgroundColor: Theme.of(context).colorScheme.error,
      );
      return false;
    }
  }

  static List<String> _requiredAiConsentScopes(JobOffer offer) {
    final scopes = <String>{'ai_interview'};
    final hasKnockout = offer.knockoutQuestions?.isNotEmpty ?? false;
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
}
