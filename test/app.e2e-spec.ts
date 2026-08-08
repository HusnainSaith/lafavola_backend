import { INestApplication } from '@nestjs/common';
import { Test, TestingModule } from '@nestjs/testing';
import * as request from 'supertest';
import { AppModule } from './../src/app.module';

describe('AppController (e2e)', () => {
  let app: INestApplication;

  beforeAll(async () => {
    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    app = moduleFixture.createNestApplication();
    await app.init();
  });

  afterAll(async () => {
    await app.close();
  });

  it('allows a public route without JWT', () => {
    return request(app.getHttpServer())
      .get('/')
      .expect(200)
      .expect((response) => {
        expect(response.body.data).toBe('La Favola API');
      });
  });

  it('exposes public liveness and database-backed readiness', async () => {
    await request(app.getHttpServer())
      .get('/health')
      .expect(200)
      .expect(({ body }) => expect(body.data.status).toBe('ok'));
    await request(app.getHttpServer())
      .get('/ready')
      .expect(200)
      .expect(({ body }) => {
        expect(body.data.status).toBe('ready');
        expect(body.data.checks.database).toBe('up');
      });
  });

  it('denies a protected route without JWT', () => {
    return request(app.getHttpServer()).get('/users').expect(401);
  });

  it.each([
    ['GET', '/reports/sales?from=2026-08-01&to=2026-08-02'],
    ['GET', '/deliveries/orders/00000000-0000-0000-0000-000000000001/tracking'],
    ['PATCH', '/deliveries/orders/00000000-0000-0000-0000-000000000001/status'],
    ['POST', '/payments/orders/00000000-0000-0000-0000-000000000001/collect'],
    ['GET', '/customers/me/privacy/requests'],
    [
      'POST',
      '/customers/me/privacy/requests/00000000-0000-0000-0000-000000000001/fulfill',
    ],
  ])('protects %s %s', (method, path) => {
    const call = request(app.getHttpServer())[method.toLowerCase() as 'get'](
      path,
    );
    return call.expect(401);
  });
});
