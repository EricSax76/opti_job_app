import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:opti_job_app/modules/candidates/models/candidate_dashboard_navigation.dart';
import 'package:opti_job_app/modules/candidates/ui/widgets/candidate_dashboard_sidebar.dart';
import 'package:opti_job_app/modules/candidates/ui/widgets/filters/job_offer_filter_sidebar_tokens.dart';

class DashboardLayoutState {
  const DashboardLayoutState({
    required this.hasDesktopNavigation,
    required this.useCompactHeader,
    required this.shouldAutoHideHeader,
    required this.canPinFilters,
    required this.showPinnedFilters,
    required this.canDismissPinnedFiltersFromSidebar,
    required this.showOffersGrid,
  });

  final bool hasDesktopNavigation;
  final bool useCompactHeader;
  final bool shouldAutoHideHeader;
  final bool canPinFilters;
  final bool showPinnedFilters;
  final bool canDismissPinnedFiltersFromSidebar;
  final bool showOffersGrid;
}

class DashboardLayoutLogic {
  const DashboardLayoutLogic._();

  static const double dashboardHorizontalPadding = 24;
  static const double minMainWidthForPinnedFilters = 560;
  static const double minOffersWidthForGrid = 620;

  static DashboardLayoutState compute({
    required double viewportWidth,
    required bool showFilters,
  }) {
    final hasDesktopNavigation =
        viewportWidth >= candidateDashboardSidebarBreakpoint;
    final useCompactHeader = !hasDesktopNavigation;
    final shouldAutoHideHeader = kIsWeb || useCompactHeader;
    final reservedNavigationWidth = hasDesktopNavigation
        ? CandidateDashboardSidebar.expandedWidth
        : 0.0;
    final canPinFilters = viewportWidth - reservedNavigationWidth >=
        JobOfferFilterSidebarTokens.sidebarWidth + minMainWidthForPinnedFilters;
    final showPinnedFilters = canPinFilters && showFilters;
    final canDismissPinnedFiltersFromSidebar = kIsWeb && showPinnedFilters;
    final reservedFilterWidth = showPinnedFilters
        ? JobOfferFilterSidebarTokens.sidebarWidth
        : 0.0;
    final mainPanelWidth =
        viewportWidth - reservedNavigationWidth - reservedFilterWidth;
    final usableOffersWidth =
        (mainPanelWidth - (dashboardHorizontalPadding * 2))
            .clamp(0.0, double.infinity)
            .toDouble();
    final showOffersGrid = usableOffersWidth >= minOffersWidthForGrid;

    return DashboardLayoutState(
      hasDesktopNavigation: hasDesktopNavigation,
      useCompactHeader: useCompactHeader,
      shouldAutoHideHeader: shouldAutoHideHeader,
      canPinFilters: canPinFilters,
      showPinnedFilters: showPinnedFilters,
      canDismissPinnedFiltersFromSidebar: canDismissPinnedFiltersFromSidebar,
      showOffersGrid: showOffersGrid,
    );
  }
}
