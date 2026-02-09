part of 'cover_letter_bloc.dart';

enum CoverLetterStatus { initial, loading, improving, saving, success, failure }

class CoverLetterState extends Equatable {
  static const Object _unset = Object();

  const CoverLetterState({
    this.status = CoverLetterStatus.initial,
    this.savedCoverLetterText,
    this.improvedCoverLetter,
    this.error,
  });

  final CoverLetterStatus status;
  final String? savedCoverLetterText;
  final String? improvedCoverLetter;
  final String? error;

  CoverLetterState copyWith({
    CoverLetterStatus? status,
    Object? savedCoverLetterText = _unset,
    Object? improvedCoverLetter = _unset,
    String? Function()? error,
  }) {
    return CoverLetterState(
      status: status ?? this.status,
      savedCoverLetterText: savedCoverLetterText == _unset
          ? this.savedCoverLetterText
          : savedCoverLetterText as String?,
      improvedCoverLetter: improvedCoverLetter == _unset
          ? this.improvedCoverLetter
          : improvedCoverLetter as String?,
      error: error != null ? error() : this.error,
    );
  }

  @override
  List<Object?> get props => [
    status,
    savedCoverLetterText,
    improvedCoverLetter,
    error,
  ];
}
