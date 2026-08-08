import { INestApplication } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import * as request from 'supertest';
import { GlobalValidationPipe } from '../../src/common/pipes/global-validation.pipe';
import { AuthController } from '../../src/modules/auth/auth.controller';
import { AuthService } from '../../src/modules/auth/auth.service';
import { SocialProvider } from '../../src/modules/auth/enums/social-provider.enum';

describe('OAuth HTTP routes', () => {
  let app: INestApplication;
  const auth = { socialLogin: jest.fn() };

  beforeAll(async () => {
    const module = await Test.createTestingModule({
      controllers: [AuthController],
      providers: [{ provide: AuthService, useValue: auth }],
    }).compile();
    app = module.createNestApplication();
    app.useGlobalPipes(new GlobalValidationPipe());
    await app.init();
  });

  beforeEach(() => {
    auth.socialLogin.mockReset().mockResolvedValue({
      success: true,
      data: { accessToken: 'access', refreshToken: 'refresh' },
    });
  });

  afterAll(async () => app.close());

  it.each([
    ['/auth/oauth/google', SocialProvider.GOOGLE],
    ['/auth/oauth/apple', SocialProvider.APPLE],
  ])('accepts POST %s without an API bearer token', async (path, provider) => {
    await request(app.getHttpServer())
      .post(path)
      .send({ idToken: 'provider.identity.token', fullName: 'Mario Rossi' })
      .expect(200)
      .expect(({ body }) => expect(body.success).toBe(true));

    expect(auth.socialLogin).toHaveBeenCalledWith(provider, {
      idToken: 'provider.identity.token',
      fullName: 'Mario Rossi',
    });
  });

  it('rejects an empty identity token before calling the provider', async () => {
    await request(app.getHttpServer())
      .post('/auth/oauth/google')
      .send({ idToken: '' })
      .expect(400);
    expect(auth.socialLogin).not.toHaveBeenCalled();
  });

  it('rejects unknown request fields', async () => {
    await request(app.getHttpServer())
      .post('/auth/oauth/apple')
      .send({ idToken: 'token', provider: 'google' })
      .expect(400);
    expect(auth.socialLogin).not.toHaveBeenCalled();
  });
});
