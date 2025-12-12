import 'package:infojobs_flutter_app/backend/config/logger.dart';
import 'package:infojobs_flutter_app/backend/data/datasource/database.dart';
import 'package:infojobs_flutter_app/backend/data/models/candidate.dart';
import 'package:infojobs_flutter_app/backend/data/models/user.dart';
import 'package:postgres/postgres.dart';

class CandidateRepository {
  CandidateRepository(this._db);

  final DatabaseManager _db;

  Future<Candidate> createCandidate({
    required String name,
    required String email,
    required String passwordHash,
  }) async {
    const insertUserSql = '''
      INSERT INTO users (name, email, password_hash, role)
      VALUES (@name, @email, @password_hash, 'candidate')
      RETURNING id, name, email, role, password_hash;
    ''';

    const insertCandidateSql = '''
      INSERT INTO candidates (user_id)
      VALUES (@user_id)
      RETURNING id;
    ''';

    const selectCandidateSql = '''
      SELECT
        c.id AS candidate_id,
        u.id AS user_id,
        u.name,
        u.email,
        u.role
      FROM candidates c
      JOIN users u ON c.user_id = u.id
      WHERE c.id = @candidate_id
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
        final candidateResult = await session.execute(
          Sql.named(insertCandidateSql),
          parameters: {'user_id': user.id},
        );
        final candidateId = candidateResult.first.toColumnMap()['id'];

        final candidateRows = await session.execute(
          Sql.named(selectCandidateSql),
          parameters: {'candidate_id': candidateId},
        );

        await session.execute('COMMIT;');
        return Candidate.fromRow(candidateRows.first);
      } catch (error, stackTrace) {
        await session.execute('ROLLBACK;');
        appLogger.severe('Error al registrar candidato', error, stackTrace);
        rethrow;
      }
    });
  }

  Future<User?> findUserByEmail(String email) async {
    const sql = '''
      SELECT id, name, email, role, password_hash
      FROM users
      WHERE email = @email AND role = 'candidate'
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

  Future<Candidate?> findCandidateByUserId(int userId) async {
    const sql = '''
      SELECT
        c.id AS candidate_id,
        u.id AS user_id,
        u.name,
        u.email,
        u.role
      FROM candidates c
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
    return Candidate.fromRow(result.first);
  }

  Future<List<Candidate>> findAll() async {
    const sql = '''
      SELECT
        c.id AS candidate_id,
        u.id AS user_id,
        u.name,
        u.email,
        u.role
      FROM candidates c
      JOIN users u ON c.user_id = u.id
      ORDER BY c.id DESC;
    ''';

    final result = await _db.run(
      (session) => session.execute(Sql.named(sql)),
    );

    return result.map<Candidate>(Candidate.fromRow).toList();
  }

  Future<Candidate?> findById(int id) async {
    const sql = '''
      SELECT
        c.id AS candidate_id,
        u.id AS user_id,
        u.name,
        u.email,
        u.role
      FROM candidates c
      JOIN users u ON c.user_id = u.id
      WHERE c.id = @id
      LIMIT 1;
    ''';

    final result = await _db.run(
      (session) => session.execute(
        Sql.named(sql),
        parameters: {'id': id},
      ),
    );

    if (result.isEmpty) return null;
    return Candidate.fromRow(result.first);
  }
}
