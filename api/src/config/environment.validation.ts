const ENVIRONMENTS = new Set(['development', 'test', 'production']);

function required(config: Record<string, unknown>, key: string): string {
  const value = String(config[key] ?? '').trim();
  if (!value) throw new Error(`Missing required environment variable: ${key}`);
  return value;
}

function integer(value: string, key: string, min: number, max: number): number {
  const parsed = Number(value);
  if (!Number.isInteger(parsed) || parsed < min || parsed > max) {
    throw new Error(`${key} must be an integer between ${min} and ${max}`);
  }
  return parsed;
}

function boolean(value: unknown, key: string): boolean {
  if (value === true || value === 'true') return true;
  if (
    value === false ||
    value === 'false' ||
    value === undefined ||
    value === ''
  )
    return false;
  throw new Error(`${key} must be true or false`);
}

function absoluteHttpUrl(value: string, key: string): string {
  try {
    const parsed = new URL(value);
    if (!['http:', 'https:'].includes(parsed.protocol)) throw new Error();
    return parsed.toString();
  } catch {
    throw new Error(`${key} must be an absolute HTTP(S) URL`);
  }
}

export function validateEnvironment(input: Record<string, unknown>) {
  const config = { ...input };
  const nodeEnv = String(config.NODE_ENV ?? 'development');
  if (!ENVIRONMENTS.has(nodeEnv)) throw new Error('NODE_ENV is invalid');
  config.NODE_ENV = nodeEnv;
  config.PORT = integer(String(config.PORT ?? '3001'), 'PORT', 1, 65535);
  config.DB_HOST = required(config, 'DB_HOST');
  config.DB_PORT = integer(required(config, 'DB_PORT'), 'DB_PORT', 1, 65535);
  config.DB_USERNAME = required(config, 'DB_USERNAME');
  config.DB_PASSWORD = required(config, 'DB_PASSWORD');
  config.DB_DATABASE = required(config, 'DB_DATABASE');
  config.DB_SSL = boolean(config.DB_SSL, 'DB_SSL');
  config.JWT_SECRET = required(config, 'JWT_SECRET');
  config.JWT_EXPIRES_IN = required(config, 'JWT_EXPIRES_IN');
  config.JWT_REFRESH_SECRET = required(config, 'JWT_REFRESH_SECRET');
  config.JWT_REFRESH_EXPIRES_IN = required(config, 'JWT_REFRESH_EXPIRES_IN');
  config.MAIL_ENABLED = boolean(config.MAIL_ENABLED, 'MAIL_ENABLED');
  const mailProvider = String(config.MAIL_PROVIDER ?? 'smtp').toLowerCase();
  if (!['smtp', 'ses'].includes(mailProvider)) {
    throw new Error('MAIL_PROVIDER must be smtp or ses');
  }
  config.MAIL_PROVIDER = mailProvider;
  if (config.MAIL_ENABLED) {
    if (mailProvider === 'smtp') {
      config.MAIL_HOST = required(config, 'MAIL_HOST');
      config.MAIL_PORT = integer(
        required(config, 'MAIL_PORT'),
        'MAIL_PORT',
        1,
        65535,
      );
      config.MAIL_SECURE = boolean(config.MAIL_SECURE, 'MAIL_SECURE');
      config.MAIL_USER = required(config, 'MAIL_USER');
      config.MAIL_PASSWORD = required(config, 'MAIL_PASSWORD');
    } else {
      config.AWS_SES_REGION = required(config, 'AWS_SES_REGION');
    }
    config.MAIL_FROM_EMAIL = required(config, 'MAIL_FROM_EMAIL');
    config.MAIL_FROM_NAME = required(config, 'MAIL_FROM_NAME');
  }
  config.PASSWORD_RESET_URL = absoluteHttpUrl(
    nodeEnv === 'production'
      ? required(config, 'PASSWORD_RESET_URL')
      : String(
          config.PASSWORD_RESET_URL ?? 'http://localhost:3000/reset-password',
        ),
    'PASSWORD_RESET_URL',
  );
  config.EMAIL_VERIFICATION_URL = absoluteHttpUrl(
    nodeEnv === 'production'
      ? required(config, 'EMAIL_VERIFICATION_URL')
      : String(
          config.EMAIL_VERIFICATION_URL ?? 'http://localhost:3000/verify-email',
        ),
    'EMAIL_VERIFICATION_URL',
  );
  config.AWS_S3_ENABLED = boolean(config.AWS_S3_ENABLED, 'AWS_S3_ENABLED');
  if (config.AWS_S3_ENABLED) {
    config.AWS_REGION = required(config, 'AWS_REGION');
    config.AWS_S3_BUCKET = required(config, 'AWS_S3_BUCKET');
  }
  config.SUMUP_ENABLED = boolean(config.SUMUP_ENABLED, 'SUMUP_ENABLED');
  config.SUMUP_API_BASE_URL = absoluteHttpUrl(
    String(config.SUMUP_API_BASE_URL ?? 'https://api.sumup.com'),
    'SUMUP_API_BASE_URL',
  ).replace(/\/$/, '');
  config.SUMUP_CURRENCY = String(config.SUMUP_CURRENCY ?? 'EUR');
  if (config.SUMUP_CURRENCY !== 'EUR') {
    throw new Error('SUMUP_CURRENCY must be EUR');
  }
  config.SUMUP_HOSTED_CHECKOUT_ENABLED = boolean(
    config.SUMUP_HOSTED_CHECKOUT_ENABLED,
    'SUMUP_HOSTED_CHECKOUT_ENABLED',
  );
  config.SUMUP_REQUEST_TIMEOUT_MS = integer(
    String(config.SUMUP_REQUEST_TIMEOUT_MS ?? '10000'),
    'SUMUP_REQUEST_TIMEOUT_MS',
    1000,
    60000,
  );
  if (config.SUMUP_ENABLED) {
    config.SUMUP_API_KEY = required(config, 'SUMUP_API_KEY');
    config.SUMUP_MERCHANT_CODE = required(config, 'SUMUP_MERCHANT_CODE');
    config.SUMUP_RETURN_URL = absoluteHttpUrl(
      required(config, 'SUMUP_RETURN_URL'),
      'SUMUP_RETURN_URL',
    );
  }
  config.AWS_REALTIME_ENABLED = boolean(
    config.AWS_REALTIME_ENABLED,
    'AWS_REALTIME_ENABLED',
  );
  config.AWS_REALTIME_TIMEOUT_MS = integer(
    String(config.AWS_REALTIME_TIMEOUT_MS ?? '5000'),
    'AWS_REALTIME_TIMEOUT_MS',
    1000,
    30000,
  );
  if (config.AWS_REALTIME_ENABLED) {
    config.AWS_APPSYNC_EVENTS_HTTP_URL = absoluteHttpUrl(
      required(config, 'AWS_APPSYNC_EVENTS_HTTP_URL'),
      'AWS_APPSYNC_EVENTS_HTTP_URL',
    );
    config.AWS_APPSYNC_EVENTS_WS_URL = required(
      config,
      'AWS_APPSYNC_EVENTS_WS_URL',
    );
    config.AWS_APPSYNC_EVENTS_API_KEY = required(
      config,
      'AWS_APPSYNC_EVENTS_API_KEY',
    );
  }
  config.PUSH_ENABLED = boolean(config.PUSH_ENABLED, 'PUSH_ENABLED');
  if (config.PUSH_ENABLED) {
    config.FIREBASE_PROJECT_ID = required(config, 'FIREBASE_PROJECT_ID');
    config.FIREBASE_CLIENT_EMAIL = required(config, 'FIREBASE_CLIENT_EMAIL');
    config.FIREBASE_PRIVATE_KEY = required(config, 'FIREBASE_PRIVATE_KEY');
  }
  config.WORKER_POLL_INTERVAL_MS = integer(
    String(config.WORKER_POLL_INTERVAL_MS ?? '2000'),
    'WORKER_POLL_INTERVAL_MS',
    100,
    60000,
  );
  config.WORKER_BATCH_SIZE = integer(
    String(config.WORKER_BATCH_SIZE ?? '20'),
    'WORKER_BATCH_SIZE',
    1,
    500,
  );
  config.WORKER_CLAIM_TIMEOUT_MS = integer(
    String(config.WORKER_CLAIM_TIMEOUT_MS ?? '300000'),
    'WORKER_CLAIM_TIMEOUT_MS',
    10000,
    3600000,
  );
  return config;
}
