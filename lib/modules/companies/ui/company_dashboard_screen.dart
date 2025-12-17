import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:opti_job_app/modules/companies/cubits/company_auth_cubit.dart';
import 'package:opti_job_app/modules/job_offers/cubit/job_offer_form_cubit.dart';
import 'package:opti_job_app/modules/job_offers/models/job_offer_service.dart';
import 'package:opti_job_app/core/widgets/app_nav_bar.dart';
import 'package:opti_job_app/modules/job_offers/cubit/company_job_offers_cubit.dart';
import 'package:opti_job_app/modules/job_offers/models/job_offer.dart';
import 'package:opti_job_app/modules/aplications/cubits/offer_applicants_cubit.dart';
import 'package:opti_job_app/modules/aplications/models/application.dart';

class CompanyDashboardScreen extends StatefulWidget {
  const CompanyDashboardScreen({super.key});

  @override
  State<CompanyDashboardScreen> createState() => _CompanyDashboardScreenState();
}

class _CompanyDashboardScreenState extends State<CompanyDashboardScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _salaryMinController = TextEditingController();
  final _salaryMaxController = TextEditingController();
  final _educationController = TextEditingController();
  final _jobTypeController = TextEditingController();
  String? _loadedCompanyUid;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _salaryMinController.dispose();
    _salaryMaxController.dispose();
    _educationController.dispose();
    _jobTypeController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final companyUid = context.read<CompanyAuthCubit>().state.company?.uid;
    if (companyUid != null && companyUid != _loadedCompanyUid) {
      _loadedCompanyUid = companyUid;
      context.read<CompanyJobOffersCubit>().loadCompanyOffers(companyUid);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<CompanyAuthCubit>().state;

    return BlocListener<JobOfferFormCubit, JobOfferFormState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        if (state.status == JobOfferFormStatus.success) {
          _formKey.currentState?.reset();
          _titleController.clear();
          _descriptionController.clear();
          _locationController.clear();
          _jobTypeController.clear();
          _salaryMinController.clear();
          _salaryMaxController.clear();
          _educationController.clear();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Oferta publicada con éxito.')),
          );
          final companyUid = _loadedCompanyUid;
          if (companyUid != null) {
            context.read<CompanyJobOffersCubit>().loadCompanyOffers(companyUid);
          }
        } else if (state.status == JobOfferFormStatus.failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error al publicar la oferta. Intenta nuevamente.'),
            ),
          );
        }
      },
      child: Scaffold(
        appBar: const AppNavBar(),
        floatingActionButton: authState.isAuthenticated
            ? FloatingActionButton.extended(
                onPressed: () => context.read<CompanyAuthCubit>().logout(),
                icon: const Icon(Icons.logout),
                label: const Text('Cerrar sesión'),
              )
            : null,
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: authState.company == null
              ? const Center(
                  child: Text(
                    'Inicia sesión como empresa para publicar ofertas.',
                  ),
                )
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bienvenida, ${authState.company!.name}',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Publica nuevas vacantes y gestiona tus ofertas fácilmente.',
                      ),
                      const SizedBox(height: 24),
                      Card(
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Crear nueva oferta',
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _titleController,
                                  decoration: const InputDecoration(
                                    labelText: 'Título',
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'El título es obligatorio';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _descriptionController,
                                  maxLines: 4,
                                  decoration: const InputDecoration(
                                    labelText: 'Descripción',
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'La descripción es obligatoria';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _locationController,
                                  decoration: const InputDecoration(
                                    labelText: 'Ubicación',
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'La ubicación es obligatoria';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _jobTypeController,
                                  decoration: const InputDecoration(
                                    labelText: 'Tipología',
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        controller: _salaryMinController,
                                        decoration: const InputDecoration(
                                          labelText: 'Salario mínimo',
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: TextFormField(
                                        controller: _salaryMaxController,
                                        decoration: const InputDecoration(
                                          labelText: 'Salario máximo',
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _educationController,
                                  decoration: const InputDecoration(
                                    labelText: 'Educación requerida',
                                  ),
                                ),
                                const SizedBox(height: 24),
                                BlocBuilder<
                                  JobOfferFormCubit,
                                  JobOfferFormState
                                >(
                                  builder: (context, state) {
                                    final isSubmitting =
                                        state.status ==
                                        JobOfferFormStatus.submitting;
                                    return FilledButton(
                                      onPressed: isSubmitting
                                          ? null
                                          : () => _submit(context),
                                      child: isSubmitting
                                          ? const SizedBox(
                                              width: 16,
                                              height: 16,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                      Color
                                                    >(Colors.white),
                                              ),
                                            )
                                          : const Text('Publicar oferta'),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Mis ofertas publicadas',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const _CompanyOffersSection(),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  void _submit(BuildContext context) {
    if (!_formKey.currentState!.validate()) return;

    final company = context.read<CompanyAuthCubit>().state.company;
    if (company == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes iniciar sesión como empresa para publicar.'),
        ),
      );
      return;
    }

    context.read<JobOfferFormCubit>().submit(
      JobOfferPayload(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        location: _locationController.text.trim(),
        companyId: company.id,
        companyUid: company.uid,
        jobType: _jobTypeController.text.trim().isEmpty
            ? null
            : _jobTypeController.text.trim(),
        salaryMin: _salaryMinController.text.trim().isEmpty
            ? null
            : _salaryMinController.text.trim(),
        salaryMax: _salaryMaxController.text.trim().isEmpty
            ? null
            : _salaryMaxController.text.trim(),
        education: _educationController.text.trim().isEmpty
            ? null
            : _educationController.text.trim(),
      ),
    );
  }
}

class _CompanyOffersSection extends StatelessWidget {
  const _CompanyOffersSection();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CompanyJobOffersCubit, CompanyJobOffersState>(
      builder: (context, state) {
        if (state.status == CompanyJobOffersStatus.loading ||
            state.status == CompanyJobOffersStatus.initial) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (state.status == CompanyJobOffersStatus.failure) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              state.errorMessage ??
                  'No se pudieron cargar tus ofertas. Intenta refrescar.',
            ),
          );
        }

        if (state.offers.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Aún no has publicado ofertas. Crea la primera para comenzar a recibir postulaciones.',
            ),
          );
        }

        return Column(
          children: [
            for (final offer in state.offers)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: _OfferCard(offer: offer),
              ),
          ],
        );
      },
    );
  }
}

class _OfferCard extends StatelessWidget {
  const _OfferCard({required this.offer});

  final JobOffer offer;

  @override
  Widget build(BuildContext context) {
    final resolvedCompanyUid = _companyUid(context);
    return Card(
      elevation: 1,
      child: ExpansionTile(
        title: Text(offer.title),
        subtitle: Text(
          '${offer.location} • ${offer.jobType ?? 'Tipología no especificada'}',
        ),
        leading: const Icon(Icons.work_outline),
        childrenPadding: const EdgeInsets.symmetric(horizontal: 16),
        onExpansionChanged: (expanded) {
          if (expanded) {
            final applicantsCubit = context.read<OfferApplicantsCubit>();
            final currentStatus =
                applicantsCubit.state.statuses[offer.id] ??
                OfferApplicantsStatus.initial;
            if (currentStatus == OfferApplicantsStatus.initial ||
                currentStatus == OfferApplicantsStatus.failure) {
              final companyUid = _companyUid(context);
              if (companyUid == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content:
                        Text('No se pudo determinar el usuario de empresa.'),
                  ),
                );
                return;
              }
              applicantsCubit.loadApplicants(
                offerId: offer.id,
                companyUid: companyUid,
              );
            }
          }
        },
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _OfferApplicantsSection(
              offer: offer,
              companyUid: resolvedCompanyUid,
            ),
          ),
        ],
      ),
    );
  }

  String? _companyUid(BuildContext context) {
    return offer.companyUid ??
        context.read<CompanyAuthCubit>().state.company?.uid;
  }
}

class _OfferApplicantsSection extends StatelessWidget {
  const _OfferApplicantsSection({
    required this.offer,
    required this.companyUid,
  });

  final JobOffer offer;
  final String? companyUid;

  @override
  Widget build(BuildContext context) {
    if (companyUid == null) {
      return const Text(
        'No se pudieron cargar los aplicantes porque falta el identificador de empresa.',
      );
    }
    return BlocBuilder<OfferApplicantsCubit, OfferApplicantsState>(
      buildWhen: (previous, current) {
        final prevStatus =
            previous.statuses[offer.id] ?? OfferApplicantsStatus.initial;
        final currentStatus =
            current.statuses[offer.id] ?? OfferApplicantsStatus.initial;
        final prevApplicants = previous.applicants[offer.id];
        final currentApplicants = current.applicants[offer.id];
        final prevError = previous.errors[offer.id];
        final currentError = current.errors[offer.id];
        return prevStatus != currentStatus ||
            prevApplicants != currentApplicants ||
            prevError != currentError;
      },
      builder: (context, state) {
        final status =
            state.statuses[offer.id] ?? OfferApplicantsStatus.initial;
        final applicants = state.applicants[offer.id] ?? const <Application>[];
        final error = state.errors[offer.id];

        switch (status) {
          case OfferApplicantsStatus.initial:
            return const Text(
              'Expande la tarjeta para cargar los aplicantes de esta oferta.',
            );
          case OfferApplicantsStatus.loading:
            return const Padding(
              padding: EdgeInsets.all(8),
              child: Center(child: CircularProgressIndicator()),
            );
          case OfferApplicantsStatus.failure:
            return Text(error ?? 'No se pudieron cargar los aplicantes.');
          case OfferApplicantsStatus.success:
            if (applicants.isEmpty) {
              return const Text('Aún no hay postulaciones para esta oferta.');
            }
            return Column(
              children: [
                for (final application in applicants)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: _ApplicantTile(
                      offerId: offer.id,
                      application: application,
                      companyUid: companyUid!,
                    ),
                  ),
              ],
            );
        }
      },
    );
  }
}

class _ApplicantTile extends StatelessWidget {
  const _ApplicantTile({
    required this.application,
    required this.offerId,
    required this.companyUid,
  });

  final Application application;
  final int offerId;
  final String companyUid;

  @override
  Widget build(BuildContext context) {
    final subtitleParts = <String>[];
    if (application.candidateEmail != null &&
        application.candidateEmail!.isNotEmpty) {
      subtitleParts.add(application.candidateEmail!);
    }
    subtitleParts.add('Estado: ${_statusLabel(application.status)}');

    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(child: Text(_initials(application))),
      title: Text(
        application.candidateName ??
            application.candidateEmail ??
            application.candidateUid,
      ),
      subtitle: Text(subtitleParts.join(' • ')),
      trailing: application.id == null
          ? null
          : PopupMenuButton<String>(
              tooltip: 'Actualizar estado',
              onSelected: (value) {
                context.read<OfferApplicantsCubit>().updateApplicationStatus(
                  offerId: offerId,
                  applicationId: application.id!,
                  newStatus: value,
                  companyUid: companyUid,
                );
              },
              itemBuilder: (context) {
                return _applicationStatuses.map((status) {
                  final isSelected = status == application.status;
                  return PopupMenuItem<String>(
                    value: status,
                    child: Row(
                      children: [
                        if (isSelected)
                          const Icon(Icons.check, size: 16)
                        else
                          const SizedBox(width: 16),
                        Text(_statusLabel(status)),
                      ],
                    ),
                  );
                }).toList();
              },
              child: Chip(label: Text(_statusLabel(application.status))),
            ),
    );
  }
}

const _applicationStatuses = [
  'pending',
  'reviewing',
  'interview',
  'accepted',
  'rejected',
];

String _statusLabel(String status) {
  switch (status) {
    case 'pending':
      return 'Pendiente';
    case 'reviewing':
      return 'En revisión';
    case 'interview':
      return 'Entrevista';
    case 'accepted':
      return 'Aceptado';
    case 'rejected':
      return 'Rechazado';
    default:
      return status;
  }
}

String _initials(Application application) {
  final raw =
      (application.candidateName?.trim().isNotEmpty == true
              ? application.candidateName!
              : application.candidateEmail?.trim().isNotEmpty == true
              ? application.candidateEmail!
              : application.candidateUid)
          .trim();
  if (raw.isEmpty) {
    return '?';
  }
  return raw.substring(0, 1).toUpperCase();
}
