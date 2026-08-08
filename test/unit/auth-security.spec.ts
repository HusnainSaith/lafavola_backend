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
  };
  const delivery = {
    sendPasswordReset: jest.fn().mockResolvedValue(undefined),
  };
  const mail = { send: jest.fn().mockResolvedValue({}) };
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
  );
  return { service, users, roles, refreshTokens, verificationTokens, delivery };
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
      expect.objectContaining({ roleId: 'client-role' }),
    );
    expect(result.user).not.toHaveProperty('password');
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

  it('stores only a reset-token digest', async () => {
    const { service, users, verificationTokens, delivery } = fixture();
    users.findByEmail.mockResolvedValue({
      id: 'user-id',
      email: 'mario@example.com',
      status: UserStatus.ACTIVE,
    });
    await service.requestPasswordReset({ email: 'mario@example.com' });
    const rawToken = delivery.sendPasswordReset.mock.calls[0][1];
    const persisted = verificationTokens.create.mock.calls[0][0];
    expect(persisted.tokenHash).toHaveLength(64);
    expect(persisted.tokenHash).not.toBe(rawToken);
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
