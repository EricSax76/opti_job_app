import 'dart:async';

import 'package:flutter/material.dart';
import 'package:opti_job_app/core/theme/ui_tokens.dart';
import 'package:opti_job_app/modules/candidates/cubits/job_offer_filter_cubit.dart';
import 'package:opti_job_app/modules/candidates/models/job_offer_filters.dart';
import 'package:opti_job_app/modules/candidates/ui/controllers/job_offer_location_catalog_controller.dart';
import 'package:opti_job_app/modules/candidates/ui/widgets/filters/job_offer_filter_field_decorators.dart';
import 'package:opti_job_app/modules/candidates/ui/widgets/filters/job_offer_filter_sidebar_field_widgets.dart';
import 'package:opti_job_app/modules/candidates/ui/widgets/filters/job_offer_filter_sidebar_models.dart';
import 'package:opti_job_app/modules/candidates/ui/widgets/filters/job_offer_filter_sidebar_shell_widgets.dart';
import 'package:opti_job_app/modules/candidates/ui/widgets/filters/job_offer_filter_sidebar_tokens.dart';

class JobOfferFilterLocationSections extends StatelessWidget {
  const JobOfferFilterLocationSections({
    super.key,
    required this.palette,
    required this.filters,
    required this.cubit,
    required this.catalogState,
    required this.locationCatalogController,
  });

  final JobOfferFilterPalette palette;
  final JobOfferFilters filters;
  final JobOfferFilterCubit cubit;
  final JobOfferLocationCatalogState catalogState;
  final JobOfferLocationCatalogController locationCatalogController;

  @override
  Widget build(BuildContext context) {
    final provinceName = locationCatalogController.selectedProvinceName(
      provinceId: filters.provinceId,
      fallbackProvinceName: filters.provinceName,
    );
    final municipalityName = locationCatalogController.selectedMunicipalityName(
      municipalityId: filters.municipalityId,
      fallbackMunicipalityName: filters.municipalityName,
    );

    final provinceItems = catalogState.provinces
        .map((province) => province.name)
        .toList(growable: false);
    final municipalityItems = catalogState.municipalities
        .map((municipality) => municipality.name)
        .toList(growable: false);

    final hasProvinceSelection = filters.provinceId?.trim().isNotEmpty ?? false;
    final municipalityEnabled =
        hasProvinceSelection &&
        !catalogState.isLoadingMunicipalities &&
        municipalityItems.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        JobOfferFilterSection(
          title: 'Ubicación',
          icon: Icons.location_on_outlined,
          palette: palette,
          child: JobOfferFilterTextField(
            palette: palette,
            hintText: 'Ej: Madrid, Barcelona',
            controller: cubit.locationController,
            inputStyle: const JobOfferFilterInputStyle(),
            onChanged: cubit.updateLocation,
          ),
        ),
        const SizedBox(height: JobOfferFilterSidebarTokens.sectionSpacing),
        JobOfferFilterSection(
          title: 'Provincia',
          icon: Icons.map_outlined,
          palette: palette,
          child: JobOfferFilterDropdownField(
            palette: palette,
            fieldKey: ValueKey('province-$provinceName'),
            initialValue: provinceName,
            items: provinceItems,
            hintText: catalogState.isLoadingCatalog
                ? 'Cargando provincias...'
                : 'Seleccionar provincia',
            inputStyle: const JobOfferFilterInputStyle(),
            enabled: !catalogState.isLoadingCatalog && provinceItems.isNotEmpty,
            onChanged: (selectedName) {
              final selected = locationCatalogController.findProvinceByName(
                selectedName,
              );
              cubit.updateProvince(
                provinceId: selected?.id,
                provinceName: selected?.name,
              );
              unawaited(
                locationCatalogController.loadMunicipalitiesForProvince(
                  selected?.id,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: JobOfferFilterSidebarTokens.sectionSpacing),
        JobOfferFilterSection(
          title: 'Municipio',
          icon: Icons.location_city_outlined,
          palette: palette,
          child: JobOfferFilterDropdownField(
            palette: palette,
            fieldKey: ValueKey(
              'municipality-${filters.provinceId}-$municipalityName',
            ),
            initialValue: municipalityName,
            items: municipalityItems,
            hintText: !hasProvinceSelection
                ? 'Selecciona una provincia'
                : (catalogState.isLoadingMunicipalities
                      ? 'Cargando municipios...'
                      : 'Seleccionar municipio'),
            inputStyle: const JobOfferFilterInputStyle(),
            enabled: municipalityEnabled,
            onChanged: (selectedName) {
              final selected = locationCatalogController.findMunicipalityByName(
                selectedName,
              );
              cubit.updateMunicipality(
                municipalityId: selected?.id,
                municipalityName: selected?.name,
              );
            },
          ),
        ),
        if (catalogState.catalogError != null) ...[
          const SizedBox(height: uiSpacing8),
          Text(
            catalogState.catalogError!,
            style: TextStyle(
              color: palette.muted,
              fontSize: JobOfferFilterSidebarTokens.regularFontSize - 1,
            ),
          ),
        ],
      ],
    );
  }
}
