import 'dart:async';

import 'package:flutter/material.dart';

import 'package:opti_job_app/modules/candidates/models/job_offer_filters.dart';
import 'package:opti_job_app/modules/candidates/ui/widgets/filters/job_offer_filter_sidebar_models.dart';
import 'package:opti_job_app/modules/candidates/ui/widgets/filters/job_offer_filter_sidebar_tokens.dart';

class JobOfferFilterSidebarController {
  static const Duration _textFilterDebounceDuration = Duration(
    milliseconds: 300,
  );
  static const double _defaultMinSalary = JobOfferFilterSidebarTokens.minSalary;
  static const double _defaultMaxSalary = JobOfferFilterSidebarTokens.maxSalary;

  JobOfferFilterSidebarController({
    required JobOfferFilters initialFilters,
    required ValueChanged<JobOfferFilters> onFiltersChanged,
  }) : _onFiltersChanged = onFiltersChanged,
       state = ValueNotifier(
         JobOfferFilterSidebarViewState.fromFilters(
           initialFilters,
           defaultMin: _defaultMinSalary,
           defaultMax: _defaultMaxSalary,
         ),
       ) {
    searchController = TextEditingController(text: initialFilters.searchQuery);
    locationController = TextEditingController(text: initialFilters.location);
    companyController = TextEditingController(text: initialFilters.companyName);
  }

  final ValueNotifier<JobOfferFilterSidebarViewState> state;
  late final TextEditingController searchController;
  late final TextEditingController locationController;
  late final TextEditingController companyController;

  ValueChanged<JobOfferFilters> _onFiltersChanged;
  Timer? _textFilterDebounce;

  JobOfferFilters get filters => state.value.filters;

  void updateOnFiltersChanged(ValueChanged<JobOfferFilters> callback) {
    _onFiltersChanged = callback;
  }

  void syncExternalFilters(JobOfferFilters externalFilters) {
    if (externalFilters == filters) return;
    _syncControllerText(searchController, externalFilters.searchQuery);
    _syncControllerText(locationController, externalFilters.location);
    _syncControllerText(companyController, externalFilters.companyName);
    _textFilterDebounce?.cancel();
    state.value = JobOfferFilterSidebarViewState.fromFilters(
      externalFilters,
      defaultMin: _defaultMinSalary,
      defaultMax: _defaultMaxSalary,
    );
  }

  void clearAllFilters() {
    _textFilterDebounce?.cancel();
    searchController.clear();
    locationController.clear();
    companyController.clear();
    const clearedFilters = JobOfferFilters();
    state.value = JobOfferFilterSidebarViewState.fromFilters(
      clearedFilters,
      defaultMin: _defaultMinSalary,
      defaultMax: _defaultMaxSalary,
    );
    _onFiltersChanged(clearedFilters);
  }

  void clearSearchQuery() {
    searchController.clear();
    _setFilters(filters.copyWith(clearSearchQuery: true));
  }

  void updateSearchQuery(String value) {
    _setFilters(
      filters.copyWith(
        searchQuery: value.isEmpty ? null : value,
        clearSearchQuery: value.isEmpty,
      ),
      debounced: true,
    );
  }

  void updateLocation(String value) {
    _setFilters(
      filters.copyWith(
        location: value.isEmpty ? null : value,
        clearLocation: value.isEmpty,
      ),
      debounced: true,
    );
  }

  void updateCompany(String value) {
    _setFilters(
      filters.copyWith(
        companyName: value.isEmpty ? null : value,
        clearCompanyName: value.isEmpty,
      ),
      debounced: true,
    );
  }

  void updateJobType(String? value) {
    _setFilters(filters.copyWith(jobType: value, clearJobType: value == null));
  }

  void updateEducation(String? value) {
    _setFilters(
      filters.copyWith(education: value, clearEducation: value == null),
    );
  }

  void updateSalaryPreview(RangeValues values) {
    state.value = state.value.copyWith(
      minSalary: values.start,
      maxSalary: values.end,
    );
  }

  void commitSalaryRange(RangeValues values) {
    _setFilters(
      filters.copyWith(salaryMin: values.start, salaryMax: values.end),
    );
  }

  void dispose() {
    _textFilterDebounce?.cancel();
    searchController.dispose();
    locationController.dispose();
    companyController.dispose();
    state.dispose();
  }

  void _setFilters(JobOfferFilters newFilters, {bool debounced = false}) {
    state.value = state.value.copyWith(filters: newFilters);
    if (debounced) {
      _textFilterDebounce?.cancel();
      _textFilterDebounce = Timer(_textFilterDebounceDuration, () {
        _onFiltersChanged(newFilters);
      });
      return;
    }
    _textFilterDebounce?.cancel();
    _onFiltersChanged(newFilters);
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
