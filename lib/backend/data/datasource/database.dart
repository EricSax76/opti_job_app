import 'package:postgres/postgres.dart';

import '../../config/env.dart';
import '../../config/logger.dart';

class DatabaseManager {
  DatabaseManager(this._env)
      : _pool = ConnectionPool(
          settings: ConnectionSettings(
            host: _env.dbHost,
            port: _env.dbPort,
            database: _env.dbName,
            user: _env.dbUser,
            password: _env.dbPassword,
            sslMode: SslMode.disable,
          ),
          maxConnectionCount: 5,
        );

  final AppEnvironment _env;
  final ConnectionPool _pool;

  Future<T> run<T>(Future<T> Function(Session session) operation) {
    return _pool.withConnection<T>((connection) async {
      return operation(connection);
    });
  }

  Future<void> close() => _pool.close();

  void logStats() {
    appLogger.info(
      'Pool status -> total: ${_pool.totalConnections}, '
      'idle: ${_pool.availableConnections}, '
      'waiting: ${_pool.waitQueueLength}',
    );
  }
}
