part of 'my_applications_cubit.dart';

enum ApplicationsStatus { initial, loading, success, error }

class MyApplicationsState extends Equatable {
  const MyApplicationsState({
    this.status = ApplicationsStatus.initial,
    this.applications = const [],
    this.errorMessage,
  });

  final ApplicationsStatus status;
  final List<CandidateApplicationEntry> applications;
  final String? errorMessage;

  MyApplicationsState copyWith({
    ApplicationsStatus? status,
    List<CandidateApplicationEntry>? applications,
    String? errorMessage,
  }) {
    return MyApplicationsState(
      status: status ?? this.status,
      applications: applications ?? this.applications,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, applications, errorMessage];
}
