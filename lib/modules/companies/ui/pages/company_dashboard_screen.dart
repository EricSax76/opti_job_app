import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:opti_job_app/core/theme/theme_cubit.dart';
import 'package:opti_job_app/core/theme/theme_state.dart';
import 'package:opti_job_app/auth/ui/pages/unauthenticated_company_message.dart';
import 'package:opti_job_app/modules/companies/cubits/company_auth_cubit.dart';
import 'package:opti_job_app/modules/companies/ui/widgets/company_candidates_tab.dart';
import 'package:opti_job_app/modules/companies/ui/pages/company_home_dashboard.dart';
import 'package:opti_job_app/modules/companies/ui/widgets/company_offer_creation_tab.dart';
import 'package:opti_job_app/modules/companies/ui/widgets/offers/company_offers_tab.dart';
import 'package:opti_job_app/modules/companies/ui/widgets/company_account_avatar_menu.dart';
import 'package:opti_job_app/modules/companies/ui/widgets/company_dashboard_nav_bar.dart';
import 'package:opti_job_app/modules/job_offers/cubits/company_job_offers_cubit.dart';
import 'package:opti_job_app/modules/job_offers/cubits/job_offer_form_cubit.dart';

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
    _tabController = TabController(length: 4, vsync: this);
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
    final theme = Theme.of(context);

    return BlocListener<JobOfferFormCubit, JobOfferFormState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        if (state.status == JobOfferFormStatus.success) {
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
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: const Text(
            'OPTIJOB',
            style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 2),
          ),
          automaticallyImplyLeading: false,
          centerTitle: true,
          actions: authState.company != null
              ? [
                  BlocBuilder<ThemeCubit, ThemeState>(
                    builder: (context, themeState) {
                      final isDark = themeState.themeMode == ThemeMode.dark;
                      return IconButton(
                        icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
                        tooltip: isDark ? 'Modo claro' : 'Modo oscuro',
                        onPressed: () =>
                            context.read<ThemeCubit>().toggleTheme(),
                      );
                    },
                  ),
                  const CompanyAccountAvatarMenu(),
                ]
              : null,
        ),
        body: authState.company == null
            ? const UnauthenticatedCompanyMessage()
            : Column(
                children: [
                  CompanyDashboardNavBar(controller: _tabController),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: const [
                        CompanyHomeDashboard(),
                        CompanyOfferCreationTab(),
                        CompanyOffersTab(),
                        CompanyCandidatesTab(),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
