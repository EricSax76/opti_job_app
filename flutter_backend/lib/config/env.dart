import 'package:dotenv/dotenv.dart' as dotenv;

class AppEnvironment {
  AppEnvironment._({
    required this.port,
    required this.dbHost,
    required this.dbPort,
    required this.dbName,
    required this.dbUser,
    required this.dbPassword,
    required this.jwtSecret,
  });

  final int port;
  final String dbHost;
  final int dbPort;
  final String dbName;
  final String dbUser;
  final String dbPassword;
  final String jwtSecret;

  static AppEnvironment load({String filename = '.env'}) {
    final env = dotenv.DotEnv()..load([filename]);

    return AppEnvironment._(
      port: int.tryParse(env['PORT'] ?? '') ?? 5001,
      dbHost: env['DB_HOST'] ?? 'localhost',
      dbPort: int.tryParse(env['DB_PORT'] ?? '') ?? 5432,
      dbName: env['DB_NAME'] ?? 'infojobs',
      dbUser: env['DB_USER'] ?? 'postgres',
      dbPassword: env['DB_PASSWORD'] ?? 'postgres',
      jwtSecret: env['JWT_SECRET'] ?? 'change-me',
    );
  }
}
