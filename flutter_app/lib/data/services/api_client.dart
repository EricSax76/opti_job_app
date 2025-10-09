import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:infojobs_flutter_app/providers/config_providers.dart';

final apiClientProvider = Provider<Dio>((ref) {
  final baseUrl = ref.watch(apiBaseUrlProvider);
  final options = BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 15),
    contentType: 'application/json',
  );

  final dio = Dio(options);
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
