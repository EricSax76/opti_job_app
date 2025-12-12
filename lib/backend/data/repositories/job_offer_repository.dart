import 'package:infojobs_flutter_app/backend/config/logger.dart';
import 'package:infojobs_flutter_app/backend/data/datasource/database.dart';
import 'package:infojobs_flutter_app/backend/data/models/job_offer.dart';
import 'package:postgres/postgres.dart';

class JobOfferRepository {
  JobOfferRepository(this._db);

  final DatabaseManager _db;

  Future<List<JobOffer>> findAll({String? jobType}) async {
    const sql = '''
      SELECT
        id,
        title,
        description,
        location,
        CASE
          WHEN salary_min IS NULL THEN NULL
          ELSE TO_CHAR(salary_min, 'FM999,999,999') || ' €'
        END AS salary_min,
        CASE
          WHEN salary_max IS NULL THEN NULL
          ELSE TO_CHAR(salary_max, 'FM999,999,999') || ' €'
        END AS salary_max,
        education,
        job_type,
        created_at
      FROM job_offers
      WHERE (@job_type::text IS NULL OR job_type = @job_type)
      ORDER BY id DESC;
    ''';

    final result = await _db.run((session) {
      return session.execute(
        Sql.named(sql),
        parameters: {
          'job_type': jobType,
        },
      );
    });

    return result.map(JobOffer.fromRow).toList();
  }

  Future<JobOffer?> findById(int id) async {
    const sql = '''
      SELECT
        id,
        title,
        description,
        location,
        CASE
          WHEN salary_min IS NULL THEN NULL
          ELSE TO_CHAR(salary_min, 'FM999,999,999') || ' €'
        END AS salary_min,
        CASE
          WHEN salary_max IS NULL THEN NULL
          ELSE TO_CHAR(salary_max, 'FM999,999,999') || ' €'
        END AS salary_max,
        education,
        job_type,
        created_at
      FROM job_offers
      WHERE id = @id
      LIMIT 1;
    ''';

    final result = await _db.run((session) {
      return session.execute(
        Sql.named(sql),
        parameters: {'id': id},
      );
    });

    if (result.isEmpty) return null;
    return JobOffer.fromRow(result.first);
  }

  Future<JobOffer> create({
    required String title,
    required String description,
    required String location,
    num? salaryMin,
    num? salaryMax,
    String? education,
    String? jobType,
  }) async {
    const sql = '''
      INSERT INTO job_offers (
        title,
        description,
        location,
        salary_min,
        salary_max,
        education,
        job_type
      )
      VALUES (
        @title,
        @description,
        @location,
        @salary_min,
        @salary_max,
        @education,
        @job_type
      )
      RETURNING
        id,
        title,
        description,
        location,
        CASE
          WHEN salary_min IS NULL THEN NULL
          ELSE TO_CHAR(salary_min, 'FM999,999,999') || ' €'
        END AS salary_min,
        CASE
          WHEN salary_max IS NULL THEN NULL
          ELSE TO_CHAR(salary_max, 'FM999,999,999') || ' €'
        END AS salary_max,
        education,
        job_type,
        created_at;
    ''';

    final result = await _db.run((session) async {
      try {
        return await session.execute(
          Sql.named(sql),
          parameters: {
            'title': title,
            'description': description,
            'location': location,
            'salary_min': salaryMin,
            'salary_max': salaryMax,
            'education': education,
            'job_type': jobType,
          },
        );
      } catch (error, stackTrace) {
        appLogger.severe('Error al crear oferta', error, stackTrace);
        rethrow;
      }
    });

    return JobOffer.fromRow(result.first);
  }
}
