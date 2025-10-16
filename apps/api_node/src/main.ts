import 'reflect-metadata';
import { NestFactory } from '@nestjs/core';
import { Logger, ValidationPipe } from '@nestjs/common';

import { AppModule } from './app.module.js';
import { APP_CONFIG } from './common/config/app-config.provider.js';
import type { AppConfig } from '@infojobs/shared-config';

async function bootstrap() {
  const app = await NestFactory.create(AppModule, { cors: true });
  app.setGlobalPrefix('api');
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: true,
      transform: true
    })
  );

  const config = app.get<AppConfig>(APP_CONFIG);
  const logger = new Logger('Bootstrap');

  await app.listen(config.port);
  logger.log(`API Gateway listening on port ${config.port}`);
}

bootstrap().catch((error) => {
  // eslint-disable-next-line no-console
  console.error('Failed to bootstrap API', error);
  process.exit(1);
});
