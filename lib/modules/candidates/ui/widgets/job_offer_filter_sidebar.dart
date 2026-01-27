import 'package:flutter/material.dart';
import 'package:opti_job_app/core/theme/ui_tokens.dart';
import 'package:opti_job_app/modules/candidates/models/job_offer_filters.dart';

class JobOfferFilterSidebar extends StatefulWidget {
  const JobOfferFilterSidebar({
    super.key,
    required this.currentFilters,
    required this.onFiltersChanged,
  });

  final JobOfferFilters currentFilters;
  final ValueChanged<JobOfferFilters> onFiltersChanged;

  @override
  State<JobOfferFilterSidebar> createState() => _JobOfferFilterSidebarState();
}

class _JobOfferFilterSidebarState extends State<JobOfferFilterSidebar> {
  late TextEditingController _searchController;
  late JobOfferFilters _filters;

  // Valores predefinidos
  final List<String> _jobTypes = [
    'Presencial',
    'Híbrido',
    'Remoto',
  ];

  final List<String> _educationLevels = [
    'Sin requisitos',
    'Educación Secundaria',
    'FP Grado Medio',
    'FP Grado Superior',
    'Grado Universitario',
    'Máster',
    'Doctorado',
  ];

  double _minSalary = 0;
  double _maxSalary = 100000;

  @override
  void initState() {
    super.initState();
    _filters = widget.currentFilters;
    _searchController = TextEditingController(text: _filters.searchQuery);
    _minSalary = _filters.salaryMin ?? 0;
    _maxSalary = _filters.salaryMax ?? 100000;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _updateFilters(JobOfferFilters newFilters) {
    setState(() => _filters = newFilters);
    widget.onFiltersChanged(newFilters);
  }

  void _clearAllFilters() {
    _searchController.clear();
    setState(() {
      _minSalary = 0;
      _maxSalary = 100000;
    });
    _updateFilters(const JobOfferFilters());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final ink = isDark ? uiDarkInk : uiInk;
    final muted = isDark ? uiDarkMuted : uiMuted;
    final border = isDark ? uiDarkBorder : uiBorder;
    final accent = uiAccent;
    final surface = isDark ? uiDarkSurface : Colors.white;

    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: surface.withValues(alpha: isDark ? 1.0 : 0.8),
        border: Border(
          right: BorderSide(color: border, width: 1),
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.filter_list, color: accent, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Filtros',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: ink,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Search bar
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar ofertas...',
                hintStyle: TextStyle(color: muted),
                prefixIcon: Icon(Icons.search, color: muted),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          _updateFilters(
                            _filters.copyWith(clearSearchQuery: true),
                          );
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: accent, width: 2),
                ),
                filled: true,
                fillColor: isDark ? uiDarkBackground : Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              style: TextStyle(color: ink),
              onChanged: (value) {
                _updateFilters(
                  _filters.copyWith(
                    searchQuery: value.isEmpty ? null : value,
                    clearSearchQuery: value.isEmpty,
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            // Location Filter
            _FilterSection(
              title: 'Ubicación',
              icon: Icons.location_on_outlined,
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Ej: Madrid, Barcelona',
                  hintStyle: TextStyle(color: muted, fontSize: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: accent, width: 2),
                  ),
                  fillColor: isDark ? uiDarkBackground : Colors.white,
                  filled: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
                style: TextStyle(color: ink, fontSize: 14),
                onChanged: (value) {
                  _updateFilters(
                    _filters.copyWith(
                      location: value.isEmpty ? null : value,
                      clearLocation: value.isEmpty,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),

            // Job Type Filter
            _FilterSection(
              title: 'Modalidad',
              icon: Icons.work_outline,
              child: DropdownButtonFormField<String>(
                key: ValueKey(_filters.jobType),
                initialValue: _filters.jobType,
                dropdownColor: isDark ? uiDarkSurface : Colors.white,
                decoration: InputDecoration(
                  hintText: 'Seleccionar',
                  hintStyle: TextStyle(color: muted, fontSize: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: accent, width: 2),
                  ),
                  fillColor: isDark ? uiDarkBackground : Colors.white,
                  filled: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
                items: _jobTypes.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(
                      type,
                      style: TextStyle(fontSize: 14, color: ink),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  _updateFilters(
                    _filters.copyWith(
                      jobType: value,
                      clearJobType: value == null,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),

            // Salary Range Filter
            _FilterSection(
              title: 'Rango Salarial',
              icon: Icons.payments_outlined,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_minSalary.toInt()}€ - ${_maxSalary.toInt()}€',
                    style: TextStyle(
                      color: accent,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  RangeSlider(
                    values: RangeValues(_minSalary, _maxSalary),
                    min: 0,
                    max: 100000,
                    divisions: 100,
                    activeColor: accent,
                    inactiveColor: border,
                    labels: RangeLabels(
                      '${_minSalary.toInt()}€',
                      '${_maxSalary.toInt()}€',
                    ),
                    onChanged: (RangeValues values) {
                      setState(() {
                        _minSalary = values.start;
                        _maxSalary = values.end;
                      });
                    },
                    onChangeEnd: (RangeValues values) {
                      _updateFilters(
                        _filters.copyWith(
                          salaryMin: values.start,
                          salaryMax: values.end,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Education Filter
            _FilterSection(
              title: 'Educación',
              icon: Icons.school_outlined,
              child: DropdownButtonFormField<String>(
                key: ValueKey(_filters.education),
                initialValue: _filters.education,
                dropdownColor: isDark ? uiDarkSurface : Colors.white,
                decoration: InputDecoration(
                  hintText: 'Seleccionar',
                  hintStyle: TextStyle(color: muted, fontSize: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: accent, width: 2),
                  ),
                  fillColor: isDark ? uiDarkBackground : Colors.white,
                  filled: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
                items: _educationLevels.map((level) {
                  return DropdownMenuItem(
                    value: level,
                    child: Text(
                      level,
                      style: TextStyle(fontSize: 14, color: ink),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  _updateFilters(
                    _filters.copyWith(
                      education: value,
                      clearEducation: value == null,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),

            // Company Name Filter
            _FilterSection(
              title: 'Empresa',
              icon: Icons.business_outlined,
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Nombre de la empresa',
                  hintStyle: TextStyle(color: muted, fontSize: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: accent, width: 2),
                  ),
                  fillColor: isDark ? uiDarkBackground : Colors.white,
                  filled: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
                style: TextStyle(color: ink, fontSize: 14),
                onChanged: (value) {
                  _updateFilters(
                    _filters.copyWith(
                      companyName: value.isEmpty ? null : value,
                      clearCompanyName: value.isEmpty,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),

            // Clear Filters Button
            if (_filters.hasActiveFilters)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _clearAllFilters,
                  icon: const Icon(Icons.clear_all, size: 18),
                  label: const Text('Limpiar filtros'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: ink,
                    side: BorderSide(color: border),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _FilterSection extends StatelessWidget {
  const _FilterSection({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    const ink = uiInk;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: ink),
            const SizedBox(width: 6),
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: ink,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}
