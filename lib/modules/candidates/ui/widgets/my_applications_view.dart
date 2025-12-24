import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:opti_job_app/modules/aplications/cubits/my_applications_cubit.dart';
import 'package:opti_job_app/modules/job_offers/models/job_offer.dart';

class MyApplicationsView extends StatelessWidget {
  const MyApplicationsView({super.key});

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
