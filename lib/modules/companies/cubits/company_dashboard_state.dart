import 'package:equatable/equatable.dart';

class CompanyDashboardState extends Equatable {
  const CompanyDashboardState({
    this.loadedCompanyUid,
    this.selectedIndex = 0,
    this.redirectPath,
  });

  final String? loadedCompanyUid;
  final int selectedIndex;
  final String? redirectPath;

  CompanyDashboardState copyWith({
    String? loadedCompanyUid,
    int? selectedIndex,
    String? redirectPath,
  }) {
    return CompanyDashboardState(
      loadedCompanyUid: loadedCompanyUid ?? this.loadedCompanyUid,
      selectedIndex: selectedIndex ?? this.selectedIndex,
      redirectPath: redirectPath,
    );
  }

  @override
  List<Object?> get props => [loadedCompanyUid, selectedIndex, redirectPath];
}
