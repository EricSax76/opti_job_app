import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:opti_job_app/modules/aplications/cubits/my_applications_cubit.dart';
import 'package:opti_job_app/modules/aplications/logic/application_service.dart';
import 'package:opti_job_app/modules/candidates/cubits/candidate_auth_cubit.dart';
import 'package:opti_job_app/modules/profiles/cubits/profile_cubit.dart';
import 'package:opti_job_app/core/platform/web_history.dart';

import 'package:opti_job_app/core/theme/theme_cubit.dart';
import 'package:opti_job_app/core/theme/theme_state.dart';

import 'package:opti_job_app/modules/candidates/ui/widgets/dashboard_view.dart';
import 'package:opti_job_app/modules/candidates/ui/widgets/interviews_view.dart';
import 'package:opti_job_app/modules/candidates/ui/widgets/my_applications_view.dart';
import 'package:opti_job_app/features/cover_letter/view/cover_letter_screen.dart';
import 'package:opti_job_app/features/cover_letter/view/video_curriculum_screen.dart';
import 'package:opti_job_app/modules/profiles/ui/pages/profile_screen.dart';
import 'package:opti_job_app/modules/curriculum/ui/pages/curriculum_screen.dart';

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
  bool _isProgrammaticTabChange = false;
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    final safeIndex = widget.initialIndex.clamp(0, 5);
    _selectedIndex = safeIndex;
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: safeIndex.clamp(0, 2),
    );
    _tabController.addListener(_handleTabChange);
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant CandidateDashboardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final safeIndex = widget.initialIndex.clamp(0, 5);
    if (safeIndex == _selectedIndex) return;
    _selectedIndex = safeIndex;
    if (_selectedIndex <= 2 && safeIndex != _tabController.index) {
      _isProgrammaticTabChange = true;
      _tabController.index = _selectedIndex;
    }
    setState(() {});
  }

  void _handleTabChange() {
    if (_isProgrammaticTabChange) {
      _isProgrammaticTabChange = false;
      return;
    }
    if (_tabController.indexIsChanging) return;

    _setSelectedIndex(_tabController.index);
  }

  String? _pathForIndex(int index) {
    if (widget.uid.isEmpty) return null;
    switch (index) {
      case 0:
        return '/candidate/${widget.uid}/dashboard';
      case 1:
        return '/candidate/${widget.uid}/applications';
      case 2:
        return '/candidate/${widget.uid}/interviews';
      case 3:
        return '/candidate/${widget.uid}/cv';
      case 4:
        return '/candidate/${widget.uid}/cover-letter';
      case 5:
        return '/candidate/${widget.uid}/video-cv';
      default:
        return '/candidate/${widget.uid}/dashboard';
    }
  }

  void _setSelectedIndex(int index) {
    final nextIndex = index.clamp(0, 5);
    if (_selectedIndex == nextIndex) return;

    setState(() {
      _selectedIndex = nextIndex;
    });

    if (_selectedIndex <= 2 && _tabController.index != _selectedIndex) {
      _isProgrammaticTabChange = true;
      _tabController.index = _selectedIndex;
    }

    // Update browser URL without triggering navigation
    if (kIsWeb) {
      final path = _pathForIndex(_selectedIndex);
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
    final colorScheme = theme.colorScheme;
    final avatarUrl = profileState.candidate?.avatarUrl;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'OPTIJOB',
          style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 2),
        ),
        automaticallyImplyLeading: true,
        centerTitle: true,
        actions: [
          BlocBuilder<ThemeCubit, ThemeState>(
            builder: (context, themeState) {
              final isDark = themeState.themeMode == ThemeMode.dark;
              return IconButton(
                icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
                tooltip: isDark ? 'Modo claro' : 'Modo oscuro',
                onPressed: () => context.read<ThemeCubit>().toggleTheme(),
              );
            },
          ),
          PopupMenuButton<_CandidateAccountAction>(
            tooltip: 'Cuenta',
            onSelected: (action) {
              switch (action) {
                case _CandidateAccountAction.profile:
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const ProfileScreen(),
                    ),
                  );
                  break;
                case _CandidateAccountAction.logout:
                  context.read<CandidateAuthCubit>().logout();
                  break;
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: _CandidateAccountAction.profile,
                child: Text('Mi perfil'),
              ),
              PopupMenuDivider(),
              PopupMenuItem(
                value: _CandidateAccountAction.logout,
                child: Text('Cerrar sesión'),
              ),
            ],
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: colorScheme.surface,
                backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty)
                    ? NetworkImage(avatarUrl)
                    : null,
                child: (avatarUrl == null || avatarUrl.isEmpty)
                    ? Icon(
                        Icons.person_outline,
                        size: 18,
                        color: colorScheme.onSurfaceVariant,
                      )
                    : null,
              ),
            ),
          ),
        ],
        bottom: TabBar(
          // The TabBar goes in the 'bottom' property of a standard AppBar
          controller: _tabController,
          labelColor: colorScheme.onSurface,
          unselectedLabelColor: colorScheme.onSurfaceVariant,
          indicatorColor: colorScheme.secondary,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Para ti'),
            Tab(icon: Icon(Icons.work_history), text: 'Mis Ofertas'),
            Tab(
              icon: Icon(Icons.event_available_outlined),
              text: 'Entrevistas',
            ),
          ],
        ),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: colorScheme.surface),
              child: Center(
                child: Text(
                  'OPTIJOB',
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.description_outlined),
              title: const Text('CV'),
              selected: _selectedIndex == 3,
              onTap: () => _handleDrawerSelection(3),
            ),
            ListTile(
              leading: const Icon(Icons.mail_outline),
              title: const Text('Carta de presentación'),
              selected: _selectedIndex == 4,
              onTap: () => _handleDrawerSelection(4),
            ),
            ListTile(
              leading: const Icon(Icons.videocam_outlined),
              title: const Text('Video curriculum'),
              selected: _selectedIndex == 5,
              onTap: () => _handleDrawerSelection(5),
            ),
          ],
        ),
      ),
      body: BlocProvider(
        create: (context) => MyApplicationsCubit(
          applicationService: context.read<ApplicationService>(),
          candidateAuthCubit: context.read<CandidateAuthCubit>(),
        )..loadMyApplications(),
        child: IndexedStack(
          index: _selectedIndex,
          children: const [
            DashboardView(),
            MyApplicationsView(),
            InterviewsView(),
            CurriculumScreen(),
            CoverLetterScreen(),
            VideoCurriculumScreen(),
          ],
        ),
      ),
    );
  }
}

enum _CandidateAccountAction { profile, logout }
