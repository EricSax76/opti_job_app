import 'package:flutter/material.dart';

import 'package:opti_job_app/core/theme/ui_tokens.dart';
import 'package:opti_job_app/core/widgets/section_header.dart';
import 'package:opti_job_app/core/widgets/state_message.dart';
import 'package:opti_job_app/modules/job_offers/logic/job_offer_list_logic.dart';
import 'package:opti_job_app/modules/job_offers/models/job_offer_list_view_model.dart';
import 'package:opti_job_app/modules/job_offers/ui/widgets/job_offer_summary_card.dart';
import 'package:opti_job_app/modules/job_offers/ui/widgets/list/job_offer_type_filter.dart';

class JobOfferListContent extends StatelessWidget {
  const JobOfferListContent({
    super.key,
    required this.viewModel,
    required this.onSelectJobType,
    required this.onClearJobType,
    required this.onShowAllOffers,
    required this.onLoadMore,
    required this.onOpenOffer,
  });

  final JobOfferListViewModel viewModel;
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
                    availableJobTypes: viewModel.availableJobTypes,
                    selectedJobType: viewModel.selectedJobType,
                    onChanged: onSelectJobType,
                    onClear: onClearJobType,
                  ),
                ],
              ),
            ),
          ),
          if (viewModel.isRefreshing)
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
          if (viewModel.isEmpty)
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
                  final item = viewModel.items[index];

                  return Padding(
                    padding: const EdgeInsets.only(bottom: uiSpacing12),
                    child: JobOfferSummaryCard(
                      title: item.title,
                      company: item.companyName,
                      avatarUrl: item.avatarUrl,
                      salary: item.salary,
                      modality: item.modality,
                      onTap: () => onOpenOffer(item.offerId),
                    ),
                  );
                }, childCount: viewModel.items.length),
              ),
            ),
          if (viewModel.isLoadingMore)
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
    final shouldLoadMore = JobOfferListLogic.shouldLoadMore(
      notification: notification,
      isLoadingMore: viewModel.isLoadingMore,
      isRefreshing: viewModel.isRefreshing,
      hasMore: viewModel.hasMore,
    );
    if (shouldLoadMore) {
      onLoadMore();
    }
    return false;
  }
}
