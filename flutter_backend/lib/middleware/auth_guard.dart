import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:shelf/shelf.dart';

import '../utils/response.dart';

Middleware authGuardMiddleware({required String secret}) {
  return (innerHandler) {
    return (request) async {
      final authorization = request.headers['Authorization'];
      if (authorization == null || !authorization.startsWith('Bearer ')) {
        return jsonError('Token requerido', statusCode: 401);
      }

      final token = authorization.substring(7);
      try {
        final jwt = JWT.verify(token, SecretKey(secret));
        final updatedRequest = request.change(context: {
          'auth': jwt.payload,
        });
        return innerHandler(updatedRequest);
      } on JWTExpiredError {
        return jsonError('Token expirado', statusCode: 401);
      } on JWTError catch (error) {
        return jsonError('Token inválido: ${error.message}', statusCode: 401);
      }
    };
  };
}
