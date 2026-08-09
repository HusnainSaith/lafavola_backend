import { INestApplication } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import * as request from 'supertest';
import { DataSource } from 'typeorm';
import { GlobalValidationPipe } from '../../src/common/pipes/global-validation.pipe';
import {
  createTestDataSource,
  ensureTestDatabase,
  resetIsolatedTestDatabase,
} from '../utils/test-data-source';

jest.setTimeout(120_000);
const enabled = process.env.RUN_DB_TESTS === 'true';
const httpMethods = new Set(['get', 'post', 'put', 'patch', 'delete']);
const placeholder = '00000000-0000-4000-8000-000000000001';

(enabled ? describe : describe.skip)('Swagger route smoke (PostgreSQL)', () => {
  let app: INestApplication;
  let database: DataSource;

  beforeAll(async () => {
    const testDatabase = await ensureTestDatabase();
    database = createTestDataSource(testDatabase);
    await resetIsolatedTestDatabase(database);
    await database.runMigrations({ transaction: 'each' });
    process.env.NODE_ENV = 'test';
    process.env.DB_DATABASE = testDatabase;
    process.env.MAIL_ENABLED = 'false';
    process.env.AWS_S3_ENABLED = 'false';
    process.env.SUMUP_ENABLED = 'false';
    process.env.AWS_REALTIME_ENABLED = 'false';
    process.env.PUSH_ENABLED = 'false';
    const { AppModule } = await import('../../src/app.module');
    const module = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();
    app = module.createNestApplication();
    app.useGlobalPipes(new GlobalValidationPipe());
    await app.init();
  });

  afterAll(async () => {
    if (app) await app.close();
    if (database?.isInitialized) await database.destroy();
  });

  it('invokes every documented operation without an unexpected internal error', async () => {
    const document = JSON.parse(
      readFileSync(resolve(process.cwd(), 'openapi.json'), 'utf8'),
    ) as {
      security?: Array<Record<string, string[]>>;
      paths: Record<string, Record<string, unknown>>;
    };
    expect(document.security).toContainEqual({ 'JWT-auth': [] });
    const failures: string[] = [];
    let invoked = 0;

    for (const [template, pathItem] of Object.entries(document.paths)) {
      for (const method of Object.keys(pathItem)) {
        if (!httpMethods.has(method)) continue;
        invoked += 1;
        const path = template.replaceAll(/\{[^}]+\}/g, placeholder);
        const call = (request(app.getHttpServer()) as any)
          [method](path)
          .set('Accept', 'application/json')
          .send({});
        const response = await call;
        if (response.status === 500) {
          failures.push(`${method.toUpperCase()} ${template}`);
        }
        expect(JSON.stringify(response.body)).not.toMatch(
          /passwordHash|tokenHash|secretAccessKey|privateKey/i,
        );
      }
    }

    expect(invoked).toBeGreaterThanOrEqual(155);
    expect(failures).toEqual([]);
  });
});
