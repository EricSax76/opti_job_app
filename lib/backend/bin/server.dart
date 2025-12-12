import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';

import 'package:infojobs_flutter_app/backend/config/env.dart';
import 'package:infojobs_flutter_app/backend/config/logger.dart';
import 'package:infojobs_flutter_app/backend/data/datasource/database.dart';
import 'package:infojobs_flutter_app/backend/data/repositories/candidate_repository.dart';
import 'package:infojobs_flutter_app/backend/data/repositories/company_repository.dart';
import 'package:infojobs_flutter_app/backend/data/repositories/job_offer_repository.dart';
import 'package:infojobs_flutter_app/backend/features/candidates/candidates_router.dart';
import 'package:infojobs_flutter_app/backend/features/companies/companies_router.dart';
import 'package:infojobs_flutter_app/backend/features/job_offers/job_offers_router.dart';
import 'package:infojobs_flutter_app/backend/middleware/cors.dart';
import 'package:infojobs_flutter_app/backend/middleware/logging.dart';
import 'package:infojobs_flutter_app/backend/utils/response.dart';

Future<void> main(List<String> args) async {
  configureLogging();
  final env = AppEnvironment.load();
  final db = DatabaseManager(env);

  final jobOfferRepository = JobOfferRepository(db);
  final candidatesRepository = CandidateRepository(db);
  final companiesRepository = CompanyRepository(db);

  final router = Router()
    ..get('/', (request) => jsonResponse({'status': 'ok'}))
    ..mount(
      '/api/job_offers/',
      JobOffersRouter(jobOfferRepository).router.call,
    )
    ..mount(
      '/api/candidates/',
      CandidatesRouter(
        candidatesRepository,
        jwtSecret: env.jwtSecret,
      ).router.call,
    )
    ..mount(
      '/api/companies/',
      CompaniesRouter(
        companiesRepository,
        jwtSecret: env.jwtSecret,
      ).router.call,
    );

  final handler = const Pipeline()
      .addMiddleware(requestLoggingMiddleware())
      .addMiddleware(createCorsMiddleware())
      .addHandler(router.call);

  final server = await shelf_io.serve(
    handler,
    InternetAddress.anyIPv4,
    env.port,
  );

  appLogger.info(
    'Servidor iniciado en http://${server.address.address}:${server.port}',
  );

  // Manejo básico de señales para cierre ordenado
  ProcessSignal.sigint.watch().listen((signal) async {
    appLogger.info('Recibida señal $signal, cerrando servidor...');
    await server.close();
    await db.close();
    exit(0);
  });
}
