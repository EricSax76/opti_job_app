part of 'company_candidates_cubit.dart';

@immutable
sealed class CompanyCandidatesState extends Equatable {
  const CompanyCandidatesState({
    this.groupedCandidates = const [],
    this.profiles = const {},
    this.isLoading = false,
  });

  final List<CandidateGroup> groupedCandidates;
  final Map<String, Candidate> profiles;
  final bool isLoading;

  @override
  List<Object?> get props => [groupedCandidates, profiles, isLoading];
}

class CompanyCandidatesInitial extends CompanyCandidatesState {
  const CompanyCandidatesInitial() : super();
}

class CompanyCandidatesLoaded extends CompanyCandidatesState {
  const CompanyCandidatesLoaded({
    required super.groupedCandidates,
    required super.profiles,
    super.isLoading = false,
  });
  
  CompanyCandidatesLoaded copyWith({
    List<CandidateGroup>? groupedCandidates,
    Map<String, Candidate>? profiles,
    bool? isLoading,
  }) {
    return CompanyCandidatesLoaded(
      groupedCandidates: groupedCandidates ?? this.groupedCandidates,
      profiles: profiles ?? this.profiles,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}
