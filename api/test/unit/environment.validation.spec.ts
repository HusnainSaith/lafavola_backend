import { validateEnvironment } from '../../src/config/environment.validation';

const valid = {
  NODE_ENV: 'test',
  PORT: '3001',
  DB_HOST: 'localhost',
  DB_PORT: '5432',
  DB_USERNAME: 'postgres',
  DB_PASSWORD: 'secret',
  DB_DATABASE: 'lafavola_test',
  DB_SSL: 'false',
  JWT_SECRET: 'access-secret',
  JWT_EXPIRES_IN: '15m',
  JWT_REFRESH_SECRET: 'refresh-secret',
  JWT_REFRESH_EXPIRES_IN: '30d',
};

describe('validateEnvironment', () => {
  it('parses false without Boolean("false") behavior', () => {
    expect(validateEnvironment(valid).DB_SSL).toBe(false);
  });

  it('fails fast when required configuration is absent', () => {
    expect(() => validateEnvironment({ ...valid, JWT_SECRET: '' })).toThrow(
      'JWT_SECRET',
    );
  });

  it.each([
    ['DB_DATABASE', ''],
    ['JWT_SECRET', ''],
    ['JWT_REFRESH_SECRET', ''],
    ['DB_PORT', 'not-a-port'],
    ['PORT', '70000'],
    ['DB_SSL', 'yes'],
  ])('rejects invalid %s', (key, value) => {
    expect(() => validateEnvironment({ ...valid, [key]: value })).toThrow();
  });

  it('requires SMTP settings only when mail is enabled', () => {
    expect(() =>
      validateEnvironment({ ...valid, MAIL_ENABLED: 'true' }),
    ).toThrow('MAIL_HOST');
    expect(
      validateEnvironment({
        ...valid,
        MAIL_ENABLED: 'true',
        MAIL_HOST: 'smtp.example.com',
        MAIL_PORT: '587',
        MAIL_SECURE: 'false',
        MAIL_USER: 'mailer',
        MAIL_PASSWORD: 'app-password',
        MAIL_FROM_EMAIL: 'no-reply@example.com',
        MAIL_FROM_NAME: 'La Favola',
      }).MAIL_PORT,
    ).toBe(587);
  });

  it('allows IAM credentials and requires only region/bucket for enabled S3', () => {
    expect(() =>
      validateEnvironment({ ...valid, AWS_S3_ENABLED: 'true' }),
    ).toThrow('AWS_REGION');
    expect(
      validateEnvironment({
        ...valid,
        AWS_S3_ENABLED: 'true',
        AWS_REGION: 'eu-south-1',
        AWS_S3_BUCKET: 'lafavola-test',
      }).AWS_S3_BUCKET,
    ).toBe('lafavola-test');
  });

  it('requires SumUp secrets only when enabled and enforces EUR', () => {
    expect(() =>
      validateEnvironment({ ...valid, SUMUP_ENABLED: 'true' }),
    ).toThrow('SUMUP_API_KEY');
    expect(
      validateEnvironment({
        ...valid,
        SUMUP_ENABLED: 'true',
        SUMUP_API_KEY: 'sandbox-secret',
        SUMUP_MERCHANT_CODE: 'MERCHANT1',
        SUMUP_RETURN_URL: 'https://api.example.com/payments/webhooks/sumup',
        SUMUP_HOSTED_CHECKOUT_ENABLED: 'true',
      }).SUMUP_CURRENCY,
    ).toBe('EUR');
    expect(() =>
      validateEnvironment({ ...valid, SUMUP_CURRENCY: 'USD' }),
    ).toThrow('SUMUP_CURRENCY');
  });

  it('validates AppSync and Firebase credentials only when enabled', () => {
    expect(() =>
      validateEnvironment({ ...valid, AWS_REALTIME_ENABLED: 'true' }),
    ).toThrow('AWS_APPSYNC_EVENTS_HTTP_URL');
    expect(() =>
      validateEnvironment({ ...valid, PUSH_ENABLED: 'true' }),
    ).toThrow('FIREBASE_PROJECT_ID');
    expect(
      validateEnvironment({
        ...valid,
        PUSH_ENABLED: 'true',
        FIREBASE_PROJECT_ID: 'project',
        FIREBASE_CLIENT_EMAIL: 'firebase@example.com',
        FIREBASE_PRIVATE_KEY: 'private-key',
      }).PUSH_ENABLED,
    ).toBe(true);
  });

  it('validates safe worker polling bounds', () => {
    expect(validateEnvironment(valid).WORKER_BATCH_SIZE).toBe(20);
    expect(() =>
      validateEnvironment({ ...valid, WORKER_POLL_INTERVAL_MS: '1' }),
    ).toThrow('WORKER_POLL_INTERVAL_MS');
    expect(() =>
      validateEnvironment({ ...valid, WORKER_BATCH_SIZE: '0' }),
    ).toThrow('WORKER_BATCH_SIZE');
  });

  it('starts with every optional provider disabled and no provider secrets', () => {
    const config = validateEnvironment({
      ...valid,
      MAIL_ENABLED: 'false',
      AWS_S3_ENABLED: 'false',
      SUMUP_ENABLED: 'false',
      AWS_REALTIME_ENABLED: 'false',
      PUSH_ENABLED: 'false',
    });
    expect(config).toMatchObject({
      MAIL_ENABLED: false,
      AWS_S3_ENABLED: false,
      SUMUP_ENABLED: false,
      AWS_REALTIME_ENABLED: false,
      PUSH_ENABLED: false,
    });
  });
});
