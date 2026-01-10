import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:opti_job_app/features/ai/repositories/ai_repository.dart';
import 'package:opti_job_app/features/cover_letter/bloc/cover_letter_bloc.dart';
import 'package:opti_job_app/modules/curriculum/models/curriculum.dart';

class _MockAiRepository extends Mock implements AiRepository {}

void main() {
  setUpAll(() {
    registerFallbackValue(Curriculum.empty());
  });

  test('ImproveCoverLetterRequested emits improving then success', () async {
    final aiRepository = _MockAiRepository();
    when(
      () => aiRepository.improveCoverLetter(
        curriculum: any(named: 'curriculum'),
        coverLetterText: any(named: 'coverLetterText'),
        locale: any(named: 'locale'),
      ),
    ).thenAnswer((_) async => 'Carta mejorada');

    final bloc = CoverLetterBloc(
      aiRepository: aiRepository,
      curriculumProvider: Curriculum.empty,
      candidateUidProvider: () => 'uid',
    );

    final expectation = expectLater(
      bloc.stream,
      emitsInOrder([
        isA<CoverLetterState>().having(
          (state) => state.status,
          'status',
          CoverLetterStatus.improving,
        ),
        isA<CoverLetterState>()
            .having((state) => state.status, 'status', CoverLetterStatus.success)
            .having(
              (state) => state.improvedCoverLetter,
              'improvedCoverLetter',
              'Carta mejorada',
            ),
      ]),
    );

    bloc.add(const ImproveCoverLetterRequested('', locale: 'es-ES'));

    await expectation;
    await bloc.close();
  });
}
