import type { Provider } from '@nestjs/common';
import type { AppConfig } from '@infojobs/shared-config';
import { loadConfig } from '@infojobs/shared-config';

export const APP_CONFIG = Symbol('APP_CONFIG');

export const AppConfigProvider: Provider<AppConfig> = {
  provide: APP_CONFIG,
  useFactory: () => loadConfig()
};
