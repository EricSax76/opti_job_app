import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:opti_job_app/core/theme/theme_cubit.dart';
import 'package:opti_job_app/auth/ui/pages/unauthenticated_company_message.dart';
import 'package:opti_job_app/modules/companies/cubits/company_auth_cubit.dart';
import 'package:opti_job_app/modules/companies/ui/widgets/company_account_avatar_menu.dart';
import 'package:opti_job_app/modules/companies/ui/widgets/dashboard/company_dashboard_app_bar.dart';
import 'package:opti_job_app/modules/companies/ui/widgets/dashboard/company_dashboard_authenticated_body.dart';
import 'package:opti_job_app/modules/companies/ui/widgets/dashboard/company_dashboard_tab_pages.dart';
import 'package:opti_job_app/modules/job_offers/cubits/company_job_offers_cubit.dart';
import 'package:opti_job_app/modules/job_offers/cubits/job_offer_form_cubit.dart';
import 'package:opti_job_app/core/config/feature_flags.dart';

class CompanyDashboardScreen extends StatefulWidget {
  const CompanyDashboardScreen({super.key});

  @override
  State<CompanyDashboardScreen> createState() => _CompanyDashboardScreenState();
}

class _CompanyDashboardScreenState extends State<CompanyDashboardScreen>
    with SingleTickerProviderStateMixin {
  String? _loadedCompanyUid;
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    final tabCount = FeatureFlags.interviews ? 5 : 4;
    _tabController = TabController(length: tabCount, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
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
    final isDarkMode = context.select(
      (ThemeCubit cubit) => cubit.state.themeMode == ThemeMode.dark,
    );
    final theme = Theme.of(context);

    return BlocListener<JobOfferFormCubit, JobOfferFormState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: _handleJobOfferFormStatus,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: CompanyDashboardAppBar(
          showAccountActions: authState.company != null,
          isDarkMode: isDarkMode,
          onToggleTheme: () => context.read<ThemeCubit>().toggleTheme(),
          accountMenu: const CompanyAccountAvatarMenu(),
        ),
        body: authState.company == null
            ? const UnauthenticatedCompanyMessage()
            : CompanyDashboardAuthenticatedBody(
                tabController: _tabController,
                tabPages: companyDashboardTabPages(),
              ),
      ),
    );
  }

  void _handleJobOfferFormStatus(
    BuildContext context,
    JobOfferFormState state,
  ) {
    if (state.status == JobOfferFormStatus.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Oferta publicada con éxito.')),
      );
      final companyUid = _loadedCompanyUid;
      if (companyUid != null) {
        context.read<CompanyJobOffersCubit>().loadCompanyOffers(companyUid);
      }
      return;
    }

    if (state.status == JobOfferFormStatus.failure) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al publicar la oferta. Intenta nuevamente.'),
        ),
      );
    }
  }
}
