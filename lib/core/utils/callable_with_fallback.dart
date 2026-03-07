import 'package:cloud_functions/cloud_functions.dart';

typedef CallableFallbackPredicate =
    bool Function(FirebaseFunctionsException error);

class CallableWithFallback {
  CallableWithFallback({
    required FirebaseFunctions functions,
    required FirebaseFunctions fallbackFunctions,
    Set<String> recoverableCodes = const <String>{'not-found', 'unimplemented'},
  }) : _functions = functions,
       _fallbackFunctions = fallbackFunctions,
       _recoverableCodes = _normalizeCodes(recoverableCodes);

  final FirebaseFunctions _functions;
  final FirebaseFunctions _fallbackFunctions;
  final Set<String> _recoverableCodes;

  Future<HttpsCallableResult<T>> call<T>({
    required String name,
    Map<String, dynamic> payload = const <String, dynamic>{},
    Set<String>? recoverableCodes,
    CallableFallbackPredicate? shouldFallback,
  }) async {
    try {
      return await _functions.httpsCallable(name).call<T>(payload);
    } on FirebaseFunctionsException catch (error) {
      final fallbackAllowed =
          shouldFallback?.call(error) ??
          _resolveRecoverableCodes(
            recoverableCodes,
          ).contains(error.code.trim().toLowerCase());
      if (!fallbackAllowed) rethrow;
      return _fallbackFunctions.httpsCallable(name).call<T>(payload);
    }
  }

  Future<Map<String, dynamic>> callMap({
    required String name,
    Map<String, dynamic> payload = const <String, dynamic>{},
    Set<String>? recoverableCodes,
    CallableFallbackPredicate? shouldFallback,
  }) async {
    final result = await call<dynamic>(
      name: name,
      payload: payload,
      recoverableCodes: recoverableCodes,
      shouldFallback: shouldFallback,
    );
    return asMap(result.data);
  }

  Future<void> callVoid({
    required String name,
    Map<String, dynamic> payload = const <String, dynamic>{},
    Set<String>? recoverableCodes,
    CallableFallbackPredicate? shouldFallback,
  }) async {
    await call<dynamic>(
      name: name,
      payload: payload,
      recoverableCodes: recoverableCodes,
      shouldFallback: shouldFallback,
    );
  }

  static Map<String, dynamic> asMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return const <String, dynamic>{};
  }

  Set<String> _resolveRecoverableCodes(Set<String>? recoverableCodes) {
    if (recoverableCodes == null) return _recoverableCodes;
    return _normalizeCodes(recoverableCodes);
  }

  static Set<String> _normalizeCodes(Set<String> codes) {
    return codes
        .map((code) => code.trim().toLowerCase())
        .where((code) => code.isNotEmpty)
        .toSet();
  }
}
