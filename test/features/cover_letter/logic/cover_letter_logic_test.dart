import 'package:flutter_test/flutter_test.dart';
import 'package:opti_job_app/features/cover_letter/bloc/cover_letter_bloc.dart';
import 'package:opti_job_app/features/cover_letter/logic/cover_letter_logic.dart';

void main() {
  group('CoverLetterLogic', () {
    test('shouldListenWhen reacts to status, text and error changes', () {
      const previous = CoverLetterState(status: CoverLetterStatus.initial);
      const currentStatus = CoverLetterState(status: CoverLetterStatus.loading);
      const currentText = CoverLetterState(savedCoverLetterText: 'Carta');
      const currentError = CoverLetterState(
        status: CoverLetterStatus.failure,
        error: 'Error',
      );

      expect(
        CoverLetterLogic.shouldListenWhen(previous, currentStatus),
        isTrue,
      );
      expect(CoverLetterLogic.shouldListenWhen(previous, currentText), isTrue);
      expect(CoverLetterLogic.shouldListenWhen(previous, currentError), isTrue);
      expect(CoverLetterLogic.shouldListenWhen(previous, previous), isFalse);
    });

    test('buildViewModel maps loading and improving flags', () {
      const loading = CoverLetterState(status: CoverLetterStatus.loading);
      const improving = CoverLetterState(status: CoverLetterStatus.improving);

      expect(CoverLetterLogic.buildViewModel(loading).isLoading, isTrue);
      expect(CoverLetterLogic.buildViewModel(loading).isImproving, isFalse);
      expect(CoverLetterLogic.buildViewModel(improving).isImproving, isTrue);
    });

    test('improvedCoverLetterToApply avoids duplicates and trims values', () {
      const state = CoverLetterState(improvedCoverLetter: '  Texto mejorado  ');

      expect(
        CoverLetterLogic.improvedCoverLetterToApply(state, null),
        'Texto mejorado',
      );
      expect(
        CoverLetterLogic.improvedCoverLetterToApply(state, 'Texto mejorado'),
        isNull,
      );
    });

    test(
      'savedCoverLetterTextToHydrate only applies when current text is empty',
      () {
        const state = CoverLetterState(
          savedCoverLetterText: ' Carta guardada ',
        );

        expect(
          CoverLetterLogic.savedCoverLetterTextToHydrate(
            state: state,
            currentText: ' ',
          ),
          'Carta guardada',
        );
        expect(
          CoverLetterLogic.savedCoverLetterTextToHydrate(
            state: state,
            currentText: 'ya existe',
          ),
          isNull,
        );
      },
    );

    test('failureMessage and saving feedback depend on state status', () {
      const failure = CoverLetterState(
        status: CoverLetterStatus.failure,
        error: ' Error ',
      );
      const saving = CoverLetterState(status: CoverLetterStatus.saving);

      expect(CoverLetterLogic.failureMessage(failure), 'Error');
      expect(CoverLetterLogic.failureMessage(saving), isNull);
      expect(CoverLetterLogic.shouldShowSavingFeedback(saving), isTrue);
      expect(CoverLetterLogic.shouldShowSavingFeedback(failure), isFalse);
    });
  });
}
