import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:infojobs_flutter_app/backend/utils/response.dart';
import 'package:shelf/shelf.dart';

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
      } on JWTExpiredException {
        return jsonError('Token expirado', statusCode: 401);
      } on JWTException catch (error) {
        return jsonError('Token inválido: ${error.message}', statusCode: 401);
      }
    };
  };
}
