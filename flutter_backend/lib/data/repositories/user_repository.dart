import 'package:postgres/postgres.dart';

import '../../config/logger.dart';
import '../datasource/database.dart';
import '../models/user.dart';

abstract class UserRepository {
  Future<User?> findByEmail(String email);

  Future<User> createUser({
    required String name,
    required String email,
    required String passwordHash,
    String role,
  });
}

class DuplicateEmailException implements Exception {
  const DuplicateEmailException();
}

class UserRepositoryException implements Exception {
  const UserRepositoryException(this.message, [this.cause]);

  final String message;
  final Object? cause;

  @override
  String toString() => 'UserRepositoryException($message, $cause)';
}

class DbUserRepository implements UserRepository {
  DbUserRepository(this._db);

  final DatabaseManager _db;

  @override
  Future<User?> findByEmail(String email) async {
    const sql = '''
      SELECT id, name, email, role, password_hash
      FROM users
      WHERE email = @email
      LIMIT 1;
    ''';

    final result = await _db.run(
      (session) => session.execute(
        Sql.named(sql),
        parameters: {'email': email},
      ),
    );

    if (result.isEmpty) return null;
    return User.fromRow(result.first);
  }

  @override
  Future<User> createUser({
    required String name,
    required String email,
    required String passwordHash,
    String role = 'candidate',
  }) async {
    const sql = '''
      INSERT INTO users (name, email, password_hash, role)
      VALUES (@name, @email, @password_hash, @role)
      RETURNING id, name, email, role, password_hash;
    ''';

    try {
      final result = await _db.run(
        (session) => session.execute(
          Sql.named(sql),
          parameters: {
            'name': name,
            'email': email,
            'password_hash': passwordHash,
            'role': role,
          },
        ),
      );

      return User.fromRow(result.first);
    } on ServerException catch (error, stackTrace) {
      appLogger.warning(
        'Error al crear usuario',
        error,
        stackTrace,
      );
      if (error.code == '23505') {
        throw const DuplicateEmailException();
      }
      throw UserRepositoryException(
        'No se pudo crear el usuario',
        error,
      );
    }
  }
}
