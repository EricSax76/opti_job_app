import 'dart:async';
import 'dart:convert';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;

final _webVitalsTelemetry = _WebVitalsTelemetry();

void startWebVitalsTelemetryImpl() {
  _webVitalsTelemetry.start();
}

class _WebVitalsTelemetry {
  static const String _storageKey = 'opti_web_vitals_queue';
  final FirebaseFunctions _regionalFunctions = FirebaseFunctions.instanceFor(
    region: 'europe-west1',
  );
  final FirebaseFunctions _fallbackFunctions = FirebaseFunctions.instance;

  bool _started = false;
  bool _isSending = false;

  void start() {
    if (_started) return;
    _started = true;
    Timer.periodic(
      const Duration(seconds: 20),
      (_) => unawaited(_flushQueue()),
    );
    unawaited(Future<void>.delayed(const Duration(seconds: 8), _flushQueue));
  }

  Future<void> _flushQueue() async {
    if (_isSending) return;
    final queue = _readQueue();
    if (queue.isEmpty) return;

    final maxBatchSize = queue.length > 40 ? 40 : queue.length;
    final batch = queue.take(maxBatchSize).toList(growable: false);
    final remaining = queue.skip(maxBatchSize).toList(growable: false);
    if (batch.isEmpty) return;

    _isSending = true;
    try {
      await _callCallableWithFallback(
        name: 'reportWebVitalsBatch',
        payload: {'events': batch},
      );
      _writeQueue(remaining);
    } catch (error) {
      if (kDebugMode) {
        debugPrint('[WebVitalsTelemetry] Failed to report metrics: $error');
      }
    } finally {
      _isSending = false;
    }
  }

  List<Map<String, dynamic>> _readQueue() {
    try {
      final raw = web.window.localStorage.getItem(_storageKey);
      if (raw == null || raw.trim().isEmpty) return const [];
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];

      return decoded
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .where(_isValidEvent)
          .toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  void _writeQueue(List<Map<String, dynamic>> queue) {
    try {
      final safe = queue.take(200).toList(growable: false);
      web.window.localStorage.setItem(_storageKey, jsonEncode(safe));
    } catch (_) {
      // Ignored in favor of keeping application flow non-blocking.
    }
  }

  bool _isValidEvent(Map<String, dynamic> event) {
    final metric = (event['metric'] as String?)?.trim();
    final value = event['value'];
    if (metric == null || metric.isEmpty) return false;
    if (value is num) return value >= 0;
    final parsed = double.tryParse(value?.toString() ?? '');
    return parsed != null && parsed >= 0;
  }

  Future<void> _callCallableWithFallback({
    required String name,
    required Map<String, dynamic> payload,
  }) async {
    try {
      await _regionalFunctions.httpsCallable(name).call(payload);
    } on FirebaseFunctionsException catch (error) {
      if (!_isRecoverable(error.code)) rethrow;
      await _fallbackFunctions.httpsCallable(name).call(payload);
    }
  }

  bool _isRecoverable(String code) {
    return code == 'not-found' ||
        code == 'unimplemented' ||
        code == 'unavailable';
  }
}
