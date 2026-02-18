import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opti_job_app/core/shell/core_shell.dart';
import 'package:opti_job_app/core/shell/core_shell_breakpoints.dart';
import 'package:opti_job_app/core/platform/web_history.dart';
import 'package:opti_job_app/auth/ui/pages/unauthenticated_company_message.dart';
import 'package:opti_job_app/modules/companies/cubits/company_auth_cubit.dart';
import 'package:opti_job_app/modules/companies/cubits/company_auth_state.dart';
import 'package:opti_job_app/modules/companies/cubits/company_dashboard_cubit.dart';
import 'package:opti_job_app/modules/companies/cubits/company_dashboard_state.dart';
import 'package:opti_job_app/modules/companies/models/company_dashboard_navigation.dart';
import 'package:opti_job_app/modules/companies/ui/widgets/company_account_avatar_menu.dart';
import 'package:opti_job_app/modules/companies/ui/widgets/dashboard/company_dashboard_app_bar.dart';
import 'package:opti_job_app/modules/companies/ui/widgets/dashboard/company_dashboard_authenticated_body.dart';
import 'package:opti_job_app/modules/companies/ui/widgets/dashboard/company_dashboard_drawer.dart';
import 'package:opti_job_app/modules/companies/ui/widgets/dashboard/company_dashboard_sidebar.dart';
import 'package:opti_job_app/modules/companies/ui/widgets/dashboard/company_dashboard_tab_pages.dart';
import 'package:opti_job_app/modules/job_offers/cubits/company_job_offers_cubit.dart';
import 'package:opti_job_app/modules/job_offers/cubits/job_offer_form_cubit.dart';
import 'package:opti_job_app/modules/companies/cubits/company_offer_creation_cubit.dart';
import 'package:opti_job_app/modules/interviews/cubits/interview_list_cubit.dart';

class CompanyDashboardScreen extends StatefulWidget {
  const CompanyDashboardScreen({
    super.key,
    required this.dashboardCubit,
    required this.offerCreationCubit,
    required this.interviewsCubit,
  });

  final CompanyDashboardCubit dashboardCubit;
  final CompanyOfferCreationCubit offerCreationCubit;
  final InterviewListCubit interviewsCubit;

  @override
  State<CompanyDashboardScreen> createState() => _CompanyDashboardScreenState();
}

class _CompanyDashboardScreenState extends State<CompanyDashboardScreen> {
  var _initialOffersLoadHandled = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialOffersLoadHandled) return;
    _initialOffersLoadHandled = true;
    final companyUid = context.read<CompanyAuthCubit>().state.company?.uid;
    widget.dashboardCubit.checkAndLoadCompanyOffers(companyUid);
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<CompanyAuthCubit>().state;
    final dashboardState = context.watch<CompanyDashboardCubit>().state;
    final theme = Theme.of(context);
    final showNavigationSidebar =
        MediaQuery.sizeOf(context).width >= coreShellNavigationBreakpoint;
    final navItems = companyDashboardNavItems();
    final tabPages = companyDashboardTabPages();
    final selectedIndex = companyDashboardClampIndex(dashboardState.selectedIndex);
    final hasAuthenticatedCompany = authState.company != null;

    if (selectedIndex != dashboardState.selectedIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        widget.dashboardCubit.selectIndex(selectedIndex);
      });
    }

    return MultiBlocListener(
      listeners: [
        BlocListener<JobOfferFormCubit, JobOfferFormState>(
          listenWhen: (previous, current) => previous.status != current.status,
          listener: _handleJobOfferFormStatus,
        ),
        BlocListener<CompanyAuthCubit, CompanyAuthState>(
          listener: (context, state) {
            widget.dashboardCubit.checkAndLoadCompanyOffers(state.company?.uid);
          },
        ),
        BlocListener<CompanyDashboardCubit, CompanyDashboardState>(
          listenWhen: (previous, current) =>
              previous.redirectPath != current.redirectPath,
          listener: (context, state) {
            if (!kIsWeb || state.redirectPath == null) return;
            pushBrowserPath(state.redirectPath!);
          },
        ),
      ],
      child: CoreShell(
        variant: CoreShellVariant.company,
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: CompanyDashboardAppBar(
          showAccountActions: hasAuthenticatedCompany,
          showMenuButton: !showNavigationSidebar && hasAuthenticatedCompany,
          accountMenu: const CompanyAccountAvatarMenu(),
        ),
        drawer: hasAuthenticatedCompany && !showNavigationSidebar
            ? CompanyDashboardDrawer(
                items: navItems,
                selectedIndex: selectedIndex,
                onSelected: (index) {
                  Navigator.of(context).pop();
                  widget.dashboardCubit.selectIndex(index);
                },
              )
            : null,
        sidebar: hasAuthenticatedCompany && showNavigationSidebar
            ? CompanyDashboardSidebar(
                items: navItems,
                selectedIndex: selectedIndex,
                onSelected: widget.dashboardCubit.selectIndex,
              )
            : null,
        sidebarAlignment: CoreShellSidebarAlignment.start,
        body: !hasAuthenticatedCompany
            ? const UnauthenticatedCompanyMessage()
            : CompanyDashboardAuthenticatedBody(
                selectedIndex: selectedIndex,
                tabPages: tabPages,
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

      final companyUid = widget.dashboardCubit.state.loadedCompanyUid;
      if (companyUid != null) {
        context.read<CompanyJobOffersCubit>().start(companyUid);
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
