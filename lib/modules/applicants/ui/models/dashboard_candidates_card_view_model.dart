class DashboardCandidateSummaryViewModel {
  const DashboardCandidateSummaryViewModel({
    required this.candidateUid,
    required this.displayName,
    required this.offerId,
  });

  final String candidateUid;
  final String displayName;
  final String offerId;
}

class DashboardCandidatesCardViewModel {
  const DashboardCandidatesCardViewModel({
    required this.candidates,
    required this.isLoading,
  });

  final List<DashboardCandidateSummaryViewModel> candidates;
  final bool isLoading;

  bool get shouldShowLoading => isLoading && candidates.isEmpty;
  bool get shouldShowEmpty => !isLoading && candidates.isEmpty;
  int get totalCandidates => candidates.length;

  List<DashboardCandidateSummaryViewModel> topCandidates({int limit = 5}) {
    if (limit <= 0) return const <DashboardCandidateSummaryViewModel>[];
    if (candidates.length <= limit) return candidates;
    return candidates.take(limit).toList(growable: false);
  }
}
