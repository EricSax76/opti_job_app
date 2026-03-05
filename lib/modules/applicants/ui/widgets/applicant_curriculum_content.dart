import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:opti_job_app/core/theme/ui_tokens.dart';
import 'package:opti_job_app/core/widgets/app_card.dart';
import 'package:opti_job_app/core/widgets/inline_state_message.dart';
import 'package:opti_job_app/modules/applicants/ui/widgets/applicant_curriculum_header.dart';
import 'package:opti_job_app/modules/candidates/models/candidate.dart';
import 'package:opti_job_app/modules/curriculum/models/curriculum.dart';
import 'package:opti_job_app/modules/curriculum/ui/widgets/curriculum_read_only_view.dart';

class ApplicantCurriculumContent extends StatelessWidget {
  const ApplicantCurriculumContent({
    super.key,
    required this.candidate,
    required this.curriculum,
    required this.offerId,
    required this.isExporting,
    required this.isMatching,
    required this.onExport,
    required this.onMatch,
  });

  final Candidate candidate;
  final Curriculum curriculum;
  final String offerId;
  final bool isExporting;
  final bool isMatching;
  final VoidCallback onExport;
  final VoidCallback onMatch;

  @override
  Widget build(BuildContext context) {
    final hasCurriculum = curriculum.hasContent;
    final coverLetterText = candidate.coverLetter?.text.trim() ?? '';
    final hasCoverLetter = candidate.hasCoverLetter;
    final hasVideoCurriculum = candidate.hasVideoCurriculum;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(uiSpacing16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ApplicantCurriculumHeader(
                candidate: candidate,
                hasCurriculum: hasCurriculum,
                isExporting: isExporting,
                isMatching: isMatching,
                onExport: onExport,
                onMatch: onMatch,
              ),
              const SizedBox(height: uiSpacing16),
              SectionCard(
                title: 'Curriculum',
                child: hasCurriculum
                    ? CurriculumReadOnlyView(
                        curriculum: curriculum,
                        avatarUrl: candidate.avatarUrl,
                      )
                    : InlineStateMessage(
                        icon: Icons.description_outlined,
                        message: 'El aplicante aún no tiene un CV cargado.',
                        color: muted,
                      ),
              ),
              const SizedBox(height: uiSpacing16),
              SectionCard(
                title: 'Carta de presentación',
                padding: EdgeInsets.zero,
                child: _DetailPanel(
                  child: hasCoverLetter
                      ? SelectableText(
                          coverLetterText,
                          style: TextStyle(color: muted, height: 1.5),
                        )
                      : InlineStateMessage(
                          icon: Icons.description_outlined,
                          message:
                              'El aplicante no adjuntó una carta de presentación.',
                          color: muted,
                        ),
                ),
              ),
              const SizedBox(height: uiSpacing16),
              SectionCard(
                title: 'Video curriculum',
                padding: EdgeInsets.zero,
                child: _DetailPanel(
                  child: Row(
                    children: [
                      Icon(Icons.videocam_outlined, color: muted),
                      const SizedBox(width: uiSpacing12),
                      Expanded(
                        child: Text(
                          hasVideoCurriculum
                              ? 'Video cargado (privado)'
                              : 'No adjuntó video curriculum',
                          style: TextStyle(color: muted, height: 1.3),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: uiSpacing16),
              SectionCard(
                title: 'Verificación de credenciales (ZKP)',
                padding: EdgeInsets.zero,
                child: _DetailPanel(
                  child: _SelectiveDisclosureVerificationPanel(
                    candidateUid: candidate.uid,
                    offerId: offerId,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailPanel extends StatelessWidget {
  const _DetailPanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return AppCard(
      padding: const EdgeInsets.all(uiSpacing16),
      borderRadius: uiTileRadius,
      backgroundColor: colorScheme.surfaceContainerHighest,
      borderColor: colorScheme.outline,
      child: child,
    );
  }
}

class _SelectiveDisclosureVerificationPanel extends StatefulWidget {
  const _SelectiveDisclosureVerificationPanel({
    required this.candidateUid,
    required this.offerId,
  });

  final String candidateUid;
  final String offerId;

  @override
  State<_SelectiveDisclosureVerificationPanel> createState() =>
      _SelectiveDisclosureVerificationPanelState();
}

class _SelectiveDisclosureVerificationPanelState
    extends State<_SelectiveDisclosureVerificationPanel> {
  final TextEditingController _proofIdController = TextEditingController();
  final TextEditingController _proofTokenController = TextEditingController();
  bool _isVerifying = false;
  String? _errorMessage;
  String? _successMessage;

  @override
  void dispose() {
    _proofIdController.dispose();
    _proofTokenController.dispose();
    super.dispose();
  }

  Future<void> _verifyProof() async {
    if (_isVerifying) return;
    final proofId = _proofIdController.text.trim();
    final proofToken = _proofTokenController.text.trim();
    if (proofId.isEmpty || proofToken.isEmpty) {
      setState(() {
        _errorMessage = 'Introduce proofId y proofToken para verificar.';
        _successMessage = null;
      });
      return;
    }

    setState(() {
      _isVerifying = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final response = await _callCallableWithFallback(
        name: 'verifySelectiveDisclosureProof',
        payload: {'proofId': proofId, 'proofToken': proofToken},
      );

      final responseCandidateUid =
          (response['candidateUid'] as String?)?.trim() ?? '';
      final responseOfferId = (response['jobOfferId'] as String?)?.trim() ?? '';
      final statement = (response['statement'] as String?)?.trim() ?? '';
      final claimKey = (response['claimKey'] as String?)?.trim() ?? '';

      if (responseCandidateUid.isNotEmpty &&
          responseCandidateUid != widget.candidateUid) {
        setState(() {
          _errorMessage =
              'La prueba es válida pero pertenece a otra candidatura.';
          _successMessage = null;
          _isVerifying = false;
        });
        return;
      }
      if (responseOfferId.isNotEmpty && responseOfferId != widget.offerId) {
        setState(() {
          _errorMessage = 'La prueba no corresponde a esta oferta.';
          _successMessage = null;
          _isVerifying = false;
        });
        return;
      }

      setState(() {
        _successMessage = statement.isNotEmpty
            ? 'Prueba válida: $statement${claimKey.isNotEmpty ? ' (claim: $claimKey)' : ''}.'
            : 'Prueba válida y verificada correctamente.';
      });
    } on FirebaseFunctionsException catch (error) {
      final message = (error.message ?? '').trim();
      setState(() {
        _errorMessage = message.isEmpty
            ? 'No se pudo verificar la prueba (${error.code}).'
            : '$message (${error.code})';
      });
    } catch (_) {
      setState(() {
        _errorMessage = 'No se pudo verificar la prueba en este momento.';
      });
    } finally {
      if (mounted) {
        setState(() => _isVerifying = false);
      }
    }
  }

  Future<Map<String, dynamic>> _callCallableWithFallback({
    required String name,
    required Map<String, dynamic> payload,
  }) async {
    final regional = FirebaseFunctions.instanceFor(region: 'europe-west1');
    final fallback = FirebaseFunctions.instance;
    try {
      final result = await regional.httpsCallable(name).call(payload);
      final data = result.data;
      if (data is Map<String, dynamic>) return data;
      if (data is Map) return Map<String, dynamic>.from(data);
      return const <String, dynamic>{};
    } on FirebaseFunctionsException catch (error) {
      if (error.code != 'not-found' && error.code != 'unimplemented') {
        rethrow;
      }
      final result = await fallback.httpsCallable(name).call(payload);
      final data = result.data;
      if (data is Map<String, dynamic>) return data;
      if (data is Map) return Map<String, dynamic>.from(data);
      return const <String, dynamic>{};
    }
  }

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Verifica una prueba de posesión sin acceder al documento original. Introduce proofId y proofToken compartidos por la persona candidata.',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: muted, height: 1.35),
        ),
        const SizedBox(height: uiSpacing12),
        TextField(
          controller: _proofIdController,
          decoration: const InputDecoration(
            labelText: 'Proof ID',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: uiSpacing8),
        TextField(
          controller: _proofTokenController,
          decoration: const InputDecoration(
            labelText: 'Proof Token',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: uiSpacing12),
        FilledButton.icon(
          onPressed: _isVerifying ? null : _verifyProof,
          icon: _isVerifying
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.fact_check_outlined),
          label: const Text('Verificar prueba'),
        ),
        if (_errorMessage != null) ...[
          const SizedBox(height: uiSpacing8),
          Text(
            _errorMessage!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.error,
            ),
          ),
        ],
        if (_successMessage != null) ...[
          const SizedBox(height: uiSpacing8),
          Text(
            _successMessage!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.tertiary,
            ),
          ),
        ],
      ],
    );
  }
}
