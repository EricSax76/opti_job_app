class AuthException implements Exception {
  final String message;
  final String? code;

  AuthException(this.message, {this.code});

  @override
  String toString() => 'AuthException: $message ($code)';
}

class UserNotFoundException extends AuthException {
  UserNotFoundException() : super('Usuario no encontrado.');
}

class WrongPasswordException extends AuthException {
  WrongPasswordException() : super('Contraseña incorrecta.');
}

class InvalidEmailException extends AuthException {
  InvalidEmailException() : super('Email inválido.');
}

class NetworkException extends AuthException {
  NetworkException() : super('Error de red. Revisa tu conexión.');
}

class TooManyRequestsException extends AuthException {
  TooManyRequestsException() : super('Demasiados intentos. Intenta más tarde.');
}

class PermissionDeniedException extends AuthException {
  PermissionDeniedException() : super('Permiso denegado.');
}
