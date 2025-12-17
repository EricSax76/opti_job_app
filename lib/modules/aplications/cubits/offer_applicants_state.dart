part of 'offer_applicants_cubit.dart';

enum OfferApplicantsStatus { initial, loading, success, failure }

class OfferApplicantsState extends Equatable {
  const OfferApplicantsState({
    this.statuses = const {},
    this.applicants = const {},
    this.errors = const {},
  });

  final Map<int, OfferApplicantsStatus> statuses;
  final Map<int, List<Application>> applicants;
  final Map<int, String?> errors;

  OfferApplicantsState copyWith({
    Map<int, OfferApplicantsStatus>? statuses,
    Map<int, List<Application>>? applicants,
    Map<int, String?>? errors,
  }) {
    return OfferApplicantsState(
      statuses: statuses ?? this.statuses,
      applicants: applicants ?? this.applicants,
      errors: errors ?? this.errors,
    );
  }

  @override
  List<Object?> get props => [statuses, applicants, errors];
}
