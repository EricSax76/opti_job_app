import 'package:postgres/postgres.dart';

import '../../config/env.dart';
import '../../config/logger.dart';

class DatabaseManager {
  DatabaseManager(
    AppEnvironment env, {
    int maxConnections = 5,
  })  : _maxConnections = maxConnections,
        _pool = Pool.withEndpoints(
          [
            Endpoint(
              host: env.dbHost,
              port: env.dbPort,
              database: env.dbName,
              username: env.dbUser,
              password: env.dbPassword,
            ),
          ],
          settings: PoolSettings(
            maxConnectionCount: maxConnections,
            sslMode: SslMode.disable,
          ),
        );

  final Pool _pool;
  final int _maxConnections;

  Future<T> run<T>(Future<T> Function(Session session) operation) {
    return _pool.run(operation);
  }

  Future<void> close() => _pool.close();

  void logStats() {
    appLogger.info(
      'Pool initialized. Max connections: $_maxConnections. '
      'Detailed statistics are unavailable with the current postgres Pool API.',
    );
  }
}
