import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opti_job_app/modules/applications/logic/application_service.dart';
import 'package:opti_job_app/modules/applications/models/qualified_signature_models.dart';
import 'package:opti_job_app/modules/job_offers/cubits/job_offer_detail_cubit.dart';
import 'package:opti_job_app/modules/job_offers/ui/controllers/detail/job_offer_detail_feedback_handler.dart';
import 'package:opti_job_app/modules/job_offers/ui/controllers/detail/job_offer_detail_loading_dialog.dart';

class JobOfferDetailSignatureFlow {
  const JobOfferDetailSignatureFlow._();

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
        JobOfferDetailFeedbackHandler.showSnackBar(
          context,
          message: 'La oferta ya está firmada cualificadamente.',
          backgroundColor: Theme.of(context).colorScheme.tertiary,
        );
        return;
      }

      final startResult =
          await JobOfferDetailLoadingDialog.run<QualifiedSignatureStartResult>(
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

      await JobOfferDetailLoadingDialog.run<void>(
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
      JobOfferDetailFeedbackHandler.showSnackBar(
        context,
        message: 'Oferta firmada con firma electrónica cualificada (eIDAS).',
        backgroundColor: Theme.of(context).colorScheme.tertiary,
      );
    } on FirebaseFunctionsException catch (error) {
      if (!context.mounted) return;
      final message = (error.message ?? '').trim();
      JobOfferDetailFeedbackHandler.showSnackBar(
        context,
        message: message.isEmpty
            ? 'No se pudo completar la firma (${error.code}).'
            : '$message (${error.code})',
        backgroundColor: Theme.of(context).colorScheme.error,
      );
    } catch (_) {
      if (!context.mounted) return;
      JobOfferDetailFeedbackHandler.showSnackBar(
        context,
        message: 'No se pudo completar la firma cualificada.',
        backgroundColor: Theme.of(context).colorScheme.error,
      );
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
