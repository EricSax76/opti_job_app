import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:opti_job_app/core/theme/ui_tokens.dart';
import 'package:opti_job_app/modules/candidates/cubits/candidate_auth_cubit.dart';
import 'package:opti_job_app/modules/candidates/cubits/candidate_reminders_visibility_cubit.dart';
import 'package:opti_job_app/modules/candidates/logic/candidate_onboarding_filter_logic.dart';
import 'package:opti_job_app/modules/candidates/logic/dashboard_layout_logic.dart';
import 'package:opti_job_app/modules/candidates/logic/dashboard_scroll_logic.dart';
import 'package:opti_job_app/modules/candidates/models/candidate.dart';

import 'package:opti_job_app/modules/candidates/models/job_offer_filters.dart';
import 'package:opti_job_app/modules/candidates/ui/widgets/candidate_dashboard_filter_toggle_row.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:opti_job_app/modules/candidates/ui/widgets/candidate_dashboard_welcome_header.dart';
import 'package:opti_job_app/modules/candidates/ui/widgets/dashboard_offers_section.dart';

import 'package:opti_job_app/modules/candidates/ui/widgets/job_offer_filter_sidebar.dart';
import 'package:opti_job_app/modules/job_offers/cubits/job_offers_cubit.dart';
import 'package:opti_job_app/modules/profiles/cubits/profile_state.dart';
import 'package:opti_job_app/modules/profiles/cubits/profile_cubit.dart';
import 'package:opti_job_app/modules/candidates/ui/widgets/candidate_reminder_panel.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  bool _showFilters = true;
  bool _isMobileFiltersOpen = false;
  bool _isMobileHeaderVisible = true;
  bool _isMobileRemindersExpanded = true;
  CandidateReminderWindow _mobileReminderWindow =
      CandidateReminderWindow.selectedDay;
  bool _didApplyOnboardingFilters = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _applyOnboardingFiltersIfNeeded(
        context: context,
        candidate: context.read<ProfileCubit>().state.candidate,
      );
    });
  }

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
    final isDark = theme.brightness == Brightness.dark;
    final _ = isDark ? uiDarkOnPrimaryContainer : uiLightOnPrimaryContainer;

    final viewportWidth = MediaQuery.sizeOf(context).width;
    final layout = DashboardLayoutLogic.compute(
      viewportWidth: viewportWidth,
      showFilters: _showFilters,
    );

    final hasDesktopNavigation = layout.hasDesktopNavigation;
    final useCompactHeader = layout.useCompactHeader;
    final shouldAutoHideHeader = layout.shouldAutoHideHeader;
    final canPinFilters = layout.canPinFilters;
    final showPinnedFilters = layout.showPinnedFilters;
    final canDismissPinnedFiltersFromSidebar =
        layout.canDismissPinnedFiltersFromSidebar;
    final showOffersGrid = layout.showOffersGrid;

    final content = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showPinnedFilters)
          BlocSelector<JobOffersCubit, JobOffersState, JobOfferFilters>(
            selector: (state) => state.activeFilters,
            builder: (context, filters) {
              return JobOfferFilterSidebar(
                currentFilters: filters,
                onFiltersChanged: context.read<JobOffersCubit>().applyFilters,
                onBackgroundTap: canDismissPinnedFiltersFromSidebar
                    ? _closePinnedFilters
                    : null,
              );
            },
          ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: DashboardLayoutLogic.dashboardHorizontalPadding,
              vertical: 16,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CandidateDashboardWelcomeHeader(
                  candidateName: candidateName,
                  useCompactHeader: useCompactHeader,
                  shouldAutoHideHeader: shouldAutoHideHeader,
                  isVisible: _isMobileHeaderVisible,
                ),
                CandidateDashboardFilterToggleRow(
                  canPinFilters: canPinFilters,
                  showFilters: _showFilters,
                  isMobileFiltersOpen: _isMobileFiltersOpen,
                  onToggle: () => _handleFiltersToggle(
                    context: context,
                    canPinFilters: canPinFilters,
                  ),
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
                            BlocBuilder<
                              CandidateRemindersVisibilityCubit,
                              bool
                            >(
                              builder: (context, remindersVisible) {
                                if (!remindersVisible) {
                                  return const SizedBox.shrink();
                                }
                                return Padding(
                                  padding: const EdgeInsets.only(top: 16),
                                  child: Dismissible(
                                    key: const ValueKey(
                                      'mobile_reminder_panel',
                                    ),
                                    direction: DismissDirection.startToEnd,
                                    onDismissed: (_) {
                                      context
                                          .read<
                                            CandidateRemindersVisibilityCubit
                                          >()
                                          .hideReminders();
                                    },
                                    background: Container(
                                      color: colorScheme.surface.withValues(
                                        alpha: 0,
                                      ),
                                    ),
                                    child: CandidateReminderPanel(
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
                                  ),
                                );
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

    if (!kIsWeb) return content;

    return Focus(
      autofocus: canDismissPinnedFiltersFromSidebar,
      onKeyEvent: (_, event) {
        if (!canDismissPinnedFiltersFromSidebar) {
          return KeyEventResult.ignored;
        }
        final isEscape =
            event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.escape;
        if (!isEscape) return KeyEventResult.ignored;

        _closePinnedFilters();
        return KeyEventResult.handled;
      },
      child: content,
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
    final nextVisibility = DashboardScrollLogic.handleOffersScrollNotification(
      notification: notification,
      enableHeaderAutoHide: enableHeaderAutoHide,
      isMobileHeaderVisible: _isMobileHeaderVisible,
    );
    if (nextVisibility != null) {
      setState(() => _isMobileHeaderVisible = nextVisibility);
    }
    return false;
  }

  void _closePinnedFilters() {
    if (!_showFilters) return;
    setState(() => _showFilters = false);
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
      backgroundColor: Theme.of(
        context,
      ).colorScheme.surface.withValues(alpha: 0),
      elevation: 0,
      builder: (sheetContext) {
        return FractionallySizedBox(
          heightFactor: 0.9,
          child: BlocSelector<JobOffersCubit, JobOffersState, JobOfferFilters>(
            selector: (state) => state.activeFilters,
            builder: (context, filters) {
              return Container(
                    clipBehavior: Clip.antiAlias,
                    margin: const EdgeInsets.only(top: 8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(32),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(
                            context,
                          ).colorScheme.shadow.withValues(alpha: 0.15),
                          blurRadius: 24,
                          offset: const Offset(0, -8),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Center(
                          child: Container(
                            margin: const EdgeInsets.only(top: 12, bottom: 8),
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                        Expanded(
                          child: JobOfferFilterSidebar(
                            currentFilters: filters,
                            onFiltersChanged: context
                                .read<JobOffersCubit>()
                                .applyFilters,
                          ),
                        ),
                      ],
                    ),
                  )
                  .animate()
                  .fadeIn(duration: 400.ms, curve: Curves.easeOut)
                  .slideY(
                    begin: 0.1,
                    duration: 600.ms,
                    curve: Curves.easeOutQuart,
                  )
                  .scaleXY(
                    begin: 0.1,
                    end: 1.0,
                    duration: 600.ms,
                    curve: Curves.easeOutQuart,
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
