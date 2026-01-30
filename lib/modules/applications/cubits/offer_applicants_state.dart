part of 'offer_applicants_cubit.dart';

enum OfferApplicantsStatus { initial, loading, success, failure }

class OfferApplicantsState extends Equatable {
  const OfferApplicantsState({
    this.statuses = const {},
    this.applicants = const {},
    this.errors = const {},
  });

  final Map<String, OfferApplicantsStatus> statuses;
  final Map<String, List<Application>> applicants;
  final Map<String, String?> errors;

  OfferApplicantsState copyWith({
    Map<String, OfferApplicantsStatus>? statuses,
    Map<String, List<Application>>? applicants,
    Map<String, String?>? errors,
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
