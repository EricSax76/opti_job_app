import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:infojobs_flutter_app/data/services/token_storage.dart';
import 'package:infojobs_flutter_app/providers/config_providers.dart';
import 'package:infojobs_flutter_app/utils/id_utils.dart';

final apiClientProvider = Provider<Dio>((ref) {
  final baseUrl = ref.watch(apiBaseUrlProvider);
  final storage = ref.watch(tokenStorageProvider);
  final options = BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 15),
    contentType: 'application/json',
  );

  final dio = Dio(options);
  dio.interceptors.add(
    QueuedInterceptorsWrapper(
      onRequest: (options, handler) async {
        options.headers['X-Trace-Id'] ??= generateTraceId();
        if (options.method != 'GET') {
          options.headers['Idempotency-Key'] ??=
              generateIdempotencyKey();
        }
        final session = await storage.read();
        if (session != null) {
          options.headers['Authorization'] =
              'Bearer ${session.accessToken}';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          await storage.clear();
        }
        handler.next(error);
      },
    ),
  );
  dio.interceptors.add(LogInterceptor(
    requestBody: true,
    responseBody: true,
    logPrint: (object) => ref
        .container
        .read(_loggerProvider)
        .call(object.toString()),
  ));
  return dio;
});

typedef LoggerFn = void Function(String message);

final _loggerProvider = Provider<LoggerFn>((_) {
  return (message) => print('[API] $message'); // ignore: avoid_print
});
