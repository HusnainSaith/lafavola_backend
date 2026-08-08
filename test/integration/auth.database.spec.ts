import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import { UnauthorizedException } from '@nestjs/common';
import { DataSource, Repository } from 'typeorm';
import { AuthService } from '../../src/modules/auth/auth.service';
import { RefreshToken } from '../../src/modules/auth/entities/refresh-token.entity';
import { VerificationToken } from '../../src/modules/auth/entities/verification-token.entity';
import { SocialAccount } from '../../src/modules/auth/entities/social-account.entity';
import { SocialProvider } from '../../src/modules/auth/enums/social-provider.enum';
import { Role } from '../../src/modules/roles/entities/role.entity';
import { RoleEnum } from '../../src/modules/roles/role.enum';
import { Permission } from '../../src/modules/permissions/entities/permission.entity';
import { UserPermission } from '../../src/modules/users/entities/user-permission.entity';
import { User } from '../../src/modules/users/entities/user.entity';
import { UserStatus } from '../../src/modules/users/enums/user-status.enum';
import { UsersService } from '../../src/modules/users/users.service';
import {
  createTestDataSource,
  ensureTestDatabase,
} from '../utils/test-data-source';

jest.setTimeout(120000);
const enabled = process.env.RUN_DB_TESTS === 'true';

(enabled ? describe : describe.skip)(
  'database-backed authentication security',
  () => {
    let dataSource: DataSource;
    let auth: AuthService;
    let delivery: { sendPasswordReset: jest.Mock };
    let mail: { send: jest.Mock };
    let users: Repository<User>;
    let socialIdentityVerifier: { verify: jest.Mock };

    beforeAll(async () => {
      const database = await ensureTestDatabase();
      dataSource = createTestDataSource(database);
      await dataSource.initialize();
      if (await dataSource.showMigrations()) await dataSource.runMigrations();
    });

    beforeEach(async () => {
      await dataSource.query(
        'TRUNCATE TABLE verification_tokens, refresh_tokens, users, roles CASCADE',
      );
      const roles = dataSource.getRepository(Role);
      await roles.save([
        roles.create({ name: RoleEnum.CLIENT, isSystem: true }),
        roles.create({ name: RoleEnum.ADMIN, isSystem: true }),
      ]);
      const usersService = new UsersService(
        dataSource.getRepository(User),
        roles,
        dataSource.getRepository(Permission),
        dataSource.getRepository(UserPermission),
      );
      delivery = { sendPasswordReset: jest.fn().mockResolvedValue(undefined) };
      mail = { send: jest.fn().mockResolvedValue({}) };
      socialIdentityVerifier = { verify: jest.fn() };
      auth = new AuthService(
        usersService,
        new JwtService(),
        new ConfigService({
          JWT_SECRET: 'test-access-secret',
          JWT_EXPIRES_IN: '15m',
          JWT_REFRESH_TTL_DAYS: '30',
          EMAIL_VERIFICATION_URL: 'http://localhost/verify-email',
        }),
        dataSource,
        roles,
        dataSource.getRepository(RefreshToken),
        dataSource.getRepository(VerificationToken),
        delivery,
        mail,
        socialIdentityVerifier,
      );
      users = dataSource.getRepository(User);
    });

    afterAll(async () => {
      if (dataSource?.isInitialized) await dataSource.destroy();
    });

    async function register(email: string) {
      return auth.register({
        fullName: 'Test Customer',
        email,
        password: 'SecurePass1',
      });
    }

    it('creates a customer and reusable refresh session from verified Google identity', async () => {
      socialIdentityVerifier.verify.mockResolvedValue({
        subject: 'google-subject-1',
        email: 'oauth@example.com',
        emailVerified: true,
        fullName: 'OAuth Customer',
      });

      const first = await auth.socialLogin(SocialProvider.GOOGLE, {
        idToken: 'google-token',
      });
      const second = await auth.socialLogin(SocialProvider.GOOGLE, {
        idToken: 'google-token-again',
      });

      expect(first.data.user.id).toBe(second.data.user.id);
      expect(first.data.accessToken).toBeTruthy();
      expect(first.data.refreshToken).toBeTruthy();
      await expect(
        auth.refreshToken({ refreshToken: first.data.refreshToken }),
      ).resolves.toBeDefined();
      expect(await users.countBy({ email: 'oauth@example.com' })).toBe(1);
      expect(
        await dataSource.getRepository(SocialAccount).countBy({
          provider: SocialProvider.GOOGLE,
          providerSubject: 'google-subject-1',
        }),
      ).toBe(1);
    });

    it('links a verified Apple identity to an existing account without duplicating it', async () => {
      await register('linked@example.com');
      const existing = await users.findOneByOrFail({
        email: 'linked@example.com',
      });
      socialIdentityVerifier.verify.mockResolvedValue({
        subject: 'apple-subject-1',
        email: 'LINKED@example.com',
        emailVerified: true,
      });

      const result = await auth.socialLogin(SocialProvider.APPLE, {
        idToken: 'apple-token',
        fullName: 'Ignored Name',
      });

      expect(result.data.user.id).toBe(existing.id);
      expect(await users.countBy({ email: 'linked@example.com' })).toBe(1);
    });

    it('requires a verified email when the social identity is not linked yet', async () => {
      socialIdentityVerifier.verify.mockResolvedValue({
        subject: 'new-apple-subject',
        emailVerified: false,
      });
      await expect(
        auth.socialLogin(SocialProvider.APPLE, { idToken: 'apple-token' }),
      ).rejects.toThrow('A verified email is required');
    });

    it('persists refresh digests, rotates them, rejects reuse, and logs out', async () => {
      await register('refresh@example.com');
      const login = await auth.login({
        email: 'refresh@example.com',
        password: 'SecurePass1',
      });
      const first = login.data.refreshToken;
      const rows = await dataSource.query('SELECT token FROM refresh_tokens');
      expect(rows[0].token).not.toBe(first);
      expect(rows[0].token).toHaveLength(64);

      const rotated = await auth.refreshToken({ refreshToken: first });
      await expect(
        auth.refreshToken({ refreshToken: first }),
      ).rejects.toBeInstanceOf(UnauthorizedException);
      await expect(
        auth.refreshToken({ refreshToken: rotated.data.refreshToken }),
      ).resolves.toBeDefined();

      const current = await auth.login({
        email: 'refresh@example.com',
        password: 'SecurePass1',
      });
      const user = await users.findOneByOrFail({
        email: 'refresh@example.com',
      });
      await expect(
        auth.logout(
          '00000000-0000-0000-0000-000000000000',
          current.data.refreshToken,
        ),
      ).rejects.toBeInstanceOf(UnauthorizedException);
      await auth.logout(user.id, current.data.refreshToken);
      await expect(
        auth.refreshToken({ refreshToken: current.data.refreshToken }),
      ).rejects.toBeInstanceOf(UnauthorizedException);
    });

    it('uses one-time reset tokens, changes password, and revokes sessions', async () => {
      await register('reset@example.com');
      const login = await auth.login({
        email: 'reset@example.com',
        password: 'SecurePass1',
      });
      const generic = await auth.requestPasswordReset({
        email: 'reset@example.com',
      });
      const unknown = await auth.requestPasswordReset({
        email: 'absent@example.com',
      });
      expect(unknown).toEqual(generic);

      const raw = delivery.sendPasswordReset.mock.calls[0][1];
      const stored = await dataSource
        .getRepository(VerificationToken)
        .createQueryBuilder('token')
        .addSelect('token.tokenHash')
        .where('token.type = :type', { type: 'password_reset' })
        .getOneOrFail();
      expect(stored.tokenHash).not.toBe(raw);

      await auth.resetPassword({ token: raw, password: 'ChangedPass1' });
      await expect(
        auth.resetPassword({ token: raw, password: 'ChangedAgain1' }),
      ).rejects.toBeInstanceOf(UnauthorizedException);
      await expect(
        auth.refreshToken({ refreshToken: login.data.refreshToken }),
      ).rejects.toBeInstanceOf(UnauthorizedException);
      await expect(
        auth.login({ email: 'reset@example.com', password: 'ChangedPass1' }),
      ).resolves.toBeDefined();
    });

    it('rejects expired and already-consumed reset tokens', async () => {
      await register('expiry@example.com');
      await auth.requestPasswordReset({ email: 'expiry@example.com' });
      const raw = delivery.sendPasswordReset.mock.calls[0][1];
      await dataSource.query(
        "UPDATE verification_tokens SET expires_at = NOW() - INTERVAL '1 minute'",
      );
      await expect(
        auth.resetPassword({ token: raw, password: 'ChangedPass1' }),
      ).rejects.toBeInstanceOf(UnauthorizedException);
    });

    it('stores email verification as a digest and consumes it once', async () => {
      await register('verify@example.com');
      const message = mail.send.mock.calls[0][0] as { text: string };
      const raw = new URL(
        message.text.match(/https?:\/\/\S+/)?.[0] ?? '',
      ).searchParams.get('token');
      expect(raw).toBeTruthy();
      const token = await dataSource
        .getRepository(VerificationToken)
        .findOneByOrFail({
          type: 'email_verify',
        });
      expect(token.tokenHash).not.toBe(raw);
      await auth.verifyEmail(raw!);
      await expect(auth.verifyEmail(raw!)).rejects.toBeInstanceOf(
        UnauthorizedException,
      );
      expect(
        (await users.findOneByOrFail({ email: 'verify@example.com' }))
          .emailVerifiedAt,
      ).toBeInstanceOf(Date);
    });

    it.each([
      UserStatus.PENDING_VERIFICATION,
      UserStatus.SUSPENDED,
      UserStatus.DISABLED,
      UserStatus.DELETED,
    ])('rejects %s accounts', async (status) => {
      await register(`${status}@example.com`);
      await users.update({ email: `${status}@example.com` }, { status });
      await expect(
        auth.login({ email: `${status}@example.com`, password: 'SecurePass1' }),
      ).rejects.toBeInstanceOf(UnauthorizedException);
    });

    it('rejects archived accounts', async () => {
      await register('archived@example.com');
      await users.update(
        { email: 'archived@example.com' },
        { archivedAt: new Date() },
      );
      await expect(
        auth.login({ email: 'archived@example.com', password: 'SecurePass1' }),
      ).rejects.toBeInstanceOf(UnauthorizedException);
    });
  },
);
