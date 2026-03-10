import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opti_job_app/auth/repositories/auth_repository.dart';
import 'package:opti_job_app/core/theme/ui_tokens.dart';

class SelectiveDisclosureVerificationPanel extends StatefulWidget {
  const SelectiveDisclosureVerificationPanel({
    super.key,
    required this.candidateUid,
    required this.offerId,
  });

  final String candidateUid;
  final String offerId;

  @override
  State<SelectiveDisclosureVerificationPanel> createState() =>
      _SelectiveDisclosureVerificationPanelState();
}

class _SelectiveDisclosureVerificationPanelState
    extends State<SelectiveDisclosureVerificationPanel> {
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

    final repository = context.read<AuthRepository>();
    try {
      final response = await repository.verifySelectiveDisclosureProof(
        proofId: proofId,
        proofToken: proofToken,
      );

      if (!response.verified) {
        setState(() {
          _errorMessage = 'La prueba no pudo verificarse correctamente.';
          _successMessage = null;
          _isVerifying = false;
        });
        return;
      }

      final responseCandidateUid = response.candidateUid?.trim() ?? '';
      final responseOfferId = response.jobOfferId?.trim() ?? '';
      final statement = response.statement.trim();
      final claimKey = response.claimKey?.trim() ?? '';

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
    } catch (error) {
      final message = repository.mapException(error).message.trim();
      setState(() {
        _errorMessage = message.isEmpty
            ? 'No se pudo verificar la prueba en este momento.'
            : message;
      });
    } finally {
      if (mounted) {
        setState(() => _isVerifying = false);
      }
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
