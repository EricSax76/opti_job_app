import 'package:equatable/equatable.dart';

class OfferCardViewModel extends Equatable {
  const OfferCardViewModel({
    required this.subtitle,
    required this.companyUid,
    this.avatarUrl,
  });

  final String subtitle;
  final String? companyUid;
  final String? avatarUrl;

  @override
  List<Object?> get props => [subtitle, companyUid, avatarUrl];
}
