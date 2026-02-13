import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:opti_job_app/core/platform/web_history.dart';
import 'package:opti_job_app/modules/applications/cubits/my_applications_cubit.dart';
import 'package:opti_job_app/modules/applications/logic/application_service.dart';
import 'package:opti_job_app/modules/candidates/cubits/candidate_auth_cubit.dart';
import 'package:opti_job_app/modules/candidates/ui/pages/candidate_dashboard_pages.dart';
import 'package:opti_job_app/modules/candidates/ui/pages/models/candidate_dashboard_navigation.dart';
import 'package:opti_job_app/modules/candidates/ui/pages/widgets/candidate_dashboard_app_bar.dart';
import 'package:opti_job_app/modules/candidates/ui/pages/widgets/candidate_dashboard_drawer.dart';
import 'package:opti_job_app/modules/candidates/ui/pages/widgets/candidate_dashboard_sidebar.dart';
import 'package:opti_job_app/modules/profiles/cubits/profile_cubit.dart';
import 'package:opti_job_app/modules/profiles/ui/pages/profile_screen.dart';

class CandidateDashboardScreen extends StatefulWidget {
  const CandidateDashboardScreen({
    super.key,
    required this.uid,
    required this.initialIndex,
  });

  final String uid;
  final int initialIndex;

  @override
  State<CandidateDashboardScreen> createState() =>
      _CandidateDashboardScreenState();
}

class _CandidateDashboardScreenState extends State<CandidateDashboardScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final MyApplicationsCubit _applicationsCubit;
  late final List<Widget?> _dashboardPages;
  bool _isProgrammaticTabChange = false;
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    final safeIndex = candidateDashboardClampIndex(widget.initialIndex);
    _selectedIndex = safeIndex;
    _tabController = TabController(
      length: candidateDashboardTabItems.length,
      vsync: this,
      initialIndex: candidateDashboardClampTabIndex(safeIndex),
    );
    _dashboardPages = List<Widget?>.filled(
      candidateDashboardMaxIndex + 1,
      null,
      growable: false,
    );
    _ensureDashboardPageLoaded(safeIndex);
    _tabController.addListener(_handleTabChange);
    _applicationsCubit = MyApplicationsCubit(
      applicationService: context.read<ApplicationService>(),
      candidateAuthCubit: context.read<CandidateAuthCubit>(),
    )..loadMyApplications();
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    _applicationsCubit.close();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant CandidateDashboardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final safeIndex = candidateDashboardClampIndex(widget.initialIndex);
    if (safeIndex == _selectedIndex) return;
    _ensureDashboardPageLoaded(safeIndex);
    _selectedIndex = safeIndex;
    if (candidateDashboardIsTabIndex(_selectedIndex) &&
        safeIndex != _tabController.index) {
      _isProgrammaticTabChange = true;
      _tabController.index = candidateDashboardClampTabIndex(_selectedIndex);
    }
    setState(() {});
  }

  void _handleTabChange() {
    if (_isProgrammaticTabChange) {
      _isProgrammaticTabChange = false;
      return;
    }
    if (_tabController.indexIsChanging) return;

    _setSelectedIndex(
      candidateDashboardNavIndexForTabIndex(_tabController.index),
    );
  }

  void _ensureDashboardPageLoaded(int index) {
    final safeIndex = candidateDashboardClampIndex(index);
    _dashboardPages[safeIndex] ??= candidateDashboardPageForIndex(safeIndex);
  }

  void _setSelectedIndex(int index) {
    final nextIndex = candidateDashboardClampIndex(index);
    if (_selectedIndex == nextIndex) return;
    _ensureDashboardPageLoaded(nextIndex);

    setState(() {
      _selectedIndex = nextIndex;
    });

    if (candidateDashboardIsTabIndex(_selectedIndex) &&
        _tabController.index != _selectedIndex) {
      _isProgrammaticTabChange = true;
      _tabController.index = _selectedIndex;
    }

    // Update browser URL without triggering navigation
    if (kIsWeb) {
      final path = candidateDashboardPathForIndex(
        uid: widget.uid,
        index: _selectedIndex,
      );
      if (path != null) {
        pushBrowserPath(path);
      }
    }
  }

  void _handleDrawerSelection(int index) {
    Navigator.of(context).pop();
    _setSelectedIndex(index);
  }

  @override
  Widget build(BuildContext context) {
    final profileState = context.watch<ProfileCubit>().state;
    final theme = Theme.of(context);
    final avatarUrl = profileState.candidate?.avatarUrl;
    final showNavigationSidebar =
        MediaQuery.of(context).size.width >=
        candidateDashboardSidebarBreakpoint;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: CandidateDashboardAppBar(
        tabController: _tabController,
        avatarUrl: avatarUrl,
        onOpenProfile: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const ProfileScreen()),
          );
        },
        onLogout: () => context.read<CandidateAuthCubit>().logout(),
      ),
      drawer: showNavigationSidebar
          ? null
          : CandidateDashboardDrawer(
              selectedIndex: _selectedIndex,
              onSelected: _handleDrawerSelection,
            ),
      body: BlocProvider.value(
        value: _applicationsCubit,
        child: Builder(
          builder: (context) {
            final content = IndexedStack(
              index: _selectedIndex,
              children: List<Widget>.generate(
                _dashboardPages.length,
                (index) => _dashboardPages[index] ?? const SizedBox.shrink(),
                growable: false,
              ),
            );

            if (!showNavigationSidebar) {
              return content;
            }

            return Row(
              children: [
                CandidateDashboardSidebar(
                  selectedIndex: _selectedIndex,
                  onSelected: _setSelectedIndex,
                ),
                Expanded(child: content),
              ],
            );
          },
        ),
      ),
    );
  }
}
