import 'package:postgres/postgres.dart';

import 'package:infojobs_flutter_app/backend/config/logger.dart';
import 'package:infojobs_flutter_app/backend/data/datasource/database.dart';
import 'package:infojobs_flutter_app/backend/data/models/company.dart';
import 'package:infojobs_flutter_app/backend/data/models/user.dart';

class CompanyRepository {
  CompanyRepository(this._db);

  final DatabaseManager _db;

  Future<Company> createCompany({
    required String name,
    required String email,
    required String passwordHash,
  }) async {
    const insertUserSql = '''
      INSERT INTO users (name, email, password_hash, role)
      VALUES (@name, @email, @password_hash, 'company')
      RETURNING id, name, email, role, password_hash;
    ''';

    const insertCompanySql = '''
      INSERT INTO companies (user_id)
      VALUES (@user_id)
      RETURNING id;
    ''';

    const selectCompanySql = '''
      SELECT
        c.id AS company_id,
        u.id AS user_id,
        u.name,
        u.email,
        u.role
      FROM companies c
      JOIN users u ON c.user_id = u.id
      WHERE c.id = @company_id
      LIMIT 1;
    ''';

    return _db.run((session) async {
      await session.execute('BEGIN;');
      try {
        final userResult = await session.execute(
          Sql.named(insertUserSql),
          parameters: {
            'name': name,
            'email': email,
            'password_hash': passwordHash,
          },
        );

        final user = User.fromRow(userResult.first);
        final companyResult = await session.execute(
          Sql.named(insertCompanySql),
          parameters: {'user_id': user.id},
        );

        final companyId = companyResult.first.toColumnMap()['id'];
        final companyRows = await session.execute(
          Sql.named(selectCompanySql),
          parameters: {'company_id': companyId},
        );

        await session.execute('COMMIT;');
        return Company.fromRow(companyRows.first);
      } catch (error, stackTrace) {
        await session.execute('ROLLBACK;');
        appLogger.severe('Error al registrar empresa', error, stackTrace);
        rethrow;
      }
    });
  }

  Future<User?> findUserByEmail(String email) async {
    const sql = '''
      SELECT id, name, email, role, password_hash
      FROM users
      WHERE email = @email AND role = 'company'
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

  Future<Company?> findCompanyByUserId(int userId) async {
    const sql = '''
      SELECT
        c.id AS company_id,
        u.id AS user_id,
        u.name,
        u.email,
        u.role
      FROM companies c
      JOIN users u ON c.user_id = u.id
      WHERE u.id = @user_id
      LIMIT 1;
    ''';

    final result = await _db.run(
      (session) => session.execute(
        Sql.named(sql),
        parameters: {'user_id': userId},
      ),
    );

    if (result.isEmpty) return null;
    return Company.fromRow(result.first);
  }
}
