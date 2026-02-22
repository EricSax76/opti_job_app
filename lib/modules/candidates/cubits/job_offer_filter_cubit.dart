import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opti_job_app/modules/candidates/models/job_offer_filters.dart';
import 'package:opti_job_app/modules/candidates/ui/widgets/filters/job_offer_filter_sidebar_tokens.dart';

part 'job_offer_filter_state.dart';

class JobOfferFilterCubit extends Cubit<JobOfferFilterState> {
  JobOfferFilterCubit({
    required JobOfferFilters initialFilters,
    required this.onFiltersChanged,
  }) : super(JobOfferFilterState.initial(initialFilters)) {
    _searchController = TextEditingController(text: initialFilters.searchQuery);
    _locationController = TextEditingController(text: initialFilters.location);
    _companyController = TextEditingController(
      text: initialFilters.companyName,
    );
  }

  final ValueChanged<JobOfferFilters> onFiltersChanged;
  late final TextEditingController _searchController;
  late final TextEditingController _locationController;
  late final TextEditingController _companyController;
  Timer? _debounceTimer;

  static const Duration _debounceDuration = Duration(milliseconds: 300);

  TextEditingController get searchController => _searchController;
  TextEditingController get locationController => _locationController;
  TextEditingController get companyController => _companyController;

  @override
  Future<void> close() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _locationController.dispose();
    _companyController.dispose();
    return super.close();
  }

  void syncExternalFilters(JobOfferFilters externalFilters) {
    if (externalFilters == state.filters) return;

    _syncControllerText(_searchController, externalFilters.searchQuery);
    _syncControllerText(_locationController, externalFilters.location);
    _syncControllerText(_companyController, externalFilters.companyName);

    _debounceTimer?.cancel();
    emit(
      state.copyWith(
        filters: externalFilters,
        minSalary: JobOfferFilterSidebarTokens.minSalary,
        maxSalary: JobOfferFilterSidebarTokens.maxSalary,
      ),
    );
  }

  void clearAllFilters() {
    _debounceTimer?.cancel();
    _searchController.clear();
    _locationController.clear();
    _companyController.clear();

    const clearedFilters = JobOfferFilters();
    emit(JobOfferFilterState.initial(clearedFilters));
    onFiltersChanged(clearedFilters);
  }

  void clearSearchQuery() {
    _searchController.clear();
    _updateFilters(state.filters.copyWith(clearSearchQuery: true));
  }

  void updateSearchQuery(String value) {
    _updateFilters(
      state.filters.copyWith(
        searchQuery: value.isEmpty ? null : value,
        clearSearchQuery: value.isEmpty,
      ),
      debounce: true,
    );
  }

  void updateLocation(String value) {
    _updateFilters(
      state.filters.copyWith(
        location: value.isEmpty ? null : value,
        clearLocation: value.isEmpty,
      ),
      debounce: true,
    );
  }

  void updateProvince({
    required String? provinceId,
    required String? provinceName,
  }) {
    final currentProvinceId = state.filters.provinceId;
    final provinceChanged = currentProvinceId != provinceId;
    _updateFilters(
      state.filters.copyWith(
        provinceId: provinceId,
        provinceName: provinceName,
        clearProvinceId: provinceId == null,
        clearProvinceName: provinceName == null,
        clearMunicipalityId: provinceChanged,
        clearMunicipalityName: provinceChanged,
      ),
    );
  }

  void updateMunicipality({
    required String? municipalityId,
    required String? municipalityName,
  }) {
    _updateFilters(
      state.filters.copyWith(
        municipalityId: municipalityId,
        municipalityName: municipalityName,
        clearMunicipalityId: municipalityId == null,
        clearMunicipalityName: municipalityName == null,
      ),
    );
  }

  void updateCompany(String value) {
    _updateFilters(
      state.filters.copyWith(
        companyName: value.isEmpty ? null : value,
        clearCompanyName: value.isEmpty,
      ),
      debounce: true,
    );
  }

  void updateJobType(String? value) {
    _updateFilters(
      state.filters.copyWith(jobType: value, clearJobType: value == null),
    );
  }

  void updateEducation(String? value) {
    _updateFilters(
      state.filters.copyWith(education: value, clearEducation: value == null),
    );
  }

  void updateJobCategory(String? value) {
    _updateFilters(
      state.filters.copyWith(
        jobCategory: value,
        clearJobCategory: value == null,
      ),
    );
  }

  void updateWorkSchedule(String? value) {
    _updateFilters(
      state.filters.copyWith(
        workSchedule: value,
        clearWorkSchedule: value == null,
      ),
    );
  }

  void updateContractType(String? value) {
    _updateFilters(
      state.filters.copyWith(
        contractType: value,
        clearContractType: value == null,
      ),
    );
  }

  void updateDatePosted(String? value) {
    _updateFilters(
      state.filters.copyWith(
        datePosted: value,
        clearDatePosted: value == null,
      ),
    );
  }

  void updateSalaryPreview(RangeValues values) {
    emit(state.copyWith(minSalary: values.start, maxSalary: values.end));
  }

  void commitSalaryRange(RangeValues values) {
    _updateFilters(
      state.filters.copyWith(salaryMin: values.start, salaryMax: values.end),
    );
  }

  void _updateFilters(JobOfferFilters newFilters, {bool debounce = false}) {
    emit(state.copyWith(filters: newFilters));

    _debounceTimer?.cancel();
    if (debounce) {
      _debounceTimer = Timer(_debounceDuration, () {
        onFiltersChanged(newFilters);
      });
    } else {
      onFiltersChanged(newFilters);
    }
  }

  void _syncControllerText(TextEditingController controller, String? value) {
    final normalizedValue = value ?? '';
    if (controller.text == normalizedValue) return;
    controller.value = controller.value.copyWith(
      text: normalizedValue,
      selection: TextSelection.collapsed(offset: normalizedValue.length),
      composing: TextRange.empty,
    );
  }
}
