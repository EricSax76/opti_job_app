import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:opti_job_app/modules/aplications/cubits/my_applications_cubit.dart';
import 'package:opti_job_app/modules/aplications/logic/application_service.dart';
import 'package:opti_job_app/modules/candidates/cubits/candidate_auth_cubit.dart';
import 'package:opti_job_app/modules/profiles/cubits/profile_cubit.dart';
import 'package:opti_job_app/core/theme/ui_tokens.dart';

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

  @override
  void initState() {
    super.initState();
    final safeIndex = widget.initialIndex.clamp(0, 5);
    _tabController = TabController(
      length: 6,
      vsync: this,
      initialIndex: safeIndex,
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
    if (safeIndex != _tabController.index) {
      _isProgrammaticTabChange = true;
      _tabController.index = safeIndex;
    }
  }

  void _handleTabChange() {
    if (_isProgrammaticTabChange) {
      _isProgrammaticTabChange = false;
      return;
    }
    if (_tabController.indexIsChanging) return;
    final path = _pathForIndex(_tabController.index);
    if (path != null) context.go(path);
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

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<CandidateAuthCubit>().state;
    final profileState = context.watch<ProfileCubit>().state;
    const background = uiBackground;
    const ink = uiInk;
    const muted = uiMuted;
    const accent = uiAccent;
    const border = uiBorder;
    final avatarUrl = profileState.candidate?.avatarUrl;

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: const Text(
          'OPTIJOB',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
          ),
        ),
        automaticallyImplyLeading: false,
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: ink,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: const Border(
          bottom: BorderSide(color: border, width: 1),
        ),
        actions: [
          IconButton(
            tooltip: 'Perfil',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const ProfileScreen(),
              ),
            ),
            icon: CircleAvatar(
              radius: 16,
              backgroundColor: background,
              backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty)
                  ? NetworkImage(avatarUrl)
                  : null,
              child: (avatarUrl == null || avatarUrl.isEmpty)
                  ? Icon(
                      Icons.person_outline,
                      size: 18,
                      color: muted,
                    )
                  : null,
            ),
          ),
        ],
        bottom: TabBar(
          // The TabBar goes in the 'bottom' property of a standard AppBar
          controller: _tabController,
          labelColor: ink,
          unselectedLabelColor: muted,
          indicatorColor: accent,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Para ti'),
            Tab(icon: Icon(Icons.work_history), text: 'Mis Ofertas'),
            Tab(icon: Icon(Icons.event_available_outlined), text: 'Entrevistas'),
            Tab(icon: Icon(Icons.description_outlined), text: 'CV'),
            Tab(icon: Icon(Icons.mail_outline), text: 'Carta'),
            Tab(icon: Icon(Icons.videocam_outlined), text: 'VC'),
          ],
        ),
      ),
      body: BlocProvider(
        create: (context) => MyApplicationsCubit(
          applicationService: context.read<ApplicationService>(),
          candidateAuthCubit: context.read<CandidateAuthCubit>(),
        )..loadMyApplications(),
        child: TabBarView(
          controller: _tabController,
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
      floatingActionButton: authState.isAuthenticated
          ? FloatingActionButton(
              backgroundColor: ink,
              foregroundColor: Colors.white,
              onPressed: () => context.read<CandidateAuthCubit>().logout(),
              tooltip: 'Cerrar sesión',
              child: const Icon(Icons.logout),
            )
          : null,
    );
  }
}
