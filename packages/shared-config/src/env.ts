import 'dotenv/config';

type RawConfig = {
  NODE_ENV?: string;
  PORT?: string;
  DATABASE_URL?: string;
  REDIS_URL?: string;
  PGVECTOR_URL?: string;
  JWT_SECRET?: string;
};

export interface AppConfig {
  nodeEnv: 'development' | 'test' | 'production';
  port: number;
  databaseUrl: string;
  redisUrl: string;
  pgvectorUrl?: string;
  jwtSecret: string;
}

const DEFAULTS: Partial<AppConfig> = {
  nodeEnv: 'development',
  port: 3000
};

export function loadConfig(envInput?: RawConfig | NodeJS.ProcessEnv): AppConfig {
  const env = (envInput ?? process.env) as RawConfig;
  const nodeEnv = (env.NODE_ENV ?? DEFAULTS.nodeEnv) as AppConfig['nodeEnv'];
  const databaseUrl =
    env.DATABASE_URL ?? 'postgres://infojobs:infojobs@localhost:5432/infojobs';
  const redisUrl = env.REDIS_URL ?? 'redis://localhost:6379';
  const jwtSecret = env.JWT_SECRET ?? 'dev-secret';
  return {
    nodeEnv,
    port: Number(env.PORT ?? DEFAULTS.port),
    databaseUrl,
    redisUrl,
    pgvectorUrl: env.PGVECTOR_URL,
    jwtSecret
  };
}
