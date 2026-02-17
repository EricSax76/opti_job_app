import 'package:equatable/equatable.dart';

class CompanyDashboardState extends Equatable {
  const CompanyDashboardState({
    this.loadedCompanyUid,
  });

  final String? loadedCompanyUid;

  CompanyDashboardState copyWith({
    String? loadedCompanyUid,
  }) {
    return CompanyDashboardState(
      loadedCompanyUid: loadedCompanyUid ?? this.loadedCompanyUid,
    );
  }

  @override
  List<Object?> get props => [loadedCompanyUid];
}
