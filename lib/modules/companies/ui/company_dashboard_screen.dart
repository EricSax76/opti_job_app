import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:opti_job_app/data/services/job_offer_service.dart';
import 'package:opti_job_app/auth/cubit/company_auth_cubit.dart';
import 'package:opti_job_app/modules/job_offers/cubit/job_offer_form_cubit.dart';
import 'package:opti_job_app/core/shared/widgets/app_nav_bar.dart';

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
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  void _submit(BuildContext context) {
    if (!_formKey.currentState!.validate()) return;

    context.read<JobOfferFormCubit>().submit(
      JobOfferPayload(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        location: _locationController.text.trim(),
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
