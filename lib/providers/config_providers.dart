import 'package:flutter_riverpod/flutter_riverpod.dart';

const _defaultBaseUrl = 'http://localhost:5001/api';

final apiBaseUrlProvider = Provider<String>(
  (ref) => const String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: _defaultBaseUrl,
  ),
);
