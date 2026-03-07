part of 'company_candidates_cubit.dart';

@immutable
sealed class CompanyCandidatesState extends Equatable {
  const CompanyCandidatesState({
    this.groupedCandidates = const [],
    this.isLoading = false,
  });

  final List<CandidateGroup> groupedCandidates;
  final bool isLoading;

  @override
  List<Object?> get props => [groupedCandidates, isLoading];
}

class CompanyCandidatesInitial extends CompanyCandidatesState {
  const CompanyCandidatesInitial() : super();
}

class CompanyCandidatesLoaded extends CompanyCandidatesState {
  const CompanyCandidatesLoaded({
    required super.groupedCandidates,
    super.isLoading = false,
  });

  CompanyCandidatesLoaded copyWith({
    List<CandidateGroup>? groupedCandidates,
    bool? isLoading,
  }) {
    return CompanyCandidatesLoaded(
      groupedCandidates: groupedCandidates ?? this.groupedCandidates,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}
