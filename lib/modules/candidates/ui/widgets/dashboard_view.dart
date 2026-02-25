import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:opti_job_app/core/theme/ui_tokens.dart';
import 'package:opti_job_app/modules/candidates/cubits/candidate_auth_cubit.dart';
import 'package:opti_job_app/modules/candidates/logic/candidate_onboarding_filter_logic.dart';
import 'package:opti_job_app/modules/candidates/models/candidate.dart';
import 'package:opti_job_app/modules/candidates/models/candidate_dashboard_navigation.dart';
import 'package:opti_job_app/modules/candidates/models/job_offer_filters.dart';
import 'package:opti_job_app/modules/candidates/ui/widgets/candidate_dashboard_sidebar.dart';
import 'package:opti_job_app/modules/candidates/ui/widgets/dashboard_offers_section.dart';
import 'package:opti_job_app/modules/candidates/ui/widgets/filters/job_offer_filter_sidebar_tokens.dart';
import 'package:opti_job_app/modules/candidates/ui/widgets/job_offer_filter_sidebar.dart';
import 'package:opti_job_app/modules/job_offers/cubits/job_offers_cubit.dart';
import 'package:opti_job_app/modules/profiles/cubits/profile_state.dart';
import 'package:opti_job_app/modules/profiles/cubits/profile_cubit.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  static const double _dashboardHorizontalPadding = 24;
  static const double _minMainWidthForPinnedFilters = 560;
  static const double _minOffersWidthForGrid = 620;

  bool _showFilters = true;
  bool _isMobileFiltersOpen = false;
  bool _isMobileHeaderVisible = true;
  bool _isMobileRemindersExpanded = true;
  CandidateReminderWindow _mobileReminderWindow =
      CandidateReminderWindow.selectedDay;
  bool _didApplyOnboardingFilters = false;

  @override
  Widget build(BuildContext context) {
    final profileCandidateName = context.select<ProfileCubit, String?>(
      (cubit) => cubit.state.candidate?.name,
    );
    final authCandidateName = context.select<CandidateAuthCubit, String?>(
      (cubit) => cubit.state.candidate?.name,
    );
    final candidateName =
        profileCandidateName ?? authCandidateName ?? 'Candidato';
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return LayoutBuilder(
      builder: (context, _) {
        return BlocListener<ProfileCubit, ProfileState>(
          listenWhen: (previous, current) =>
              previous.candidate?.onboardingProfile !=
              current.candidate?.onboardingProfile,
          listener: (context, state) => _applyOnboardingFiltersIfNeeded(
            context: context,
            candidate: state.candidate,
          ),
          child: _buildDashboardContent(
            context: context,
            theme: theme,
            colorScheme: colorScheme,
            candidateName: candidateName,
          ),
        );
      },
    );
  }

  Widget _buildDashboardContent({
    required BuildContext context,
    required ThemeData theme,
    required ColorScheme colorScheme,
    required String candidateName,
  }) {
    _applyOnboardingFiltersIfNeeded(
      context: context,
      candidate: context.read<ProfileCubit>().state.candidate,
    );

    final viewportWidth = MediaQuery.sizeOf(context).width;
    final hasDesktopNavigation =
        viewportWidth >= candidateDashboardSidebarBreakpoint;
    final useCompactHeader = !hasDesktopNavigation;
    final shouldAutoHideHeader = kIsWeb || useCompactHeader;
    final reservedNavigationWidth = hasDesktopNavigation
        ? CandidateDashboardSidebar.expandedWidth
        : 0.0;
    final canPinFilters =
        viewportWidth - reservedNavigationWidth >=
        JobOfferFilterSidebarTokens.sidebarWidth +
            _minMainWidthForPinnedFilters;
    final showPinnedFilters = canPinFilters && _showFilters;
    final reservedFilterWidth = showPinnedFilters
        ? JobOfferFilterSidebarTokens.sidebarWidth
        : 0.0;
    final mainPanelWidth =
        viewportWidth - reservedNavigationWidth - reservedFilterWidth;
    final usableOffersWidth =
        (mainPanelWidth - (_dashboardHorizontalPadding * 2))
            .clamp(0.0, double.infinity)
            .toDouble();
    final showOffersGrid = usableOffersWidth >= _minOffersWidthForGrid;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showPinnedFilters)
          BlocSelector<JobOffersCubit, JobOffersState, JobOfferFilters>(
            selector: (state) => state.activeFilters,
            builder: (context, filters) {
              return JobOfferFilterSidebar(
                currentFilters: filters,
                onFiltersChanged: context.read<JobOffersCubit>().applyFilters,
              );
            },
          ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: _dashboardHorizontalPadding,
              vertical: 16,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, animation) {
                    return SizeTransition(
                      sizeFactor: animation,
                      axisAlignment: -1,
                      child: FadeTransition(opacity: animation, child: child),
                    );
                  },
                  child: (!shouldAutoHideHeader || _isMobileHeaderVisible)
                      ? Padding(
                          key: const ValueKey(
                            'dashboard_welcome_header_visible',
                          ),
                          padding: EdgeInsets.only(
                            bottom: useCompactHeader ? 12 : 24,
                          ),
                          child: Container(
                            width: double.infinity,
                            padding: EdgeInsets.symmetric(
                              horizontal: useCompactHeader ? 14 : 24,
                              vertical: useCompactHeader ? 12 : 24,
                            ),
                            decoration: BoxDecoration(
                              color: useCompactHeader
                                  ? colorScheme.primaryContainer.withValues(
                                      alpha: 0.55,
                                    )
                                  : null,
                              gradient: useCompactHeader
                                  ? null
                                  : LinearGradient(
                                      colors: [
                                        colorScheme.primaryContainer,
                                        colorScheme.primaryContainer.withValues(
                                          alpha: 0.5,
                                        ),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                              borderRadius: BorderRadius.circular(
                                useCompactHeader ? 14 : uiCardRadius,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Hola, $candidateName',
                                  style:
                                      (useCompactHeader
                                              ? theme.textTheme.titleMedium
                                              : theme.textTheme.headlineSmall)
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color:
                                                colorScheme.onPrimaryContainer,
                                          ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Aquí tienes las mejores ofertas seleccionadas para ti.',
                                  maxLines: useCompactHeader ? 2 : null,
                                  overflow: useCompactHeader
                                      ? TextOverflow.ellipsis
                                      : TextOverflow.visible,
                                  style:
                                      (useCompactHeader
                                              ? theme.textTheme.bodyMedium
                                              : theme.textTheme.bodyLarge)
                                          ?.copyWith(
                                            color: colorScheme
                                                .onPrimaryContainer
                                                .withValues(alpha: 0.8),
                                          ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : const SizedBox(
                          key: ValueKey('dashboard_welcome_header_hidden'),
                        ),
                ),
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: () => _handleFiltersToggle(
                        context: context,
                        canPinFilters: canPinFilters,
                      ),
                      icon: Icon(
                        canPinFilters
                            ? (_showFilters
                                  ? Icons.filter_list_off
                                  : Icons.filter_list)
                            : (_isMobileFiltersOpen
                                  ? Icons.filter_list_off
                                  : Icons.filter_list),
                      ),
                      label: Text(
                        canPinFilters
                            ? (_showFilters ? 'Ocultar filtros' : 'Filtros')
                            : (_isMobileFiltersOpen
                                  ? 'Cerrar filtros'
                                  : 'Filtros'),
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: colorScheme.secondary,
                      ),
                    ),
                    const Spacer(),
                  ],
                ),
                SizedBox(height: useCompactHeader ? 12 : 16),
                Expanded(
                  child: hasDesktopNavigation
                      ? NotificationListener<ScrollNotification>(
                          onNotification: (notification) =>
                              _handleOffersScrollNotification(
                                notification: notification,
                                enableHeaderAutoHide: shouldAutoHideHeader,
                              ),
                          child: DashboardOffersSection(
                            showTwoColumns: showOffersGrid,
                          ),
                        )
                      : Column(
                          children: [
                            Expanded(
                              child: NotificationListener<ScrollNotification>(
                                onNotification: (notification) =>
                                    _handleOffersScrollNotification(
                                      notification: notification,
                                      enableHeaderAutoHide:
                                          shouldAutoHideHeader,
                                    ),
                                child: DashboardOffersSection(
                                  showTwoColumns: showOffersGrid,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            CandidateReminderPanel(
                              isExpanded: _isMobileRemindersExpanded,
                              onToggle: () {
                                setState(() {
                                  _isMobileRemindersExpanded =
                                      !_isMobileRemindersExpanded;
                                });
                              },
                              window: _mobileReminderWindow,
                              onWindowChanged: (window) {
                                setState(() {
                                  _mobileReminderWindow = window;
                                });
                              },
                            ),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _applyOnboardingFiltersIfNeeded({
    required BuildContext context,
    required Candidate? candidate,
  }) {
    if (_didApplyOnboardingFilters) return;

    final onboardingFilters =
        CandidateOnboardingFilterLogic.buildInitialFilters(candidate);
    if (onboardingFilters == null) return;

    final jobOffersCubit = context.read<JobOffersCubit>();
    if (jobOffersCubit.state.activeFilters.hasActiveFilters) {
      _didApplyOnboardingFilters = true;
      return;
    }

    _didApplyOnboardingFilters = true;
    jobOffersCubit.applyFilters(onboardingFilters);
  }

  bool _handleOffersScrollNotification({
    required ScrollNotification notification,
    required bool enableHeaderAutoHide,
  }) {
    if (!enableHeaderAutoHide) return false;
    if (notification.metrics.axis != Axis.vertical) return false;

    if (notification.metrics.pixels <= 8) {
      if (!_isMobileHeaderVisible) {
        setState(() => _isMobileHeaderVisible = true);
      }
      return false;
    }

    if (notification is UserScrollNotification) {
      if (notification.direction == ScrollDirection.reverse &&
          _isMobileHeaderVisible) {
        setState(() => _isMobileHeaderVisible = false);
      } else if (notification.direction == ScrollDirection.forward &&
          !_isMobileHeaderVisible) {
        setState(() => _isMobileHeaderVisible = true);
      }
    }
    return false;
  }

  Future<void> _handleFiltersToggle({
    required BuildContext context,
    required bool canPinFilters,
  }) async {
    if (canPinFilters) {
      setState(() => _showFilters = !_showFilters);
      return;
    }

    if (_isMobileFiltersOpen) {
      Navigator.of(context).maybePop();
      return;
    }

    setState(() => _isMobileFiltersOpen = true);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) {
        return FractionallySizedBox(
          heightFactor: 0.9,
          child: BlocSelector<JobOffersCubit, JobOffersState, JobOfferFilters>(
            selector: (state) => state.activeFilters,
            builder: (context, filters) {
              return JobOfferFilterSidebar(
                currentFilters: filters,
                onFiltersChanged: context.read<JobOffersCubit>().applyFilters,
              );
            },
          ),
        );
      },
    );
    if (!mounted) return;
    setState(() => _isMobileFiltersOpen = false);
  }
}
