import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:infojobs_flutter_app/providers/auth_providers.dart';
import 'package:infojobs_flutter_app/data/services/job_offer_service.dart';
import 'package:infojobs_flutter_app/features/shared/widgets/app_nav_bar.dart';

class CompanyDashboardScreen extends ConsumerStatefulWidget {
  const CompanyDashboardScreen({super.key});

  @override
  ConsumerState<CompanyDashboardScreen> createState() =>
      _CompanyDashboardScreenState();
}

class _CompanyDashboardScreenState
    extends ConsumerState<CompanyDashboardScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _salaryMinController = TextEditingController();
  final _salaryMaxController = TextEditingController();
  final _educationController = TextEditingController();
  final _jobTypeController = TextEditingController();

  bool _isSubmitting = false;
  String? _message;

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
    final auth = ref.watch(authControllerProvider);

    return Scaffold(
      appBar: const AppNavBar(),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: auth.company == null
            ? const Center(
                child:
                    Text('Inicia sesión como empresa para publicar ofertas.'),
              )
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bienvenida, ${auth.company!.name}',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Publica nuevas vacantes y gestiona tus ofertas fácilmente.',
                    ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerRight,
                      child: OutlinedButton.icon(
                        onPressed: auth.isLoading
                            ? null
                            : () => _handleLogout(context),
                        icon: const Icon(Icons.logout),
                        label: const Text('Cerrar sesión'),
                      ),
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
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
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
                              FilledButton(
                                onPressed: _isSubmitting
                                    ? null
                                    : () => _submit(context),
                                child: _isSubmitting
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                  Colors.white),
                                        ),
                                      )
                                    : const Text('Publicar oferta'),
                              ),
                              if (_message != null) ...[
                                const SizedBox(height: 12),
                                Text(
                                  _message!,
                                  style: TextStyle(
                                    color: _message!.startsWith('Error')
                                        ? Colors.red
                                        : Colors.green,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  void _handleLogout(BuildContext context) {
    ref.read(authControllerProvider).logout();
    if (!mounted) return;
    setState(() {
      _message = null;
    });
    context.go('/CompanyLogin');
  }

  Future<void> _submit(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _message = null;
    });

    final service = ref.read(jobOfferServiceProvider);

    try {
      await service.createJobOffer(
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
      setState(() {
        _message = 'Oferta publicada con éxito.';
      });
      _formKey.currentState!.reset();
      _titleController.clear();
      _descriptionController.clear();
      _locationController.clear();
      _jobTypeController.clear();
      _salaryMinController.clear();
      _salaryMaxController.clear();
      _educationController.clear();
    } catch (error, stackTrace) {
      debugPrint('Error al crear oferta: $error\n$stackTrace');
      setState(() {
        _message = 'Error al publicar la oferta. Intenta nuevamente.';
      });
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }
}
