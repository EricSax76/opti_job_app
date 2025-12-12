import 'package:shelf/shelf.dart';
import 'package:shelf_cors_headers/shelf_cors_headers.dart';

Middleware createCorsMiddleware() {
  const defaultCorsHeaders = {
    ACCESS_CONTROL_ALLOW_ORIGIN: '*',
    ACCESS_CONTROL_ALLOW_HEADERS:
        'Origin, Content-Type, Accept, Authorization',
    ACCESS_CONTROL_ALLOW_METHODS: 'GET, POST, PUT, DELETE, OPTIONS',
  };

  return corsHeaders(headers: defaultCorsHeaders);
}
