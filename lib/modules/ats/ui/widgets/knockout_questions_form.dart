import 'package:flutter/material.dart';
import 'package:opti_job_app/core/theme/ui_tokens.dart';
import 'package:opti_job_app/core/widgets/app_card.dart';
import 'package:opti_job_app/core/widgets/inline_state_message.dart';
import 'package:opti_job_app/core/widgets/section_header.dart';
import 'package:opti_job_app/modules/ats/models/knockout_question.dart';

class KnockoutQuestionsForm extends StatefulWidget {
  const KnockoutQuestionsForm({
    super.key,
    required this.initialQuestions,
    required this.onQuestionsChanged,
  });

  final List<KnockoutQuestion> initialQuestions;
  final ValueChanged<List<KnockoutQuestion>> onQuestionsChanged;

  @override
  State<KnockoutQuestionsForm> createState() => _KnockoutQuestionsFormState();
}

class _KnockoutQuestionsFormState extends State<KnockoutQuestionsForm> {
  late List<KnockoutQuestion> _questions;

  @override
  void initState() {
    super.initState();
    _questions = List.from(widget.initialQuestions);
  }

  void _addQuestion() {
    setState(() {
      _questions.add(
        KnockoutQuestion(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          question: '',
          type: KnockoutQuestionType.boolean,
          requiredAnswer: true,
        ),
      );
    });
    widget.onQuestionsChanged(_questions);
  }

  void _removeQuestion(int index) {
    setState(() {
      _questions.removeAt(index);
    });
    widget.onQuestionsChanged(_questions);
  }

  void _updateQuestion(int index, KnockoutQuestion updated) {
    setState(() {
      _questions[index] = updated;
    });
    widget.onQuestionsChanged(_questions);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Preguntas eliminatorias',
          subtitle: 'Filtra automáticamente candidaturas no válidas.',
          titleFontSize: 20,
          action: TextButton.icon(
            onPressed: _addQuestion,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Añadir pregunta'),
          ),
        ),
        const SizedBox(height: uiSpacing12),
        if (_questions.isEmpty)
          const InlineStateMessage(
            icon: Icons.rule_outlined,
            message: 'No hay preguntas configuradas.',
            color: uiMuted,
          ),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _questions.length,
          separatorBuilder: (context, _) => const SizedBox(height: uiSpacing16),
          itemBuilder: (context, index) {
            final q = _questions[index];
            return AppCard(
              padding: const EdgeInsets.all(uiSpacing16),
              borderRadius: uiFieldRadius,
              borderColor: uiBorder,
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          initialValue: q.question,
                          decoration: const InputDecoration(
                            labelText: 'Pregunta',
                            isDense: true,
                          ),
                          onChanged: (val) {
                            _updateQuestion(
                              index,
                              KnockoutQuestion(
                                id: q.id,
                                question: val,
                                type: q.type,
                                options: q.options,
                                requiredAnswer: q.requiredAnswer,
                              ),
                            );
                          },
                        ),
                      ),
                      IconButton(
                        onPressed: () => _removeQuestion(index),
                        icon: const Icon(Icons.delete_outline, color: uiError),
                      ),
                    ],
                  ),
                  const SizedBox(height: uiSpacing12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<KnockoutQuestionType>(
                          initialValue: q.type,
                          decoration: const InputDecoration(
                            labelText: 'Tipo de respuesta',
                            isDense: true,
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: KnockoutQuestionType.boolean,
                              child: Text('Sí / No'),
                            ),
                            DropdownMenuItem(
                              value: KnockoutQuestionType.text,
                              child: Text('Texto libre'),
                            ),
                          ],
                          onChanged: (newType) {
                            if (newType != null) {
                              _updateQuestion(
                                index,
                                KnockoutQuestion(
                                  id: q.id,
                                  question: q.question,
                                  type: newType,
                                  options: q.options,
                                  requiredAnswer:
                                      newType == KnockoutQuestionType.boolean
                                      ? true
                                      : null,
                                ),
                              );
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: uiSpacing16),
                      if (q.type == KnockoutQuestionType.boolean)
                        Expanded(
                          child: DropdownButtonFormField<bool>(
                            initialValue: q.requiredAnswer as bool? ?? true,
                            decoration: const InputDecoration(
                              labelText: 'Respuesta esperada',
                              isDense: true,
                            ),
                            items: const [
                              DropdownMenuItem(value: true, child: Text('Sí')),
                              DropdownMenuItem(value: false, child: Text('No')),
                            ],
                            onChanged: (newAns) {
                              if (newAns != null) {
                                _updateQuestion(
                                  index,
                                  KnockoutQuestion(
                                    id: q.id,
                                    question: q.question,
                                    type: q.type,
                                    options: q.options,
                                    requiredAnswer: newAns,
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
