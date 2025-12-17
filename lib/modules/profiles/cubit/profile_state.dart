import 'package:equatable/equatable.dart';
import 'package:opti_job_app/modules/candidates/models/candidate.dart';
import 'package:opti_job_app/modules/companies/models/company.dart';

enum ProfileStatus { initial, loading, loaded, failure, empty }

class ProfileState extends Equatable {
  const ProfileState({
    this.status = ProfileStatus.initial,
    this.candidate,
    this.company,
    this.errorMessage,
  });

  final ProfileStatus status;
  final Candidate? candidate;
  final Company? company;
  final String? errorMessage;

  @override
  List<Object?> get props => [status, candidate, company, errorMessage];

  ProfileState copyWith({
    ProfileStatus? status,
    Candidate? candidate,
    Company? company,
    String? errorMessage,
    bool clearCandidate = false,
    bool clearCompany = false,
    bool clearError = false,
  }) {
    return ProfileState(
      status: status ?? this.status,
      candidate: clearCandidate ? null : candidate ?? this.candidate,
      company: clearCompany ? null : company ?? this.company,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}
