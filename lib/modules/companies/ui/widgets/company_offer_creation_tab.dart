import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opti_job_app/core/widgets/state_message.dart';
import 'package:opti_job_app/modules/companies/cubits/company_auth_cubit.dart';
import 'package:opti_job_app/modules/companies/controllers/offer_form_controllers.dart';
import 'package:opti_job_app/modules/companies/cubits/company_offer_creation_cubit.dart';
import 'package:opti_job_app/modules/companies/logic/company_offer_creation_controller.dart';
import 'package:opti_job_app/modules/companies/logic/company_offer_creation_logic.dart';
import 'package:opti_job_app/modules/companies/ui/widgets/company_offer_creation_content.dart';
import 'package:opti_job_app/modules/job_offers/cubits/job_offer_form_cubit.dart';

class CompanyOfferCreationTab extends StatelessWidget {
  const CompanyOfferCreationTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const _CompanyOfferCreationView();
  }
}

class _CompanyOfferCreationView extends StatefulWidget {
  const _CompanyOfferCreationView();

  @override
  State<_CompanyOfferCreationView> createState() =>
      _CompanyOfferCreationViewState();
}

class _CompanyOfferCreationViewState extends State<_CompanyOfferCreationView> {
  final _formKey = GlobalKey<FormState>();
  final _formControllers = OfferFormControllers();

  @override
  void dispose() {
    _formControllers.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final company = context.watch<CompanyAuthCubit>().state.company;
    if (company == null) {
      return const StateMessage(
        title: 'Acceso requerido',
        message:
            'Inicia sesion como empresa para publicar ofertas y usar generacion con IA.',
      );
    }

    final isGeneratingOffer = context.select(
      (CompanyOfferCreationCubit cubit) => cubit.state.isGeneratingOffer,
    );
    final viewModel = CompanyOfferCreationLogic.buildViewModel(
      companyName: company.name,
      isGeneratingOffer: isGeneratingOffer,
    );

    return BlocListener<JobOfferFormCubit, JobOfferFormState>(
      listenWhen: CompanyOfferCreationLogic.shouldResetFormOnStatusChange,
      listener: (_, state) =>
          CompanyOfferCreationController.handleJobOfferFormStatus(
            state: state,
            formKey: _formKey,
            formControllers: _formControllers,
          ),
      child: CompanyOfferCreationContent(
        companyName: viewModel.companyName,
        formKey: _formKey,
        formControllers: _formControllers,
        isGeneratingOffer: viewModel.isGeneratingOffer,
        onSubmit: () => CompanyOfferCreationController.submit(
          context: context,
          formKey: _formKey,
          formControllers: _formControllers,
        ),
        onGenerateWithAi: () => CompanyOfferCreationController.generateWithAi(
          context: context,
          formControllers: _formControllers,
        ),
      ),
    );
  }
}
