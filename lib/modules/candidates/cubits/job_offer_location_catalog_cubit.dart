import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class JobOfferLocationCatalogController extends ChangeNotifier {
  JobOfferLocationCatalogController({
    FirebaseFirestore? firestore,
    http.Client? httpClient,
    String? catalogBaseUrl,
  }) : _firestore = firestore ?? _resolveFirestore(),
       _httpClient = httpClient ?? http.Client(),
       _ownsHttpClient = httpClient == null,
       _catalogBaseUrl = _normalizeBaseUrl(
         catalogBaseUrl ?? _catalogBaseUrlFromEnvironment,
       );

  static const String _catalogBaseUrlFromEnvironment = String.fromEnvironment(
    'LOCATION_CATALOG_BASE_URL',
    defaultValue: '',
  );

  final FirebaseFirestore? _firestore;
  final http.Client _httpClient;
  final bool _ownsHttpClient;
  final String? _catalogBaseUrl;

  JobOfferLocationCatalogState _state = const JobOfferLocationCatalogState();
  JobOfferLocationCatalogState get state => _state;

  int _catalogRequestSequence = 0;
  int _municipalityRequestSequence = 0;
  bool _isDisposed = false;

  Future<void> initialize({String? initialProvinceId}) async {
    final requestId = ++_catalogRequestSequence;
    _emit(_state.copyWith(isLoadingCatalog: true, clearCatalogError: true));

    final httpCatalog = await _tryLoadCatalogFromHttp(
      requestId: requestId,
      initialProvinceId: initialProvinceId,
    );
    if (httpCatalog != null) {
      _emit(httpCatalog);
      return;
    }

    final firestore = _firestore;
    if (firestore == null) {
      _emit(
        _state.copyWith(
          isLoadingCatalog: false,
          isLoadingMunicipalities: false,
          clearCatalogError: true,
        ),
      );
      return;
    }

    try {
      final provincesDoc = await firestore
          .collection('catalog')
          .doc('provincias_es')
          .get();
      final provinces = _readCatalogItems(provincesDoc.data());
      final municipalities = await _fetchMunicipalitiesForProvince(
        initialProvinceId,
      );
      if (_isDisposed || requestId != _catalogRequestSequence) return;

      _emit(
        _state.copyWith(
          provinces: provinces,
          municipalities: municipalities,
          loadedMunicipalityProvinceId: _normalizeId(initialProvinceId),
          isLoadingCatalog: false,
          isLoadingMunicipalities: false,
          clearCatalogError: true,
        ),
      );
    } catch (_) {
      if (_isDisposed || requestId != _catalogRequestSequence) return;
      _emit(
        _state.copyWith(
          isLoadingCatalog: false,
          isLoadingMunicipalities: false,
          catalogError: 'No se pudo cargar el catálogo de ubicaciones.',
        ),
      );
    }
  }

  Future<void> loadMunicipalitiesForProvince(String? provinceId) async {
    final normalizedProvinceId = _normalizeId(provinceId);
    if (normalizedProvinceId == null) {
      _emit(
        _state.copyWith(
          municipalities: const [],
          clearLoadedMunicipalityProvinceId: true,
          isLoadingMunicipalities: false,
          clearCatalogError: true,
        ),
      );
      return;
    }

    if (normalizedProvinceId == _state.loadedMunicipalityProvinceId &&
        _state.municipalities.isNotEmpty) {
      return;
    }

    final requestId = ++_municipalityRequestSequence;
    _emit(
      _state.copyWith(isLoadingMunicipalities: true, clearCatalogError: true),
    );

    final httpMunicipalities = await _tryLoadMunicipalitiesFromHttp(
      requestId: requestId,
      provinceId: normalizedProvinceId,
    );
    if (httpMunicipalities != null) {
      _emit(
        _state.copyWith(
          municipalities: httpMunicipalities,
          loadedMunicipalityProvinceId: normalizedProvinceId,
          isLoadingMunicipalities: false,
          clearCatalogError: true,
        ),
      );
      return;
    }

    try {
      final municipalities = await _fetchMunicipalitiesForProvince(
        normalizedProvinceId,
      );
      if (_isDisposed || requestId != _municipalityRequestSequence) return;

      _emit(
        _state.copyWith(
          municipalities: municipalities,
          loadedMunicipalityProvinceId: normalizedProvinceId,
          isLoadingMunicipalities: false,
          clearCatalogError: true,
        ),
      );
    } catch (_) {
      if (_isDisposed || requestId != _municipalityRequestSequence) return;
      _emit(
        _state.copyWith(
          municipalities: const [],
          loadedMunicipalityProvinceId: normalizedProvinceId,
          isLoadingMunicipalities: false,
          catalogError: 'No se pudieron cargar los municipios.',
        ),
      );
    }
  }

  JobOfferLocationCatalogItem? findProvinceByName(String? name) {
    return _findByName(_state.provinces, name);
  }

  JobOfferLocationCatalogItem? findMunicipalityByName(String? name) {
    return _findByName(_state.municipalities, name);
  }

  String? selectedProvinceName({
    required String? provinceId,
    required String? fallbackProvinceName,
  }) {
    final byId = _findById(_state.provinces, provinceId)?.name;
    if (byId != null) return byId;
    if (fallbackProvinceName == null || fallbackProvinceName.trim().isEmpty) {
      return null;
    }
    final byName = _findByName(_state.provinces, fallbackProvinceName);
    return byName?.name;
  }

  String? selectedMunicipalityName({
    required String? municipalityId,
    required String? fallbackMunicipalityName,
  }) {
    final byId = _findById(_state.municipalities, municipalityId)?.name;
    if (byId != null) return byId;
    if (fallbackMunicipalityName == null ||
        fallbackMunicipalityName.trim().isEmpty) {
      return null;
    }
    final byName = _findByName(_state.municipalities, fallbackMunicipalityName);
    return byName?.name;
  }

  List<JobOfferLocationCatalogItem> _readCatalogItems(
    Map<String, dynamic>? data,
  ) {
    final rawItems = data?['items'];
    if (rawItems is! List) return const [];

    final deduplicated = <String, JobOfferLocationCatalogItem>{};
    for (final rawItem in rawItems) {
      if (rawItem is! Map) continue;
      final item = JobOfferLocationCatalogItem.fromMap(rawItem);
      if (item == null) continue;
      deduplicated[item.id] = item;
    }

    final items = deduplicated.values.toList(growable: false)
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return items;
  }

  Future<JobOfferLocationCatalogState?> _tryLoadCatalogFromHttp({
    required int requestId,
    required String? initialProvinceId,
  }) async {
    if (_catalogBaseUrl == null) return null;
    try {
      final provincesData = await _fetchJsonFromHttp('geo/provincias_es.json');
      final provinces = _readCatalogItems(provincesData);
      final municipalities = await _fetchMunicipalitiesFromHttp(
        initialProvinceId,
      );
      if (_isDisposed || requestId != _catalogRequestSequence) {
        return null;
      }
      return _state.copyWith(
        provinces: provinces,
        municipalities: municipalities,
        loadedMunicipalityProvinceId: _normalizeId(initialProvinceId),
        isLoadingCatalog: false,
        isLoadingMunicipalities: false,
        clearCatalogError: true,
      );
    } catch (_) {
      return null;
    }
  }

  Future<List<JobOfferLocationCatalogItem>?> _tryLoadMunicipalitiesFromHttp({
    required int requestId,
    required String provinceId,
  }) async {
    if (_catalogBaseUrl == null) return null;
    try {
      final municipalities = await _fetchMunicipalitiesFromHttp(provinceId);
      if (_isDisposed || requestId != _municipalityRequestSequence) {
        return null;
      }
      return municipalities;
    } catch (_) {
      return null;
    }
  }

  Future<List<JobOfferLocationCatalogItem>> _fetchMunicipalitiesFromHttp(
    String? provinceId,
  ) async {
    final normalizedProvinceId = _normalizeId(provinceId);
    if (normalizedProvinceId == null) return const [];
    final path = 'geo/municipios_$normalizedProvinceId.json';
    final data = await _fetchJsonFromHttp(path);
    return _readCatalogItems(data);
  }

  Future<Map<String, dynamic>> _fetchJsonFromHttp(String relativePath) async {
    final uri = _buildCatalogUri(relativePath);
    final response = await _httpClient.get(
      uri,
      headers: const {'Accept': 'application/json'},
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError(
        'Location catalog request failed (${response.statusCode}) for $uri',
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map) {
      throw const FormatException('Location catalog JSON must be an object.');
    }

    return _toStringDynamicMap(decoded);
  }

  Uri _buildCatalogUri(String relativePath) {
    final base = _catalogBaseUrl;
    if (base == null) {
      throw StateError('Location catalog base URL is not configured.');
    }
    final baseUri = Uri.parse('$base/');
    return baseUri.resolve(relativePath);
  }

  Map<String, dynamic> _toStringDynamicMap(Map<dynamic, dynamic> value) {
    final map = <String, dynamic>{};
    value.forEach((key, item) {
      map[key.toString()] = item;
    });
    return map;
  }

  Future<List<JobOfferLocationCatalogItem>> _fetchMunicipalitiesForProvince(
    String? provinceId,
  ) async {
    final firestore = _firestore;
    if (firestore == null) return const [];

    final normalizedProvinceId = _normalizeId(provinceId);
    if (normalizedProvinceId == null) return const [];

    final municipalitiesDoc = await firestore
        .collection('catalog_municipios')
        .doc(normalizedProvinceId)
        .get();
    return _readCatalogItems(municipalitiesDoc.data());
  }

  JobOfferLocationCatalogItem? _findById(
    List<JobOfferLocationCatalogItem> items,
    String? id,
  ) {
    final normalizedId = _normalizeId(id);
    if (normalizedId == null) return null;
    for (final item in items) {
      if (item.id == normalizedId) return item;
    }
    return null;
  }

  JobOfferLocationCatalogItem? _findByName(
    List<JobOfferLocationCatalogItem> items,
    String? name,
  ) {
    final normalizedName = name?.trim();
    if (normalizedName == null || normalizedName.isEmpty) return null;
    for (final item in items) {
      if (item.name == normalizedName) return item;
    }
    return null;
  }

  String? _normalizeId(String? value) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) return null;
    return normalized;
  }

  static FirebaseFirestore? _resolveFirestore() {
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  static String? _normalizeBaseUrl(String? value) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) return null;
    if (normalized.endsWith('/')) {
      return normalized.substring(0, normalized.length - 1);
    }
    return normalized;
  }

  void _emit(JobOfferLocationCatalogState nextState) {
    if (_isDisposed) return;
    _state = nextState;
    notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    if (_ownsHttpClient) {
      _httpClient.close();
    }
    super.dispose();
  }
}

class JobOfferLocationCatalogState {
  const JobOfferLocationCatalogState({
    this.provinces = const [],
    this.municipalities = const [],
    this.loadedMunicipalityProvinceId,
    this.isLoadingCatalog = true,
    this.isLoadingMunicipalities = false,
    this.catalogError,
  });

  final List<JobOfferLocationCatalogItem> provinces;
  final List<JobOfferLocationCatalogItem> municipalities;
  final String? loadedMunicipalityProvinceId;
  final bool isLoadingCatalog;
  final bool isLoadingMunicipalities;
  final String? catalogError;

  JobOfferLocationCatalogState copyWith({
    List<JobOfferLocationCatalogItem>? provinces,
    List<JobOfferLocationCatalogItem>? municipalities,
    String? loadedMunicipalityProvinceId,
    bool clearLoadedMunicipalityProvinceId = false,
    bool? isLoadingCatalog,
    bool? isLoadingMunicipalities,
    String? catalogError,
    bool clearCatalogError = false,
  }) {
    return JobOfferLocationCatalogState(
      provinces: provinces ?? this.provinces,
      municipalities: municipalities ?? this.municipalities,
      loadedMunicipalityProvinceId: clearLoadedMunicipalityProvinceId
          ? null
          : (loadedMunicipalityProvinceId ?? this.loadedMunicipalityProvinceId),
      isLoadingCatalog: isLoadingCatalog ?? this.isLoadingCatalog,
      isLoadingMunicipalities:
          isLoadingMunicipalities ?? this.isLoadingMunicipalities,
      catalogError: clearCatalogError
          ? null
          : (catalogError ?? this.catalogError),
    );
  }
}

class JobOfferLocationCatalogItem {
  const JobOfferLocationCatalogItem({required this.id, required this.name});

  final String id;
  final String name;

  static JobOfferLocationCatalogItem? fromMap(Map<dynamic, dynamic> map) {
    final rawId = map['id'] ?? map['code'] ?? map['codigo'];
    final rawName = map['name'] ?? map['nombre'];
    final id = rawId?.toString().trim() ?? '';
    final name = rawName?.toString().trim() ?? '';
    if (id.isEmpty || name.isEmpty) return null;
    return JobOfferLocationCatalogItem(id: id, name: name);
  }
}
