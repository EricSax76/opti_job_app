import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:opti_job_app/core/config/feature_flags.dart';
import 'package:opti_job_app/modules/applications/cubits/my_applications_cubit.dart';

import 'package:opti_job_app/modules/candidates/cubits/candidate_auth_cubit.dart';
import 'package:opti_job_app/modules/candidates/cubits/candidate_dashboard_cubit.dart';
import 'package:opti_job_app/modules/candidates/logic/candidate_dashboard_screen_logic.dart';
import 'package:opti_job_app/modules/candidates/models/candidate_dashboard_navigation.dart';
import 'package:opti_job_app/modules/candidates/ui/pages/candidate_dashboard_pages.dart';
import 'package:opti_job_app/modules/candidates/ui/pages/candidate_settings_screen.dart';
import 'package:opti_job_app/modules/candidates/ui/widgets/candidate_dashboard_scaffold.dart';
import 'package:opti_job_app/features/calendar/cubits/calendar_cubit.dart';
import 'package:opti_job_app/modules/interviews/cubits/interview_list_cubit.dart';
import 'package:opti_job_app/modules/curriculum/cubits/curriculum_form_cubit.dart';
import 'package:opti_job_app/modules/candidates/cubits/candidate_reminders_visibility_cubit.dart';

import 'package:opti_job_app/modules/profiles/cubits/profile_cubit.dart';
import 'package:opti_job_app/modules/profiles/ui/pages/profile_screen.dart';

class CandidateDashboardScreen extends StatefulWidget {
  const CandidateDashboardScreen({
    super.key,
    required this.uid,
    required this.initialIndex,
    required this.applicationsCubit,
    required this.interviewsCubit,
    required this.curriculumFormCubit,
    required this.calendarCubit,
    required this.profileCubit,
  });

  final String uid;
  final int initialIndex;
  final MyApplicationsCubit applicationsCubit;
  final InterviewListCubit interviewsCubit;
  final CurriculumFormCubit curriculumFormCubit;
  final CalendarCubit calendarCubit;
  final ProfileCubit profileCubit;

  @override
  State<CandidateDashboardScreen> createState() =>
      _CandidateDashboardScreenState();
}

class _CandidateDashboardScreenState extends State<CandidateDashboardScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final CandidateDashboardCubit _dashboardCubit;
  late final CandidateRemindersVisibilityCubit _remindersVisibilityCubit;
  late final List<Widget?> _dashboardPages;
  bool _isProgrammaticTabChange = false;

  @override
  void initState() {
    super.initState();
    _dashboardCubit = CandidateDashboardCubit(
      initialIndex: widget.initialIndex,
      candidateUid: widget.uid,
    );
    _remindersVisibilityCubit = CandidateRemindersVisibilityCubit();

    // Initialize TabController based on Cubit's initial state
    _tabController = TabController(
      length: candidateDashboardTabItems.length,
      vsync: this,
      initialIndex: _dashboardCubit.state.tabIndex,
    );
    _tabController.addListener(_onTabControllerChanged);

    _dashboardPages = List<Widget?>.filled(
      candidateDashboardMaxIndex + 1,
      null,
      growable: false,
    );
    _ensureDashboardPageLoaded(_dashboardCubit.state.selectedIndex);

    // _applicationsCubit is now passed via constructor
    // _interviewsCubit is now passed via constructor
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabControllerChanged);
    _tabController.dispose();
    _dashboardCubit.close();
    _remindersVisibilityCubit.close();
    // _applicationsCubit.close(); // Managed by parent provider
    // _interviewsCubit.close(); // Managed by parent provider
    super.dispose();
  }

  void _onTabControllerChanged() {
    if (_isProgrammaticTabChange) return;
    if (_tabController.indexIsChanging) return;
    _dashboardCubit.onTabChanged(_tabController.index);
  }

  void _ensureDashboardPageLoaded(int index) {
    _dashboardPages[index] ??= candidateDashboardPageForIndex(
      index,
      curriculumFormCubit: widget.curriculumFormCubit,
    );
  }

  @override
  Widget build(BuildContext context) {
    final avatarUrl = context.select(
      (ProfileCubit cubit) => cubit.state.candidate?.avatarUrl,
    );
    final profileCandidateName = context.select<ProfileCubit, String?>(
      (cubit) => cubit.state.candidate?.name,
    );
    final authCandidateName = context.select<CandidateAuthCubit, String?>(
      (cubit) => cubit.state.candidate?.name,
    );
    final candidateName = _resolveCandidateName(
      profileCandidateName: profileCandidateName,
      authCandidateName: authCandidateName,
    );
    final candidateUid = context.select(
      (CandidateAuthCubit cubit) => cubit.state.candidate?.uid,
    );

    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _dashboardCubit),
        BlocProvider.value(value: _remindersVisibilityCubit),
        BlocProvider.value(value: widget.applicationsCubit),
        BlocProvider.value(value: widget.interviewsCubit),
        BlocProvider.value(value: widget.calendarCubit),
        BlocProvider.value(value: widget.profileCubit),
        // CurriculumFormCubit provided by CurriculumScreen
      ],
      child: BlocListener<CandidateDashboardCubit, CandidateDashboardState>(
        bloc: _dashboardCubit,
        listener: (context, state) => _handleDashboardState(state),
        child: BlocBuilder<CandidateDashboardCubit, CandidateDashboardState>(
          bloc: _dashboardCubit,
          buildWhen: (previous, current) =>
              previous.selectedIndex != current.selectedIndex,
          builder: (context, state) {
            final viewModel = CandidateDashboardScreenLogic.buildViewModel(
              dashboardState: state,
              avatarUrl: avatarUrl,
              viewportWidth: MediaQuery.sizeOf(context).width,
              interviewsEnabled: FeatureFlags.interviews,
            );

            return CandidateDashboardScaffold(
              tabController: _tabController,
              viewModel: viewModel,
              candidateName: candidateName,
              dashboardPages: _dashboardPages,
              interviewsCubit: widget.interviewsCubit,
              candidateUid: candidateUid,
              onSelectIndex: (index) => _navigateToSection(context, index),
              onOpenSettings: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const CandidateSettingsScreen(),
                  ),
                );
              },
              onOpenProfile: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => ProfileScreen(cubit: widget.profileCubit),
                  ),
                );
              },
              onLogout: () => context.read<CandidateAuthCubit>().logout(),
            );
          },
        ),
      ),
    );
  }

  void _handleDashboardState(CandidateDashboardState state) {
    _ensureDashboardPageLoaded(state.selectedIndex);

    if (candidateDashboardIsTabIndex(state.selectedIndex) &&
        _tabController.index != state.tabIndex) {
      _isProgrammaticTabChange = true;
      _tabController.index = state.tabIndex;
      _isProgrammaticTabChange = false;
    }
  }

  void _navigateToSection(BuildContext context, int index) {
    final path = candidateDashboardPathForIndex(uid: widget.uid, index: index);
    if (path != null) {
      context.go(path);
    }
  }

  String? _resolveCandidateName({
    required String? profileCandidateName,
    required String? authCandidateName,
  }) {
    final profileName = profileCandidateName?.trim();
    if (profileName != null && profileName.isNotEmpty) return profileName;
    final authName = authCandidateName?.trim();
    if (authName != null && authName.isNotEmpty) return authName;
    return null;
  }
}
