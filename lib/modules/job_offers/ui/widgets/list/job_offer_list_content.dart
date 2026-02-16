import 'package:flutter/material.dart';

import 'package:opti_job_app/core/theme/ui_tokens.dart';
import 'package:opti_job_app/core/widgets/section_header.dart';
import 'package:opti_job_app/core/widgets/state_message.dart';
import 'package:opti_job_app/modules/companies/models/company.dart';
import 'package:opti_job_app/modules/job_offers/models/job_offer.dart';
import 'package:opti_job_app/modules/job_offers/models/job_offer_extensions.dart';
import 'package:opti_job_app/modules/job_offers/ui/widgets/job_offer_summary_card.dart';
import 'package:opti_job_app/modules/job_offers/ui/widgets/list/job_offer_type_filter.dart';

const double _paginationThreshold = 280;

class JobOfferListContent extends StatelessWidget {
  const JobOfferListContent({
    super.key,
    required this.offers,
    required this.companiesById,
    required this.availableJobTypes,
    required this.selectedJobType,
    required this.isRefreshing,
    required this.isLoadingMore,
    required this.hasMore,
    required this.onSelectJobType,
    required this.onClearJobType,
    required this.onShowAllOffers,
    required this.onLoadMore,
    required this.onOpenOffer,
  });

  final List<JobOffer> offers;
  final Map<int, Company> companiesById;
  final List<String> availableJobTypes;
  final String? selectedJobType;
  final bool isRefreshing;
  final bool isLoadingMore;
  final bool hasMore;
  final ValueChanged<String?> onSelectJobType;
  final VoidCallback onClearJobType;
  final VoidCallback onShowAllOffers;
  final VoidCallback onLoadMore;
  final ValueChanged<String> onOpenOffer;

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: _handleScroll,
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(uiSpacing16),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionHeader(
                    title: 'Ofertas activas',
                    subtitle: 'Encuentra tu próximo reto profesional.',
                  ),
                  const SizedBox(height: uiSpacing20),
                  JobOfferTypeFilter(
                    availableJobTypes: availableJobTypes,
                    selectedJobType: selectedJobType,
                    onChanged: onSelectJobType,
                    onClear: onClearJobType,
                  ),
                ],
              ),
            ),
          ),
          if (isRefreshing)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  uiSpacing16,
                  0,
                  uiSpacing16,
                  uiSpacing12,
                ),
                child: LinearProgressIndicator(minHeight: 2),
              ),
            ),
          if (offers.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: StateMessage(
                  title: 'Sin resultados',
                  message: 'No hay ofertas disponibles que coincidan.',
                  actionLabel: 'Ver todas',
                  onAction: onShowAllOffers,
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                uiSpacing16,
                0,
                uiSpacing16,
                uiSpacing24,
              ),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final offer = offers[index];
                  final company = offer.companyId == null
                      ? null
                      : companiesById[offer.companyId!];
                  final companyName =
                      offer.companyName ??
                      company?.name ??
                      'Empresa no especificada';
                  final avatarUrl =
                      offer.companyAvatarUrl ?? company?.avatarUrl;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: uiSpacing12),
                    child: JobOfferSummaryCard(
                      title: offer.title,
                      company: companyName,
                      avatarUrl: avatarUrl,
                      salary: offer.formattedSalary,
                      modality: offer.jobType,
                      onTap: () => onOpenOffer(offer.id),
                    ),
                  );
                }, childCount: offers.length),
              ),
            ),
          if (isLoadingMore)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.only(bottom: uiSpacing20),
                child: Center(
                  child: SizedBox.square(
                    dimension: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  bool _handleScroll(ScrollNotification notification) {
    if (notification.metrics.axis != Axis.vertical) return false;
    if (isLoadingMore || isRefreshing || !hasMore) return false;

    final pixels = notification.metrics.pixels;
    final max = notification.metrics.maxScrollExtent;
    if (max - pixels <= _paginationThreshold) {
      onLoadMore();
    }
    return false;
  }
}
