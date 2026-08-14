import { UnauthorizedException } from '@nestjs/common';
import * as bcrypt from 'bcryptjs';
import { plainToInstance } from 'class-transformer';
import { validate } from 'class-validator';
import { AuthService } from '../../src/modules/auth/auth.service';
import { AuthUserResponseDto } from '../../src/modules/auth/dto/auth-user-response.dto';
import { RegisterDto } from '../../src/modules/auth/dto/register.dto';
import { UserStatus } from '../../src/modules/users/enums/user-status.enum';

function fixture() {
  const users = {
    create: jest.fn(),
    findByEmail: jest.fn(),
    findOne: jest.fn(),
  };
  const jwt = { signAsync: jest.fn().mockResolvedValue('access') };
  const config = {
    getOrThrow: jest.fn((key: string) =>
      key === 'EMAIL_VERIFICATION_URL'
        ? 'http://localhost/verify-email'
        : 'secret',
    ),
    get: jest.fn((_key: string, fallback: unknown) => fallback),
  };
  const dataSource = { transaction: jest.fn() };
  const roles = { findOne: jest.fn() };
  const refreshTokens = {
    create: jest.fn((value) => value),
    save: jest.fn().mockResolvedValue(undefined),
    createQueryBuilder: jest.fn(),
  };
  const verificationTokens = {
    create: jest.fn((value) => value),
    save: jest.fn().mockResolvedValue(undefined),
    createQueryBuilder: jest.fn(() => ({
      update: jest.fn().mockReturnThis(),
      set: jest.fn().mockReturnThis(),
      where: jest.fn().mockReturnThis(),
      andWhere: jest.fn().mockReturnThis(),
      execute: jest.fn().mockResolvedValue({ affected: 0 }),
    })),
  };
  const delivery = {
    sendPasswordReset: jest.fn().mockResolvedValue(undefined),
  };
  const mail = { send: jest.fn().mockResolvedValue({}) };
  const socialIdentityVerifier = { verify: jest.fn() };
  const service = new AuthService(
    users as never,
    jwt as never,
    config as never,
    dataSource as never,
    roles as never,
    refreshTokens as never,
    verificationTokens as never,
    delivery,
    mail,
    socialIdentityVerifier,
  );
  return {
    service,
    users,
    roles,
    refreshTokens,
    verificationTokens,
    delivery,
    mail,
    socialIdentityVerifier,
  };
}

describe('P0 authentication security', () => {
  it('rejects privileged fields from public registration input', async () => {
    const dto = plainToInstance(RegisterDto, {
      fullName: 'Mario Rossi',
      email: 'mario@example.com',
      password: 'SecurePass1',
      roleId: 'e5cfbf82-c225-4a38-81bd-b8d947a532ce',
      isAdmin: true,
    });
    const errors = await validate(dto, {
      whitelist: true,
      forbidNonWhitelisted: true,
    });
    expect(errors.map((error) => error.property)).toEqual(
      expect.arrayContaining(['roleId', 'isAdmin']),
    );
  });

  it('serializes only explicitly safe user fields', () => {
    const result = AuthUserResponseDto.from({
      id: 'user-id',
      email: 'mario@example.com',
      fullName: 'Mario Rossi',
      status: UserStatus.ACTIVE,
      password: 'hash',
      refreshTokens: [{ tokenHash: 'digest' }],
    } as never) as unknown as Record<string, unknown>;
    expect(result).not.toHaveProperty('password');
    expect(result).not.toHaveProperty('passwordHash');
    expect(result).not.toHaveProperty('refreshToken');
    expect(result).not.toHaveProperty('resetToken');
    expect(result).not.toHaveProperty('verificationToken');
  });

  it.each([
    UserStatus.PENDING_VERIFICATION,
    UserStatus.SUSPENDED,
    UserStatus.DISABLED,
    UserStatus.DELETED,
  ])('denies login for %s accounts', async (status) => {
    const { service, users } = fixture();
    users.findByEmail.mockResolvedValue({
      status,
      password: '$2a$10$invalid',
      archivedAt: null,
    });
    await expect(
      service.login({ email: 'mario@example.com', password: 'SecurePass1' }),
    ).rejects.toBeInstanceOf(UnauthorizedException);
  });

  it('logs in an active account and persists only a refresh digest', async () => {
    const { service, users, refreshTokens } = fixture();
    users.findByEmail.mockResolvedValue({
      id: 'user-id',
      email: 'mario@example.com',
      fullName: 'Mario Rossi',
      status: UserStatus.ACTIVE,
      emailVerifiedAt: new Date(),
      password: await bcrypt.hash('SecurePass1', 4),
    });
    const result = await service.login({
      email: 'mario@example.com',
      password: 'SecurePass1',
    });
    const persisted = refreshTokens.create.mock.calls[0][0];
    expect(result.data.refreshToken).not.toBe(persisted.tokenHash);
    expect(persisted.tokenHash).toHaveLength(64);
    expect(result.data.user).not.toHaveProperty('password');
  });

  it('denies a correct password until the email is verified', async () => {
    const { service, users, refreshTokens } = fixture();
    users.findByEmail.mockResolvedValue({
      id: 'user-id',
      email: 'mario@example.com',
      status: UserStatus.PENDING_VERIFICATION,
      password: await bcrypt.hash('SecurePass1', 4),
    });

    await expect(
      service.login({ email: 'mario@example.com', password: 'SecurePass1' }),
    ).rejects.toThrow('Please verify your email before signing in');
    expect(refreshTokens.save).not.toHaveBeenCalled();
  });

  it('assigns the client role server-side and returns a safe response', async () => {
    const { service, users, roles } = fixture();
    roles.findOne.mockResolvedValue({ id: 'client-role', name: 'client' });
    users.create.mockResolvedValue({
      data: {
        id: 'user-id',
        email: 'mario@example.com',
        fullName: 'Mario Rossi',
        status: UserStatus.ACTIVE,
        password: 'hash',
      },
    });
    const result = await service.register({
      fullName: 'Mario Rossi',
      email: 'mario@example.com',
      password: 'SecurePass1',
    });
    expect(users.create).toHaveBeenCalledWith(
      expect.objectContaining({
        roleId: 'client-role',
        status: UserStatus.PENDING_VERIFICATION,
      }),
    );
    expect(result.user).not.toHaveProperty('password');
  });

  it('does not report registration as failed when verification email delivery fails', async () => {
    const { service, users, roles, mail } = fixture();
    roles.findOne.mockResolvedValue({ id: 'client-role', name: 'client' });
    users.create.mockResolvedValue({
      data: {
        id: 'user-id',
        email: 'mario@example.com',
        fullName: 'Mario Rossi',
        status: UserStatus.ACTIVE,
      },
    });
    mail.send.mockRejectedValue(new Error('provider unavailable'));

    await expect(
      service.register({
        fullName: 'Mario Rossi',
        email: 'mario@example.com',
        password: 'SecurePass1',
      }),
    ).resolves.toMatchObject({ success: true });
  });

  it('returns the same forgot-password response for unknown accounts', async () => {
    const { service, users, verificationTokens, delivery } = fixture();
    users.findByEmail.mockResolvedValue(null);
    const result = await service.requestPasswordReset({
      email: 'unknown@example.com',
    });
    expect(result.message).toMatch(/^If an account exists/);
    expect(result).not.toHaveProperty('token');
    expect(verificationTokens.save).not.toHaveBeenCalled();
    expect(delivery.sendPasswordReset).not.toHaveBeenCalled();
  });

  it('sends a six-digit reset code and stores only its digest', async () => {
    const { service, users, verificationTokens, delivery } = fixture();
    users.findByEmail.mockResolvedValue({
      id: 'user-id',
      email: 'mario@example.com',
      status: UserStatus.ACTIVE,
    });
    await service.requestPasswordReset({ email: 'mario@example.com' });
    const resetCode = delivery.sendPasswordReset.mock.calls[0][1];
    const persisted = verificationTokens.create.mock.calls[0][0];
    expect(resetCode).toMatch(/^\d{6}$/);
    expect(persisted.tokenHash).toHaveLength(64);
    expect(persisted.tokenHash).not.toBe(resetCode);
  });

  it('keeps the generic forgot-password response when delivery fails', async () => {
    const { service, users, delivery } = fixture();
    users.findByEmail.mockResolvedValue({
      id: 'user-id',
      email: 'mario@example.com',
      status: UserStatus.ACTIVE,
    });
    delivery.sendPasswordReset.mockRejectedValue(new Error('SMTP details'));

    await expect(
      service.requestPasswordReset({ email: 'mario@example.com' }),
    ).resolves.toEqual(
      expect.objectContaining({
        message: expect.stringMatching(/^If an account exists/),
      }),
    );
  });
});
