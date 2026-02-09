import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:opti_job_app/features/ai/repositories/ai_repository.dart';
import 'package:opti_job_app/features/cover_letter/bloc/cover_letter_bloc.dart';
import 'package:opti_job_app/features/cover_letter/repositories/cover_letter_repository.dart';
import 'package:opti_job_app/features/cover_letter/services/cover_letter_service.dart';
import 'package:opti_job_app/modules/curriculum/models/curriculum.dart';

class _MockAiRepository extends Mock implements AiRepository {}

void main() {
  setUpAll(() {
    registerFallbackValue(Curriculum.empty());
  });

  group('ImproveCoverLetterRequested', () {
    test('emits improving then success', () async {
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
        coverLetterRepository: _buildCoverLetterRepository(),
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
              .having(
                (state) => state.status,
                'status',
                CoverLetterStatus.success,
              )
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
  });

  group('SaveCoverLetterRequested', () {
    test(
      'saves text in Firestore and clears stale improvedCoverLetter',
      () async {
        final aiRepository = _MockAiRepository();
        when(
          () => aiRepository.improveCoverLetter(
            curriculum: any(named: 'curriculum'),
            coverLetterText: any(named: 'coverLetterText'),
            locale: any(named: 'locale'),
          ),
        ).thenAnswer((_) async => 'Carta mejorada');

        final firestore = FakeFirebaseFirestore();
        await firestore.collection('candidates').doc('uid').set({});

        final bloc = CoverLetterBloc(
          aiRepository: aiRepository,
          coverLetterRepository: _buildCoverLetterRepository(firestore),
          curriculumProvider: Curriculum.empty,
          candidateUidProvider: () => 'uid',
        );

        bloc.add(
          const ImproveCoverLetterRequested('borrador', locale: 'es-ES'),
        );
        await _waitForState(
          bloc,
          (state) =>
              state.status == CoverLetterStatus.success &&
              state.improvedCoverLetter == 'Carta mejorada',
        );

        bloc.add(const SaveCoverLetterRequested('Carta definitiva'));
        await _waitForState(
          bloc,
          (state) =>
              state.status == CoverLetterStatus.success &&
              state.savedCoverLetterText == 'Carta definitiva',
        );

        expect(bloc.state.improvedCoverLetter, isNull);
        final candidateDoc = await firestore
            .collection('candidates')
            .doc('uid')
            .get();
        final data = candidateDoc.data();
        expect(data, isNotNull);
        final coverLetterData = data!['cover_letter'] as Map<String, dynamic>?;
        expect(coverLetterData?['text'], 'Carta definitiva');

        await bloc.close();
      },
    );

    test('fails when text is empty', () async {
      final bloc = CoverLetterBloc(
        aiRepository: _MockAiRepository(),
        coverLetterRepository: _buildCoverLetterRepository(),
        curriculumProvider: Curriculum.empty,
        candidateUidProvider: () => 'uid',
      );

      bloc.add(const SaveCoverLetterRequested(''));
      await _waitForState(
        bloc,
        (state) => state.status == CoverLetterStatus.failure,
      );

      expect(bloc.state.error, 'Escribe tu carta antes de guardar.');
      await bloc.close();
    });

    test('fails when candidate is not authenticated', () async {
      final bloc = CoverLetterBloc(
        aiRepository: _MockAiRepository(),
        coverLetterRepository: _buildCoverLetterRepository(),
        curriculumProvider: Curriculum.empty,
        candidateUidProvider: () => null,
      );

      bloc.add(const SaveCoverLetterRequested('Texto'));
      await _waitForState(
        bloc,
        (state) => state.status == CoverLetterStatus.failure,
      );

      expect(bloc.state.error, 'Debes iniciar sesión para guardar.');
      await bloc.close();
    });

    test('emits failure when firestore update throws', () async {
      final firestore = FakeFirebaseFirestore();
      final bloc = CoverLetterBloc(
        aiRepository: _MockAiRepository(),
        coverLetterRepository: _buildCoverLetterRepository(firestore),
        curriculumProvider: Curriculum.empty,
        candidateUidProvider: () => 'uid',
      );

      bloc.add(const SaveCoverLetterRequested('Texto'));
      await _waitForState(
        bloc,
        (state) => state.status == CoverLetterStatus.failure,
      );

      expect(bloc.state.error, isNotNull);
      await bloc.close();
    });
  });

  group('LoadCoverLetterRequested', () {
    test('loads and trims saved cover letter text', () async {
      final firestore = FakeFirebaseFirestore();
      await firestore.collection('candidates').doc('uid').set({
        'cover_letter': {'text': '  Hola mundo  '},
      });

      final bloc = CoverLetterBloc(
        aiRepository: _MockAiRepository(),
        coverLetterRepository: _buildCoverLetterRepository(firestore),
        curriculumProvider: Curriculum.empty,
        candidateUidProvider: () => 'uid',
      );

      bloc.add(LoadCoverLetterRequested());
      await _waitForState(
        bloc,
        (state) =>
            state.status == CoverLetterStatus.initial &&
            state.savedCoverLetterText == 'Hola mundo',
      );

      expect(bloc.state.savedCoverLetterText, 'Hola mundo');
      await bloc.close();
    });
  });

  group('SaveCoverLetterRequested status', () {
    test('emits saving before success when save works', () async {
      final firestore = FakeFirebaseFirestore();
      await firestore.collection('candidates').doc('uid').set({});

      final bloc = CoverLetterBloc(
        aiRepository: _MockAiRepository(),
        coverLetterRepository: _buildCoverLetterRepository(firestore),
        curriculumProvider: Curriculum.empty,
        candidateUidProvider: () => 'uid',
      );

      final expectation = expectLater(
        bloc.stream,
        emitsThrough(
          isA<CoverLetterState>().having(
            (state) => state.status,
            'status',
            CoverLetterStatus.saving,
          ),
        ),
      );

      bloc.add(const SaveCoverLetterRequested('Carta'));
      await expectation;
      await _waitForState(
        bloc,
        (state) => state.status == CoverLetterStatus.success,
      );
      await bloc.close();
    });
  });
}

Future<CoverLetterState> _waitForState(
  CoverLetterBloc bloc,
  bool Function(CoverLetterState state) matcher,
) async {
  if (matcher(bloc.state)) {
    return bloc.state;
  }
  return bloc.stream.firstWhere(matcher);
}

CoverLetterRepository _buildCoverLetterRepository([
  FakeFirebaseFirestore? firestore,
]) {
  return CoverLetterRepository(
    CoverLetterService(firestore: firestore ?? FakeFirebaseFirestore()),
  );
}
