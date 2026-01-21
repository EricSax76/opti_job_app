part of 'company_job_offers_cubit.dart';

enum CompanyJobOffersStatus { initial, loading, success, failure }

class CompanyJobOffersState extends Equatable {
  const CompanyJobOffersState({
    this.status = CompanyJobOffersStatus.initial,
    this.offers = const [],
    this.errorMessage,
  });

  final CompanyJobOffersStatus status;
  final List<JobOffer> offers;
  final String? errorMessage;

  CompanyJobOffersState copyWith({
    CompanyJobOffersStatus? status,
    List<JobOffer>? offers,
    String? errorMessage,
    bool clearError = false,
  }) {
    return CompanyJobOffersState(
      status: status ?? this.status,
      offers: offers ?? this.offers,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, offers, errorMessage];
}
