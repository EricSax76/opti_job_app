import 'package:shelf/shelf.dart';

import 'package:infojobs_flutter_app/backend/config/logger.dart';

Middleware requestLoggingMiddleware() {
  return (innerHandler) {
    return (request) async {
      final stopwatch = Stopwatch()..start();
      Response? response;
      Object? error;
      StackTrace? stackTrace;
      try {
        response = await innerHandler(request);
        return response;
      } catch (err, st) {
        error = err;
        stackTrace = st;
        rethrow;
      } finally {
        stopwatch.stop();
        final status = response?.statusCode ?? 500;
        final message =
            '${request.method} ${request.requestedUri.path} → $status (${stopwatch.elapsedMilliseconds}ms)';
        if (status >= 500 || error != null) {
          appLogger.severe(message, error, stackTrace);
        } else {
          appLogger.info(message);
        }
      }
    };
  };
}
