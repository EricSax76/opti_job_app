import 'package:infojobs_flutter_app/backend/config/env.dart';
import 'package:postgres/postgres.dart';

class DatabaseManager {
  DatabaseManager(AppEnvironment env)
      : _pool = Pool.withEndpoints(
          [
            Endpoint(
              host: env.dbHost,
              port: env.dbPort,
              database: env.dbName,
              username: env.dbUser,
              password: env.dbPassword,
            ),
          ],
          settings: const PoolSettings(
            sslMode: SslMode.disable,
            maxConnectionCount: 5,
          ),
        );

  final Pool _pool;

  Future<T> run<T>(Future<T> Function(Session session) operation) {
    return _pool.run(operation);
  }

  Future<void> close() => _pool.close();
}
