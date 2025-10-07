import 'package:shelf/shelf.dart';
import 'package:shelf_cors_headers/shelf_cors_headers.dart' as cors;

Middleware createCorsMiddleware() {
  const headers = {
    cors.ACCESS_CONTROL_ALLOW_ORIGIN: '*',
    cors.ACCESS_CONTROL_ALLOW_HEADERS:
        'Origin, Content-Type, Accept, Authorization',
    cors.ACCESS_CONTROL_ALLOW_METHODS: 'GET, POST, PUT, DELETE, OPTIONS',
  };

  return cors.corsHeaders(headers: headers);
}
