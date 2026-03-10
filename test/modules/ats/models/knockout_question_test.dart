import 'package:flutter_test/flutter_test.dart';
import 'package:opti_job_app/modules/ats/models/knockout_question.dart';

void main() {
  group('KnockoutQuestion.fromFirestore', () {
    test('normaliza id/question y filtra opciones no string', () {
      final question = KnockoutQuestion.fromFirestore({
        'id': 123,
        'question': 456,
        'type': 'multiple_choice',
        'options': ['Si', 1, null, '  ', 'No'],
      });

      expect(question.id, '123');
      expect(question.question, '456');
      expect(question.type, KnockoutQuestionType.multipleChoice);
      expect(question.options, ['Si', 'No']);
    });

    test('usa tipo text cuando el tipo no es reconocible', () {
      final question = KnockoutQuestion.fromFirestore({
        'id': 'q-1',
        'question': 'Pregunta',
        'type': 999,
      });

      expect(question.type, KnockoutQuestionType.text);
      expect(question.options, isNull);
    });
  });
}
