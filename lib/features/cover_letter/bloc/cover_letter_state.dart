part of 'cover_letter_bloc.dart';

enum CoverLetterStatus {
  initial,
  loading,
  success,
  failure,
  uploading,
  improving,
  recording,
}

class CoverLetterState extends Equatable {
  static const Object _unset = Object();

  const CoverLetterState({
    this.status = CoverLetterStatus.initial,
    this.attemptsLeft = 3,
    this.savedCoverLetterText,
    this.recordedVideoPath,
    this.improvedCoverLetter,
    this.error,
  });

  final CoverLetterStatus status;
  final int attemptsLeft;
  final String? savedCoverLetterText;
  final String? recordedVideoPath;
  final String? improvedCoverLetter;
  final String? error;

  CoverLetterState copyWith({
    CoverLetterStatus? status,
    int? attemptsLeft,
    Object? savedCoverLetterText = _unset,
    Object? recordedVideoPath = _unset,
    Object? improvedCoverLetter = _unset,
    String? Function()? error,
  }) {
    return CoverLetterState(
      status: status ?? this.status,
      attemptsLeft: attemptsLeft ?? this.attemptsLeft,
      savedCoverLetterText: savedCoverLetterText == _unset
          ? this.savedCoverLetterText
          : savedCoverLetterText as String?,
      recordedVideoPath: recordedVideoPath == _unset
          ? this.recordedVideoPath
          : recordedVideoPath as String?,
      improvedCoverLetter: improvedCoverLetter == _unset
          ? this.improvedCoverLetter
          : improvedCoverLetter as String?,
      error: error != null ? error() : this.error,
    );
  }

  @override
  List<Object?> get props => [
        status,
        attemptsLeft,
        savedCoverLetterText,
        recordedVideoPath,
        improvedCoverLetter,
        error,
      ];
}
