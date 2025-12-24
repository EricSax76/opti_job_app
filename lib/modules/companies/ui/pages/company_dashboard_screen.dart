import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:opti_job_app/modules/companies/cubits/company_auth_cubit.dart';
import 'package:opti_job_app/modules/job_offers/cubit/job_offer_form_cubit.dart';
import 'package:opti_job_app/modules/job_offers/models/job_offer_service.dart';
import 'package:opti_job_app/core/widgets/app_nav_bar.dart';
import 'package:opti_job_app/modules/job_offers/cubit/company_job_offers_cubit.dart';
import 'package:opti_job_app/modules/companies/ui/widgets/company_dashboard_widgets.dart';

class CompanyDashboardScreen extends StatefulWidget {
  const CompanyDashboardScreen({super.key});

  @override
  State<CompanyDashboardScreen> createState() => _CompanyDashboardScreenState();
}

class _CompanyDashboardScreenState extends State<CompanyDashboardScreen> {
  final _formKey = GlobalKey<FormState>();
  final _formControllers = OfferFormControllers();
  String? _loadedCompanyUid;

  @override
  void dispose() {
    _formControllers.dispose();
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
          _resetForm();
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
              ? const UnauthenticatedCompanyMessage()
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CompanyDashboardHeader(
                        companyName: authState.company!.name,
                      ),
                      const SizedBox(height: 24),
                      CreateOfferCard(
                        formKey: _formKey,
                        controllers: _formControllers,
                        onSubmit: () => _submit(context),
                      ),
                      const SizedBox(height: 24),
                      const CompanyOffersHeader(),
                      const SizedBox(height: 8),
                      const CompanyOffersSection(),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _formControllers.clear();
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
        title: _formControllers.title.text.trim(),
        description: _formControllers.description.text.trim(),
        location: _formControllers.location.text.trim(),
        companyId: company.id,
        companyUid: company.uid,
        jobType: _formControllers.jobType.text.trim().isEmpty
            ? null
            : _formControllers.jobType.text.trim(),
        salaryMin: _formControllers.salaryMin.text.trim().isEmpty
            ? null
            : _formControllers.salaryMin.text.trim(),
        salaryMax: _formControllers.salaryMax.text.trim().isEmpty
            ? null
            : _formControllers.salaryMax.text.trim(),
        education: _formControllers.education.text.trim().isEmpty
            ? null
            : _formControllers.education.text.trim(),
      ),
    );
  }
}
