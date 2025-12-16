import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:opti_job_app/data/models/calendar_event.dart';
import 'package:opti_job_app/data/models/job_offer.dart';
import 'package:opti_job_app/data/services/application_service.dart';
import 'package:opti_job_app/modules/candidates/cubits/candidate_auth_cubit.dart';
import 'package:opti_job_app/features/calendar/cubit/calendar_cubit.dart';
import 'package:opti_job_app/modules/candidates/cubits/my_applications_cubit.dart';
import 'package:opti_job_app/modules/job_offers/cubit/job_offers_cubit.dart';
import 'package:opti_job_app/features/profiles/cubit/profile_cubit.dart';

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
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<CandidateAuthCubit>().state;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Opti-Job'),
        automaticallyImplyLeading: false,
        centerTitle: true,
        bottom: TabBar(
          // The TabBar goes in the 'bottom' property of a standard AppBar
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Para ti'),
            Tab(icon: Icon(Icons.work_history), text: 'Mis Ofertas'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          const _DashboardView(),
          BlocProvider(
            create: (context) => MyApplicationsCubit(
              applicationService: context.read<ApplicationService>(),
              candidateAuthCubit: context.read<CandidateAuthCubit>(),
            )..loadMyApplications(),
            child: const _MyApplicationsView(),
          ),
        ],
      ),
      floatingActionButton: authState.isAuthenticated
          ? FloatingActionButton(
              onPressed: () => context.read<CandidateAuthCubit>().logout(),
              tooltip: 'Cerrar sesión',
              child: const Icon(Icons.logout),
            )
          : null,
    );
  }
}

class _DashboardView extends StatelessWidget {
  const _DashboardView();

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<CandidateAuthCubit>().state;
    final profileState = context.watch<ProfileCubit>().state;
    final offersState = context.watch<JobOffersCubit>().state;
    final calendarState = context.watch<CalendarCubit>().state;

    final candidateName =
        profileState.candidate?.name ??
        authState.candidate?.name ??
        'Candidato';

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hola, $candidateName',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text('Aquí tienes ofertas seleccionadas para ti.'),
          const SizedBox(height: 16),
          Expanded(
            child: Column(
              children: [
                Expanded(child: _OffersList(state: offersState)),
                const SizedBox(height: 16),
                _CalendarPanel(state: calendarState),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MyApplicationsView extends StatelessWidget {
  const _MyApplicationsView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MyApplicationsCubit, MyApplicationsState>(
      builder: (context, state) {
        if (state.status == ApplicationsStatus.loading ||
            state.status == ApplicationsStatus.initial) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state.status == ApplicationsStatus.error) {
          return Center(
            child: Text(
              state.errorMessage ?? 'Error al cargar tus postulaciones.',
            ),
          );
        }

        if (state.applications.isEmpty) {
          return const Center(
            child: Text('Aún no te has postulado a ninguna oferta.'),
          );
        }

        return _ApplicationsList(offers: state.applications);
      },
    );
  }
}

class _ApplicationsList extends StatelessWidget {
  const _ApplicationsList({required this.offers});

  final List<JobOffer> offers;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: offers.length,
      itemBuilder: (context, index) {
        final offer = offers[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ListTile(
            title: Text(offer.title),
            subtitle: Text(offer.description),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => context.go('/job-offer/${offer.id}'),
          ),
        );
      },
    );
  }
}

class _OffersList extends StatelessWidget {
  const _OffersList({required this.state});

  final JobOffersState state;

  @override
  Widget build(BuildContext context) {
    if (state.status == JobOffersStatus.loading ||
        state.status == JobOffersStatus.initial) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.status == JobOffersStatus.failure) {
      return Center(
        child: Text(state.errorMessage ?? 'Error al cargar las ofertas.'),
      );
    }

    if (state.offers.isEmpty) {
      return const Center(
        child: Text('Aún no hay ofertas disponibles. Intenta más tarde.'),
      );
    }

    return ListView.builder(
      itemCount: state.offers.length,
      itemBuilder: (context, index) {
        final offer = state.offers[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: ListTile(
            title: Text(offer.title),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(offer.description),
                const SizedBox(height: 4),
                Text(
                  offer.location,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            trailing: const Icon(Icons.open_in_new),
            onTap: () => context.go('/job-offer/${offer.id}'),
          ),
        );
      },
    );
  }
}

class _CalendarPanel extends StatelessWidget {
  const _CalendarPanel({required this.state});

  final CalendarState state;

  @override
  Widget build(BuildContext context) {
    final events = state.events[_normalize(state.selectedDay)] ?? const [];
    final calendarState = context.watch<CalendarCubit>().state;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recordatorios (${events.length})',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    final date = calendarState.selectedDay;
                    context.read<CalendarCubit>().addEvent(
                      date: date,
                      title: 'Seguimiento de oferta',
                      description:
                          'Revisa el estado de tus postulaciones en ${date.day}/${date.month}',
                      ownerType: 'candidate',
                    );
                  },
                ),
              ],
            ),
            if (calendarState.status == CalendarStatus.loading)
              const LinearProgressIndicator(),
            if (events.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 8.0),
                child: Text('No tienes recordatorios para este día.'),
              )
            else
              ...events.map((event) => _CalendarEventTile(event: event)),
          ],
        ),
      ),
    );
  }

  DateTime _normalize(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }
}

class _CalendarEventTile extends StatelessWidget {
  const _CalendarEventTile({required this.event});

  final CalendarEvent event;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(event.title),
      subtitle: event.description != null ? Text(event.description!) : null,
      trailing: IconButton(
        icon: const Icon(Icons.close),
        tooltip: 'Eliminar',
        onPressed: () => context.read<CalendarCubit>().removeEvent(event.id),
      ),
    );
  }
}
