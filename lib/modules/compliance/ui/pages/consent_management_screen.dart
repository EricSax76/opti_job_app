import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opti_job_app/modules/compliance/models/data_request.dart';
import 'package:opti_job_app/modules/compliance/repositories/compliance_repository.dart';
import 'package:opti_job_app/modules/compliance/ui/widgets/compliance_data_requests_tab.dart';
import 'package:opti_job_app/modules/compliance/ui/widgets/consent_records_tab.dart';
import 'package:opti_job_app/modules/compliance/ui/widgets/process_data_request_dialog.dart';
import 'package:opti_job_app/modules/compliance/ui/widgets/salary_benchmarks_tab.dart';
import 'package:opti_job_app/modules/companies/cubits/company_auth_cubit.dart';
import 'package:opti_job_app/modules/recruiters/cubits/recruiter_auth_cubit.dart';
import 'package:opti_job_app/modules/recruiters/models/recruiter_role.dart';

class ConsentManagementScreen extends StatefulWidget {
  const ConsentManagementScreen({super.key, required this.companyId});

  final String companyId;

  @override
  State<ConsentManagementScreen> createState() =>
      _ConsentManagementScreenState();
}

class _ConsentManagementScreenState extends State<ConsentManagementScreen> {
  final Set<String> _processingRequestIds = <String>{};
  static const Set<RecruiterRole> _salaryBenchmarkAllowedRoles = {
    RecruiterRole.admin,
    RecruiterRole.recruiter,
  };

  @override
  Widget build(BuildContext context) {
    final canManageSalaryBenchmarks = _canManageSalaryBenchmarks(context);
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Gestión de Cumplimiento (RGPD/AI Act)'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Consentimientos'),
              Tab(text: 'Solicitudes'),
              Tab(text: 'Benchmarks'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            ConsentRecordsTab(companyId: widget.companyId),
            ComplianceDataRequestsTab(
              companyId: widget.companyId,
              processingRequestIds: _processingRequestIds,
              onProcessRequest: _processRequest,
            ),
            SalaryBenchmarksTab(
              companyId: widget.companyId,
              canManage: canManageSalaryBenchmarks,
            ),
          ],
        ),
      ),
    );
  }

  bool _canManageSalaryBenchmarks(BuildContext context) {
    final routeCompanyId = widget.companyId.trim();
    final companyUid = context.read<CompanyAuthCubit>().state.company?.uid;
    if (companyUid != null && companyUid.trim() == routeCompanyId) {
      return true;
    }

    final recruiter = context.read<RecruiterAuthCubit>().state.recruiter;
    if (recruiter == null || !recruiter.isActive) {
      return false;
    }
    if (recruiter.companyId.trim() != routeCompanyId) {
      return false;
    }
    return _salaryBenchmarkAllowedRoles.contains(recruiter.role);
  }

  Future<void> _processRequest(DataRequest request) async {
    final decision = await showDialog<RequestDecision>(
      context: context,
      builder: (_) => ProcessDataRequestDialog(request: request),
    );

    if (decision == null || !mounted) return;

    setState(() => _processingRequestIds.add(request.id));
    try {
      await context.read<DataRequestRepository>().updateRequestStatus(
        request.id,
        decision.status,
        response: decision.response,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Solicitud actualizada correctamente.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo actualizar la solicitud: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _processingRequestIds.remove(request.id));
      }
    }
  }
}
