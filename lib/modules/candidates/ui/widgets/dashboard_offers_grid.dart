import 'package:flutter/material.dart';
import 'package:opti_job_app/core/widgets/state_message.dart';
import 'package:opti_job_app/modules/candidates/ui/widgets/candidate_offer_card_base.dart';
import 'package:opti_job_app/modules/job_offers/models/job_offer.dart';
import 'package:opti_job_app/modules/job_offers/models/job_offer_extensions.dart';

class DashboardOffersGrid extends StatelessWidget {
  const DashboardOffersGrid({
    super.key,
    required this.status,
    required this.offers,
    required this.companiesById,
    required this.showTwoColumns,
    required this.isLoadingMore,
    required this.hasMore,
    required this.hasActiveFilters,
    this.errorMessage,
    required this.onRetry,
    required this.onClearFilters,
    required this.onLoadMore,
    required this.onOfferTap,
  });

  final String
  status; // Using String to avoid direct dependency on JobOffersStatus enum if possible, or just import it. Let's import it for type safety if it's the pattern. Actually, let's keep it pure.
  final List<JobOffer> offers;
  final Map<int, dynamic> companiesById; // Keys are int companyId
  final bool showTwoColumns;
  final bool isLoadingMore;
  final bool hasMore;
  final bool hasActiveFilters;
  final String? errorMessage;
  final VoidCallback onRetry;
  final VoidCallback onClearFilters;
  final VoidCallback onLoadMore;
  final ValueChanged<JobOffer> onOfferTap;

  static const double _paginationThreshold = 280;
  static const double _gridMainAxisExtent = 220;

  @override
  Widget build(BuildContext context) {
    // We'll use strings for status to keep it decoupled from the Cubit's enum if desired,
    // but typically we can import the enum if it's a domain model.
    // For now, let's assume the caller handles the status mapping or we use the strings.

    if (status == 'loading' || status == 'initial') {
      return const Center(child: CircularProgressIndicator());
    }

    if (status == 'failure') {
      return StateMessage(
        title: 'No se pudieron cargar las ofertas',
        message: errorMessage ?? 'Intenta nuevamente en unos segundos.',
        actionLabel: 'Reintentar',
        onAction: onRetry,
      );
    }

    if (offers.isEmpty) {
      return StateMessage(
        title: hasActiveFilters ? 'Sin resultados' : 'Sin ofertas disponibles',
        message: hasActiveFilters
            ? 'No se encontraron ofertas con los filtros aplicados.'
            : 'Aún no hay ofertas disponibles. Intenta más tarde.',
        actionLabel: hasActiveFilters ? 'Limpiar filtros' : 'Actualizar',
        onAction: hasActiveFilters ? onClearFilters : onRetry,
      );
    }

    if (showTwoColumns) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final crossAxisCount = constraints.maxWidth >= 900 ? 2 : 1;
          final grid = NotificationListener<ScrollNotification>(
            onNotification: (notification) => _handleScroll(notification),
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                mainAxisExtent: _gridMainAxisExtent,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: offers.length,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemBuilder: (context, index) =>
                  _buildOfferCard(context, offers[index], index, isGrid: true),
            ),
          );
          if (!isLoadingMore) return grid;
          return _LoadingMoreOverlay(child: grid);
        },
      );
    }

    final list = NotificationListener<ScrollNotification>(
      onNotification: (notification) => _handleScroll(notification),
      child: ListView.builder(
        itemCount: offers.length,
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: _buildOfferCard(
              context,
              offers[index],
              index,
              isGrid: false,
            ),
          );
        },
      ),
    );
    if (!isLoadingMore) return list;
    return _LoadingMoreOverlay(child: list);
  }

  Widget _buildOfferCard(
    BuildContext context,
    JobOffer offer,
    int index, {
    required bool isGrid,
  }) {
    final company = offer.companyId == null
        ? null
        : companiesById[offer.companyId!];

    // We can't easily avoid the company dynamic type here without a specific model,
    // but we can assume it has the name and avatarUrl properties or handle them.
    // In the original code, companiesById was Map<String, Company>.

    final companyName =
        (offer.companyName ??
            (company != null ? (company as dynamic).name : null)) ??
        'Empresa no especificada';
    final avatarUrl =
        offer.companyAvatarUrl ??
        (company != null ? (company as dynamic).avatarUrl : null);

    return CandidateOfferCardBase(
      title: offer.title,
      company: companyName,
      description: offer.description,
      avatarUrl: avatarUrl,
      salary: offer.formattedSalary,
      location: offer.location,
      modality: offer.jobType ?? 'Modalidad no especificada',
      tags: _extractTags(offer),
      heroTag: '${isGrid ? 'offers-grid' : 'offers-list'}-$index-${offer.id}',
      heroTagPrefix: 'job_offer_avatar',
      onTap: () => onOfferTap(offer),
    );
  }

  List<String>? _extractTags(JobOffer offer) {
    final tags = <String>[];
    if (offer.education != null && offer.education!.isNotEmpty) {
      tags.add(offer.education!);
    }
    if (offer.keyIndicators != null && offer.keyIndicators!.isNotEmpty) {
      final indicators = offer.keyIndicators!.split(',');
      tags.addAll(indicators.take(2).map((value) => value.trim()));
    }
    return tags.isEmpty ? null : tags;
  }

  bool _handleScroll(ScrollNotification notification) {
    if (notification.metrics.axis != Axis.vertical) return false;
    final distanceToBottom =
        notification.metrics.maxScrollExtent - notification.metrics.pixels;

    if (distanceToBottom <= _paginationThreshold && hasMore && !isLoadingMore) {
      onLoadMore();
    }
    return false;
  }
}

class _LoadingMoreOverlay extends StatelessWidget {
  const _LoadingMoreOverlay({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        const Positioned(
          left: 0,
          right: 0,
          bottom: 8,
          child: Center(
            child: SizedBox.square(
              dimension: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
      ],
    );
  }
}
