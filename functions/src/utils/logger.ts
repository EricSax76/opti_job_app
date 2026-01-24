/**
 * Structured logging utility for Cloud Functions
 */

type LogLevel = "DEBUG" | "INFO" | "WARN" | "ERROR";

interface LogContext {
  [key: string]: unknown;
}

class Logger {
  private context: LogContext;

  constructor(context: LogContext = {}) {
    this.context = context;
  }

  private log(level: LogLevel, message: string, data?: LogContext) {
    const logEntry = {
      severity: level,
      message,
      timestamp: new Date().toISOString(),
      ...this.context,
      ...data,
    };

    console.log(JSON.stringify(logEntry));
  }

  debug(message: string, data?: LogContext) {
    this.log("DEBUG", message, data);
  }

  info(message: string, data?: LogContext) {
    this.log("INFO", message, data);
  }

  warn(message: string, data?: LogContext) {
    this.log("WARN", message, data);
  }

  error(message: string, error?: Error | unknown, data?: LogContext) {
    const errorData = error instanceof Error ?
      {
        error: {
          message: error.message,
          stack: error.stack,
          name: error.name,
        },
        ...data,
      } :
      { error, ...data };

    this.log("ERROR", message, errorData);
  }

  withContext(additionalContext: LogContext): Logger {
    return new Logger({ ...this.context, ...additionalContext });
  }
}

export const logger = new Logger();

export function createLogger(context: LogContext): Logger {
  return new Logger(context);
}
