import 'package:flutter/material.dart';
import 'package:opti_job_app/modules/ats/models/knockout_question.dart';
import 'package:opti_job_app/modules/job_offers/models/job_offer.dart';

class JobOfferDetailKnockoutFlow {
  const JobOfferDetailKnockoutFlow._();

  static Future<Map<String, dynamic>?> collectResponses(
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

  static List<KnockoutQuestion> _parseKnockoutQuestions(JobOffer offer) {
    final rawQuestions = offer.knockoutQuestions ?? const <dynamic>[];
    final parsed = <KnockoutQuestion>[];

    for (final raw in rawQuestions) {
      final normalizedMap = _normalizeQuestionMap(raw);
      if (normalizedMap == null) continue;

      try {
        parsed.add(KnockoutQuestion.fromFirestore(normalizedMap));
      } catch (_) {
        // Ignoramos payloads corruptos para no bloquear la postulación.
      }
    }

    return parsed
        .where((question) => question.id.trim().isNotEmpty)
        .where((question) => question.question.trim().isNotEmpty)
        .toList(growable: false);
  }

  static Map<String, dynamic>? _normalizeQuestionMap(dynamic raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) {
      return raw.map((key, value) => MapEntry(key.toString(), value));
    }
    return null;
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
