import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opti_job_app/modules/aplications/cubits/my_applications_cubit.dart';
import 'package:opti_job_app/modules/aplications/models/application_service.dart';
import 'package:opti_job_app/modules/candidates/cubits/candidate_auth_cubit.dart';

import 'package:opti_job_app/modules/candidates/ui/widgets/dashboard_view.dart';
import 'package:opti_job_app/modules/candidates/ui/widgets/my_applications_view.dart';
import 'package:opti_job_app/modules/profiles/ui/pages/profile_screen.dart';

class CandidateDashboardScreen extends StatefulWidget {
  const CandidateDashboardScreen({super.key});

  @override
  State<CandidateDashboardScreen> createState() =>
      _CandidateDashboardScreenState();
}

class _CandidateDashboardScreenState extends State<CandidateDashboardScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<CandidateAuthCubit>().state;
    const background = Color(0xFFF8FAFC);
    const ink = Color(0xFF0F172A);
    const muted = Color(0xFF64748B);
    const accent = Color(0xFF3FA7A0);
    const border = Color(0xFFE2E8F0);

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
        bottom: TabBar(
          // The TabBar goes in the 'bottom' property of a standard AppBar
          controller: _tabController,
          labelColor: ink,
          unselectedLabelColor: muted,
          indicatorColor: accent,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Para ti'),
            Tab(icon: Icon(Icons.work_history), text: 'Mis Ofertas'),
            Tab(icon: Icon(Icons.person_outline), text: 'Perfil'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          const DashboardView(),
          BlocProvider(
            create: (context) => MyApplicationsCubit(
              applicationService: context.read<ApplicationService>(),
              candidateAuthCubit: context.read<CandidateAuthCubit>(),
            )..loadMyApplications(),
            child: const MyApplicationsView(),
          ),
          const ProfileScreen(),
        ],
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
