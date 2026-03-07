import 'package:flutter/material.dart';
import 'package:opti_job_app/core/theme/ui_tokens.dart';
import 'package:opti_job_app/modules/applicants/models/ai_decision_review.dart';
import 'package:opti_job_app/modules/applicants/repositories/applicants_repository.dart';

class AiDecisionReviewDialog extends StatefulWidget {
  const AiDecisionReviewDialog({
    super.key,
    required this.applicationId,
    required this.jobOfferId,
    required this.repository,
    this.initialScore,
  });

  final String applicationId;
  final String jobOfferId;
  final ApplicantsRepository repository;
  final double? initialScore;

  @override
  State<AiDecisionReviewDialog> createState() => _AiDecisionReviewDialogState();
}

class _AiDecisionReviewDialogState extends State<AiDecisionReviewDialog> {
  final TextEditingController _reasonController = TextEditingController();
  final TextEditingController _scoreController = TextEditingController();

  AiDecisionReview? _review;
  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _isRunningVectorMatch = false;
  bool _isRunningSkillMatch = false;
  String? _runInfoMessage;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadReview();
  }

  @override
  void dispose() {
    _reasonController.dispose();
    _scoreController.dispose();
    super.dispose();
  }

  Future<void> _loadReview({bool showLoading = true}) async {
    if (showLoading) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final review = await widget.repository.getAiDecisionReview(
        applicationId: widget.applicationId,
        limit: 20,
      );
      if (!mounted) return;
      setState(() {
        _review = review;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = _normalizeError(error);
        _isLoading = false;
      });
    }
  }

  bool get _isBusy =>
      _isSubmitting || _isRunningVectorMatch || _isRunningSkillMatch;

  Future<void> _runVectorMatch() async {
    if (_isBusy) return;
    setState(() {
      _isRunningVectorMatch = true;
      _runInfoMessage = null;
      _errorMessage = null;
    });

    try {
      await widget.repository.runAiVectorMatch(
        applicationId: widget.applicationId,
        limit: 8,
      );
      await _loadReview(showLoading: false);
      if (!mounted) return;
      setState(() {
        _runInfoMessage =
            'Matching vectorial ejecutado. Se actualizó la traza de decisión.';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = _normalizeError(error);
      });
    } finally {
      if (mounted) {
        setState(() {
          _isRunningVectorMatch = false;
        });
      }
    }
  }

  Future<void> _runSkillMatch() async {
    if (_isBusy) return;
    setState(() {
      _isRunningSkillMatch = true;
      _runInfoMessage = null;
      _errorMessage = null;
    });

    try {
      await widget.repository.runAiSkillMatch(
        applicationId: widget.applicationId,
        jobOfferId: widget.jobOfferId,
      );
      await _loadReview(showLoading: false);
      if (!mounted) return;
      setState(() {
        _runInfoMessage =
            'Matching semántico por skills ejecutado y visible en trazas.';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = _normalizeError(error);
      });
    } finally {
      if (mounted) {
        setState(() {
          _isRunningSkillMatch = false;
        });
      }
    }
  }

  Future<void> _submitOverride() async {
    final review = _review;
    if (review == null || _isSubmitting) return;

    final reason = _reasonController.text.trim();
    if (reason.isEmpty) {
      setState(() {
        _errorMessage = 'Debes indicar un motivo para el override.';
      });
      return;
    }

    double? overrideScore;
    final scoreText = _scoreController.text.trim();
    if (scoreText.isNotEmpty) {
      overrideScore = double.tryParse(scoreText);
      if (overrideScore == null || overrideScore < 0 || overrideScore > 100) {
        setState(() {
          _errorMessage = 'La puntuación debe estar entre 0 y 100.';
        });
        return;
      }
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      await widget.repository.overrideAiDecision(
        applicationId: widget.applicationId,
        reason: reason,
        overrideScore: overrideScore,
        originalAiScore: review.aiMatchResult.score ?? widget.initialScore,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = _normalizeError(error);
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  String _normalizeError(Object error) {
    final text = error.toString().trim();
    if (text.isEmpty) return 'No se pudo completar la operación.';
    return text;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      title: const Text('Revisión y override IA'),
      content: SizedBox(
        width: 680,
        child: _isLoading
            ? const SizedBox(
                height: 180,
                child: Center(child: CircularProgressIndicator()),
              )
            : _buildContent(colorScheme),
      ),
      actions: [
        TextButton(
          onPressed: _isBusy ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cerrar'),
        ),
        FilledButton.icon(
          onPressed: (_review == null || _isBusy) ? null : _submitOverride,
          icon: _isSubmitting
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.gavel_outlined),
          label: const Text('Aplicar override'),
        ),
      ],
    );
  }

  Widget _buildContent(ColorScheme colorScheme) {
    final review = _review;
    if (review == null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _errorMessage ?? 'No se pudo cargar la revisión IA.',
            style: TextStyle(color: colorScheme.error),
          ),
          const SizedBox(height: uiSpacing12),
          OutlinedButton.icon(
            onPressed: _loadReview,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ],
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _pill(
                context: context,
                label:
                    'Score IA: ${_formatScore(review.aiMatchResult.score ?? widget.initialScore)}',
                icon: Icons.auto_graph_outlined,
              ),
              _pill(
                context: context,
                label: 'Scope: ${review.actorScope}',
                icon: Icons.admin_panel_settings_outlined,
              ),
              _pill(
                context: context,
                label: 'Logs: ${review.logs.length}',
                icon: Icons.history_outlined,
              ),
            ],
          ),
          const SizedBox(height: uiSpacing12),
          _section(
            context: context,
            title: 'Disparadores manuales IA',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _isBusy ? null : _runVectorMatch,
                      icon: _isRunningVectorMatch
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.auto_awesome_motion_outlined),
                      label: const Text('Recalcular vectorial'),
                    ),
                    OutlinedButton.icon(
                      onPressed: _isBusy ? null : _runSkillMatch,
                      icon: _isRunningSkillMatch
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.rule_folder_outlined),
                      label: const Text('Recalcular skills'),
                    ),
                  ],
                ),
                const SizedBox(height: uiSpacing8),
                Text(
                  'Trigger manual para uso interno: ejecuta callables backend y refresca score/trazas.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (review.aiMatchResult.explanation case final explanation?)
            _section(
              context: context,
              title: 'Explicabilidad IA',
              child: Text(explanation),
            ),
          _section(
            context: context,
            title: 'Estado de override',
            child: Text(_buildOverrideSummary(review.humanOverride)),
          ),
          _section(
            context: context,
            title: 'Aplicar override',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _reasonController,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Motivo (requerido)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: uiSpacing8),
                TextField(
                  controller: _scoreController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Nuevo score (opcional, 0-100)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: uiSpacing8),
                Text(
                  'Si no indicas score, se mantiene el score actual y se registra solo la decisión humana.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          _section(
            context: context,
            title: 'Trazas recientes',
            child: review.logs.isEmpty
                ? Text(
                    'No hay logs disponibles.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  )
                : Column(
                    children: review.logs
                        .take(8)
                        .map(
                          (entry) => Padding(
                            padding: const EdgeInsets.only(bottom: uiSpacing8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.fiber_manual_record, size: 10),
                                const SizedBox(width: uiSpacing8),
                                Expanded(
                                  child: Text(
                                    '${entry.decisionType} · ${entry.decisionStatus} · score ${_formatScore(entry.score)} · ${_formatDate(entry.createdAt)}',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(growable: false),
                  ),
          ),
          if (_errorMessage case final message?) ...[
            const SizedBox(height: uiSpacing8),
            Text(
              message,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: colorScheme.error),
            ),
          ],
          if (_runInfoMessage case final message?) ...[
            const SizedBox(height: uiSpacing8),
            Text(
              message,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: colorScheme.tertiary),
            ),
          ],
        ],
      ),
    );
  }

  Widget _pill({
    required BuildContext context,
    required String label,
    required IconData icon,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: scheme.primary),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
    );
  }

  Widget _section({
    required BuildContext context,
    required String title,
    required Widget child,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: uiSpacing12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: uiSpacing8),
          child,
        ],
      ),
    );
  }

  String _buildOverrideSummary(AiDecisionHumanOverride humanOverride) {
    if (!humanOverride.isOverridden) {
      return 'Sin override registrado.';
    }

    final overrideScore = _formatScore(humanOverride.overrideScore);
    final originalScore = _formatScore(humanOverride.originalAiScore);
    final dateText = _formatDate(humanOverride.overriddenAt);
    final reason = (humanOverride.reason ?? '').trim();
    final reasonText = reason.isEmpty ? 'sin motivo explícito' : reason;
    return 'Override activo · original $originalScore · nuevo $overrideScore · $dateText · $reasonText';
  }

  String _formatScore(double? score) {
    if (score == null) return 'N/A';
    return '${score.toStringAsFixed(1)}%';
  }

  String _formatDate(DateTime? value) {
    if (value == null) return 'sin fecha';
    final local = value.toLocal();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '${local.year}-$month-$day $hour:$minute';
  }
}
