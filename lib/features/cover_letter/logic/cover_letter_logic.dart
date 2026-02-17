import 'package:opti_job_app/features/cover_letter/bloc/cover_letter_bloc.dart';
import 'package:opti_job_app/features/cover_letter/view/models/cover_letter_view_model.dart';

class CoverLetterLogic {
  const CoverLetterLogic._();

  static bool shouldListenWhen(
    CoverLetterState previous,
    CoverLetterState current,
  ) {
    return previous.status != current.status ||
        previous.savedCoverLetterText != current.savedCoverLetterText ||
        previous.improvedCoverLetter != current.improvedCoverLetter ||
        previous.error != current.error;
  }

  static bool shouldBuildWhen(
    CoverLetterState previous,
    CoverLetterState current,
  ) {
    return previous.status != current.status ||
        previous.savedCoverLetterText != current.savedCoverLetterText;
  }

  static CoverLetterViewModel buildViewModel(CoverLetterState state) {
    return CoverLetterViewModel(
      isLoading: state.status == CoverLetterStatus.loading,
      isImproving: state.status == CoverLetterStatus.improving,
    );
  }

  static String? improvedCoverLetterToApply(
    CoverLetterState state,
    String? lastAppliedImprovedCoverLetter,
  ) {
    final improvedCoverLetter = _normalizeText(state.improvedCoverLetter);
    if (improvedCoverLetter == null) return null;
    if (improvedCoverLetter == lastAppliedImprovedCoverLetter) return null;
    return improvedCoverLetter;
  }

  static bool shouldResetImprovedTracking(CoverLetterState state) {
    return _normalizeText(state.improvedCoverLetter) == null;
  }

  static String? savedCoverLetterTextToHydrate({
    required CoverLetterState state,
    required String currentText,
  }) {
    final savedCoverLetterText = _normalizeText(state.savedCoverLetterText);
    if (savedCoverLetterText == null) return null;
    if (_normalizeText(currentText) != null) return null;
    return savedCoverLetterText;
  }

  static String? failureMessage(CoverLetterState state) {
    if (state.status != CoverLetterStatus.failure) return null;
    return _normalizeText(state.error);
  }

  static bool shouldShowSavingFeedback(CoverLetterState state) {
    return state.status == CoverLetterStatus.saving;
  }

  static String? _normalizeText(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    return trimmed;
  }
}
