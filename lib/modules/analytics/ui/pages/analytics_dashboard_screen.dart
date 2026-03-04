import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:opti_job_app/core/theme/ui_tokens.dart';
import 'package:opti_job_app/core/widgets/section_header.dart';
import 'package:opti_job_app/core/widgets/state_message.dart';
import 'package:opti_job_app/modules/analytics/cubits/analytics_dashboard_cubit.dart';
import 'package:opti_job_app/modules/analytics/models/kpi_metric.dart';
import 'package:opti_job_app/modules/analytics/ui/widgets/inp_performance_card.dart';
import 'package:opti_job_app/modules/analytics/ui/widgets/kpi_summary_card.dart';
import 'package:opti_job_app/modules/analytics/ui/widgets/pipeline_funnel_chart.dart';
import 'package:opti_job_app/modules/analytics/ui/widgets/recruiter_performance_table.dart';
import 'package:opti_job_app/modules/analytics/ui/widgets/source_effectiveness_chart.dart';
import 'package:opti_job_app/modules/analytics/ui/widgets/time_to_hire_chart.dart';

class AnalyticsDashboardScreen extends StatefulWidget {
  const AnalyticsDashboardScreen({super.key, required this.companyId});

  final String companyId;

  @override
  State<AnalyticsDashboardScreen> createState() =>
      _AnalyticsDashboardScreenState();
}

class _AnalyticsDashboardScreenState extends State<AnalyticsDashboardScreen> {
  @override
  void initState() {
    super.initState();
    context.read<AnalyticsDashboardCubit>().loadDashboard(widget.companyId);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard de Analytics'),
        actions: [
          BlocBuilder<AnalyticsDashboardCubit, AnalyticsDashboardState>(
            builder: (context, state) {
              if (state.history.isEmpty) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: DropdownButton<String>(
                  value: state.selectedAnalytics?.period,
                  underline: const SizedBox.shrink(),
                  onChanged: (period) {
                    if (period != null) {
                      final selected = state.history.firstWhere(
                        (a) => a.period == period,
                      );
                      context.read<AnalyticsDashboardCubit>().selectPeriod(
                        selected,
                      );
                    }
                  },
                  items: state.history.map((a) {
                    return DropdownMenuItem(
                      value: a.period,
                      child: Text(a.period, style: theme.textTheme.bodyMedium),
                    );
                  }).toList(),
                ),
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<AnalyticsDashboardCubit, AnalyticsDashboardState>(
        builder: (context, state) {
          if (state.status == AnalyticsDashboardStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.status == AnalyticsDashboardStatus.empty ||
              state.selectedAnalytics == null) {
            return const StateMessage(
              title: 'Sin analytics',
              message: 'No hay datos de analytics disponibles para mostrar.',
            );
          }

          final metrics = state.selectedAnalytics!.metrics;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(uiSpacing16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeader(
                  title: 'Dashboard de Analytics',
                  subtitle: 'KPIs, embudo y desempeño del equipo',
                  titleFontSize: 24,
                ),
                if (state.performanceDashboard != null) ...[
                  const SizedBox(height: uiSpacing16),
                  InpPerformanceCard(dashboard: state.performanceDashboard!),
                ],
                const SizedBox(height: uiSpacing20),
                _buildKpiGrid(metrics),
                const SizedBox(height: uiSpacing24),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: PipelineFunnelChart(
                        data: metrics['pipelineConversionRates'] ?? {},
                      ),
                    ),
                    const SizedBox(width: uiSpacing16),
                    Expanded(
                      flex: 2,
                      child: Column(
                        children: [
                          TimeToHireChart(
                            avgTimeToHire:
                                (metrics['averageTimeToHire'] as num?)
                                    ?.toDouble() ??
                                0.0,
                          ),
                          const SizedBox(height: uiSpacing16),
                          SourceEffectivenessChart(
                            data: metrics['sourceEffectiveness'] ?? {},
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: uiSpacing24),
                RecruiterPerformanceTable(
                  data: metrics['recruiterMetrics'] ?? {},
                ),
                const SizedBox(height: uiSpacing32),
                Center(
                  child: Text(
                    'Última actualización: ${state.selectedAnalytics!.updatedAt != null ? DateFormat('d MMM yyyy, HH:mm').format(state.selectedAnalytics!.updatedAt!) : 'Recién calculado'}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildKpiGrid(Map<String, dynamic> metrics) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth >= 1100
            ? 3
            : constraints.maxWidth >= 700
            ? 2
            : 1;

        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: uiSpacing16,
          mainAxisSpacing: uiSpacing16,
          childAspectRatio: 2.5,
          children: [
            KpiSummaryCard(
              metric: KpiMetric(
                label: 'Ofertas Publicadas',
                value: (metrics['offersPublished'] as num?)?.toDouble() ?? 0.0,
                unit: '',
              ),
            ),
            KpiSummaryCard(
              metric: KpiMetric(
                label: 'Candidaturas Recibidas',
                value:
                    (metrics['applicationsReceived'] as num?)?.toDouble() ??
                    0.0,
                unit: '',
              ),
            ),
            KpiSummaryCard(
              metric: KpiMetric(
                label: 'Tasa de Completitud',
                value:
                    ((metrics['applicationCompletionRate'] as num?)
                            ?.toDouble() ??
                        0.0) *
                    100,
                unit: '%',
              ),
            ),
            KpiSummaryCard(
              metric: KpiMetric(
                label: 'Inversión Canales',
                value:
                    (metrics['totalMultipostingSpendEur'] as num?)
                        ?.toDouble() ??
                    0.0,
                unit: '€',
              ),
            ),
            KpiSummaryCard(
              metric: KpiMetric(
                label: 'ROI Canales',
                value:
                    ((metrics['overallChannelRoi'] as num?)?.toDouble() ?? 0) *
                    100,
                unit: '%',
              ),
            ),
          ],
        );
      },
    );
  }
}
