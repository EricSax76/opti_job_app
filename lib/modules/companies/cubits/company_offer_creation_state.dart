import 'package:equatable/equatable.dart';

class CompanyOfferCreationState extends Equatable {
  const CompanyOfferCreationState({
    this.isGeneratingOffer = false,
  });

  final bool isGeneratingOffer;

  CompanyOfferCreationState copyWith({
    bool? isGeneratingOffer,
  }) {
    return CompanyOfferCreationState(
      isGeneratingOffer: isGeneratingOffer ?? this.isGeneratingOffer,
    );
  }

  @override
  List<Object> get props => [isGeneratingOffer];
}
