import {
  BadRequestException,
  Inject,
  Injectable,
  InternalServerErrorException,
  HttpException,
  HttpStatus,
  Logger,
  UnauthorizedException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import { InjectRepository } from '@nestjs/typeorm';
import * as bcrypt from 'bcryptjs';
import { createHash, randomBytes, randomInt } from 'crypto';
import { DataSource, IsNull, QueryFailedError, Repository } from 'typeorm';
import {
  MAIL_PROVIDER,
  MailProvider,
} from '../../integrations/mail/mail.interface';
import { escapeHtml } from '../../integrations/mail/templates/template.util';
import { Role } from '../roles/entities/role.entity';
import { RoleEnum } from '../roles/role.enum';
import { UserStatus } from '../users/enums/user-status.enum';
import { User } from '../users/entities/user.entity';
import { UsersService } from '../users/users.service';
import { AuthCredentialsDto } from './dto/auth-credentials.dto';
import { AuthUserResponseDto } from './dto/auth-user-response.dto';
import {
  PasswordResetDto,
  RefreshTokenDto,
  ResetPasswordDto,
} from './dto/refresh-token.dto';
import { RegisterDto } from './dto/register.dto';
import { SocialLoginDto } from './dto/social-login.dto';
import { RefreshToken } from './entities/refresh-token.entity';
import { SocialAccount } from './entities/social-account.entity';
import { VerificationToken } from './entities/verification-token.entity';
import { SocialProvider } from './enums/social-provider.enum';
import {
  PASSWORD_RESET_DELIVERY,
  PasswordResetDelivery,
} from './interfaces/password-reset-delivery.interface';
import {
  SOCIAL_IDENTITY_VERIFIER,
  SocialIdentityVerifier,
} from './interfaces/social-identity-verifier.interface';

const GENERIC_RESET_MESSAGE =
  'If an account exists for that email, password reset instructions have been sent.';

@Injectable()
export class AuthService {
  private readonly logger = new Logger(AuthService.name);

  constructor(
    private readonly usersService: UsersService,
    private readonly jwtService: JwtService,
    private readonly config: ConfigService,
    private readonly dataSource: DataSource,
    @InjectRepository(Role) private readonly roles: Repository<Role>,
    @InjectRepository(RefreshToken)
    private readonly refreshTokens: Repository<RefreshToken>,
    @InjectRepository(VerificationToken)
    private readonly verificationTokens: Repository<VerificationToken>,
    @Inject(PASSWORD_RESET_DELIVERY)
    private readonly resetDelivery: PasswordResetDelivery,
    @Inject(MAIL_PROVIDER) private readonly mail: MailProvider,
    @Inject(SOCIAL_IDENTITY_VERIFIER)
    private readonly socialIdentityVerifier: SocialIdentityVerifier,
  ) {}

  async register(dto: RegisterDto) {
    const customerRole = await this.roles.findOne({
      where: { name: RoleEnum.CLIENT },
    });
    if (!customerRole) {
      throw new InternalServerErrorException(
        'Customer registration is unavailable',
      );
    }

    const response = await this.usersService.create({
      email: dto.email,
      phone: dto.phone,
      password: dto.password,
      fullName: dto.fullName,
      roleId: customerRole.id,
      status: UserStatus.PENDING_VERIFICATION,
    });

    if (response.data.email) {
      await this.sendEmailVerification(
        response.data.id,
        response.data.email,
        false,
      );
    }

    return {
      success: true,
      message: 'User registered successfully',
      user: AuthUserResponseDto.from(response.data),
    };
  }

  async login(dto: AuthCredentialsDto) {
    const user = await this.usersService.findByEmail(dto.email, {
      includePassword: true,
    });
    if (
      !user ||
      user.archivedAt ||
      !user.password ||
      !(await bcrypt.compare(dto.password, user.password))
    ) {
      throw new UnauthorizedException('Invalid email or password');
    }
    if (!user.emailVerifiedAt) {
      throw new UnauthorizedException(
        'Please verify your email before signing in',
      );
    }
    if (user.status !== UserStatus.ACTIVE) {
      throw new UnauthorizedException('This account cannot sign in');
    }

    const accessToken = await this.signAccessToken(user.id, user.email);
    const refreshToken = await this.createRefreshSession(user.id);
    return {
      success: true,
      message: 'Login successful',
      data: {
        accessToken,
        refreshToken,
        user: AuthUserResponseDto.from(user),
      },
    };
  }

  async socialLogin(provider: SocialProvider, dto: SocialLoginDto) {
    const identity = await this.socialIdentityVerifier.verify(
      provider,
      dto.idToken,
    );

    const user = await this.dataSource.transaction(async (manager) => {
      const socialAccounts = manager.getRepository(SocialAccount);
      const existingAccount = await socialAccounts.findOne({
        where: { provider, providerSubject: identity.subject },
        relations: { user: { role: true } },
      });

      if (existingAccount) {
        this.assertActive(existingAccount.user);
        existingAccount.user.lastLoginAt = new Date();
        await manager.update(User, existingAccount.user.id, {
          lastLoginAt: existingAccount.user.lastLoginAt,
        });
        return existingAccount.user;
      }

      if (!identity.email || !identity.emailVerified) {
        throw new BadRequestException(
          'A verified email is required for first-time OAuth sign-in',
        );
      }

      const users = manager.getRepository(User);
      let linkedUser = await users
        .createQueryBuilder('user')
        .leftJoinAndSelect('user.role', 'role')
        .where('LOWER(user.email) = LOWER(:email)', { email: identity.email })
        .getOne();

      if (linkedUser) {
        this.assertActive(linkedUser);
        linkedUser.lastLoginAt = new Date();
        await manager.update(User, linkedUser.id, {
          lastLoginAt: linkedUser.lastLoginAt,
          emailVerifiedAt: linkedUser.emailVerifiedAt || new Date(),
        });
      } else {
        const customerRole = await manager.getRepository(Role).findOne({
          where: { name: RoleEnum.CLIENT },
        });
        if (!customerRole) {
          throw new InternalServerErrorException(
            'Customer authentication is unavailable',
          );
        }
        linkedUser = await users.save(
          users.create({
            email: identity.email,
            fullName:
              dto.fullName?.trim() ||
              identity.fullName ||
              identity.email.split('@')[0],
            roleId: customerRole.id,
            role: customerRole,
            status: UserStatus.ACTIVE,
            emailVerifiedAt: new Date(),
            lastLoginAt: new Date(),
          }),
        );
      }

      await socialAccounts.save(
        socialAccounts.create({
          userId: linkedUser.id,
          provider,
          providerSubject: identity.subject,
          providerEmail: identity.email,
        }),
      );
      return linkedUser;
    });

    return {
      success: true,
      message: `${provider === SocialProvider.GOOGLE ? 'Google' : 'Apple'} authentication successful`,
      data: {
        accessToken: await this.signAccessToken(user.id, user.email),
        refreshToken: await this.createRefreshSession(user.id),
        user: AuthUserResponseDto.from(user),
      },
    };
  }

  async refreshToken(dto: RefreshTokenDto) {
    const tokenHash = this.digest(dto.refreshToken);
    const session = await this.refreshTokens
      .createQueryBuilder('session')
      .addSelect('session.tokenHash')
      .leftJoinAndSelect('session.user', 'user')
      .where('session.token = :tokenHash', { tokenHash })
      .getOne();

    if (
      !session ||
      session.isRevoked ||
      session.expiresAt <= new Date() ||
      !session.user ||
      session.user.status !== UserStatus.ACTIVE ||
      session.user.archivedAt
    ) {
      throw new UnauthorizedException('Invalid or expired refresh token');
    }

    const rotated = await this.dataSource.transaction(async (manager) => {
      const result = await manager.update(
        RefreshToken,
        { id: session.id, isRevoked: false },
        { isRevoked: true, revokedAt: new Date() },
      );
      if (result.affected !== 1) {
        throw new UnauthorizedException('Invalid or expired refresh token');
      }
      return this.createRefreshSession(
        session.userId,
        manager.getRepository(RefreshToken),
      );
    });

    return {
      success: true,
      message: 'Token refreshed successfully',
      data: {
        accessToken: await this.signAccessToken(
          session.user.id,
          session.user.email,
        ),
        refreshToken: rotated,
      },
    };
  }

  async logout(userId: string, rawToken: string) {
    const result = await this.refreshTokens
      .createQueryBuilder()
      .update(RefreshToken)
      .set({ isRevoked: true, revokedAt: new Date() })
      .where('user_id = :userId', { userId })
      .andWhere('token = :tokenHash', { tokenHash: this.digest(rawToken) })
      .andWhere('is_revoked = false')
      .execute();
    if (result.affected !== 1) {
      throw new UnauthorizedException('Invalid refresh token');
    }
    return { success: true, message: 'Logged out successfully' };
  }

  async requestPasswordReset(dto: PasswordResetDto) {
    const user = await this.usersService.findByEmail(dto.email);
    if (user && user.status !== UserStatus.DELETED && !user.archivedAt) {
      await this.verificationTokens
        .createQueryBuilder()
        .update(VerificationToken)
        .set({ consumedAt: new Date() })
        .where('user_id = :userId', { userId: user.id })
        .andWhere('type = :type', { type: 'password_reset' })
        .andWhere('consumed_at IS NULL')
        .execute();
      const resetCode = await this.createSixDigitCode(
        user.id,
        'password_reset',
        15 * 60 * 1000,
      );
      try {
        await this.resetDelivery.sendPasswordReset(user.email, resetCode);
      } catch {
        // Preserve the same public response for known and unknown accounts.
        // The provider logs its sanitized failure without recipient or token data.
        this.logger.warn('Password reset delivery failed');
      }
    }
    return { success: true, message: GENERIC_RESET_MESSAGE };
  }

  async resetPassword(dto: ResetPasswordDto) {
    const tokenHash = this.digest(dto.code);
    const changed = await this.dataSource.transaction(async (manager) => {
      const repository = manager.getRepository(VerificationToken);
      const token = await repository.findOne({
        where: { tokenHash, type: 'password_reset', consumedAt: IsNull() },
        lock: { mode: 'pessimistic_write' },
      });
      if (!token || token.expiresAt <= new Date() || token.attempts >= 5) {
        return false;
      }
      const password = await bcrypt.hash(dto.password, 12);
      await manager.update('users', { id: token.userId }, { password });
      token.consumedAt = new Date();
      await repository.save(token);
      await manager.update(
        RefreshToken,
        { userId: token.userId, isRevoked: false },
        { isRevoked: true, revokedAt: new Date() },
      );
      return true;
    });
    if (!changed) {
      throw new UnauthorizedException('Invalid or expired reset code');
    }
    return { success: true, message: 'Password has been changed successfully' };
  }

  async resendEmailVerification(userId: string) {
    const user = await this.usersService.findById(userId);
    if (!user || !user.email || user.emailVerifiedAt) {
      return { success: true, message: 'Verification request accepted' };
    }
    await this.sendEmailVerification(user.id, user.email, true);
    return { success: true, message: 'Verification request accepted' };
  }

  async resendEmailVerificationForEmail(email: string) {
    const user = await this.usersService.findByEmail(email);
    if (
      user &&
      [UserStatus.PENDING_VERIFICATION, UserStatus.ACTIVE].includes(
        user.status as UserStatus,
      ) &&
      !user.archivedAt &&
      !user.emailVerifiedAt &&
      user.email
    ) {
      await this.sendEmailVerification(user.id, user.email, true);
    }
    return { success: true, message: 'Verification request accepted' };
  }

  async verifyEmail(code: string) {
    const tokenHash = this.digest(code);
    await this.dataSource.transaction(async (manager) => {
      const token = await manager.getRepository(VerificationToken).findOne({
        where: { tokenHash, type: 'email_verify', consumedAt: IsNull() },
        lock: { mode: 'pessimistic_write' },
      });
      if (!token || token.consumedAt || token.expiresAt <= new Date()) {
        throw new UnauthorizedException(
          'Invalid or expired verification code',
        );
      }
      await manager.update(
        'users',
        { id: token.userId },
        {
          emailVerifiedAt: new Date(),
          status: UserStatus.ACTIVE,
        },
      );
      token.consumedAt = new Date();
      await manager.save(token);
    });
    return { success: true, message: 'Email verified successfully' };
  }

  async getCurrentUser(userId: string) {
    const response = await this.usersService.findOne(userId);
    return { ...response, data: AuthUserResponseDto.from(response.data) };
  }

  private assertActive(user: User) {
    if (!user || user.status !== UserStatus.ACTIVE || user.archivedAt) {
      throw new UnauthorizedException('This account cannot sign in');
    }
  }

  private async signAccessToken(userId: string, email?: string) {
    return this.jwtService.signAsync(
      { sub: userId, email },
      {
        secret: this.config.getOrThrow<string>('JWT_SECRET'),
        expiresIn: this.config.get<string>('JWT_EXPIRES_IN', '15m'),
      },
    );
  }

  private async createRefreshSession(
    userId: string,
    repository = this.refreshTokens,
  ): Promise<string> {
    const rawToken = randomBytes(48).toString('base64url');
    const ttlDays = Number(
      this.config.get<string>('JWT_REFRESH_TTL_DAYS', '30'),
    );
    await repository.save(
      repository.create({
        tokenHash: this.digest(rawToken),
        userId,
        expiresAt: new Date(Date.now() + ttlDays * 24 * 60 * 60 * 1000),
        isRevoked: false,
      }),
    );
    return rawToken;
  }

  private async sendEmailVerification(
    userId: string,
    email: string,
    enforceThrottle: boolean,
  ) {
    if (enforceThrottle) {
      const recent = await this.verificationTokens
        .createQueryBuilder('token')
        .where('token.user_id = :userId', { userId })
        .andWhere('token.type = :type', { type: 'email_verify' })
        .andWhere('token.consumed_at IS NULL')
        .andWhere("token.created_at > NOW() - INTERVAL '60 seconds'")
        .getExists();
      if (recent) {
        throw new HttpException(
          'Please wait before requesting another verification email',
          HttpStatus.TOO_MANY_REQUESTS,
        );
      }
    }
    await this.verificationTokens
      .createQueryBuilder()
      .update(VerificationToken)
      .set({ consumedAt: new Date() })
      .where('user_id = :userId', { userId })
      .andWhere('type = :type', { type: 'email_verify' })
      .andWhere('consumed_at IS NULL')
      .execute();
    const code = await this.createSixDigitCode(
      userId,
      'email_verify',
      24 * 60 * 60 * 1000,
    );
    const safeCode = escapeHtml(code);
    const template = {
      text: `Verify your La Favola email\n\nYour email verification code is: ${code}\n\nThis code expires in 24 hours and can be used once.`,
      html: `<h1>Verify your La Favola email</h1><p>Your email verification code is:</p><p style="font-size:32px;font-weight:bold;letter-spacing:8px"><code>${safeCode}</code></p><p>This code expires in 24 hours and can be used once.</p>`,
    };
    try {
      await this.mail.send({
        to: email,
        subject: 'Verify your La Favola email',
        ...template,
      });
    } catch {
      // The account and its verification token are already durable. SMTP is an
      // optional delivery channel and must not make registration appear failed.
      this.logger.warn('Email verification delivery failed');
    }
  }

  private digest(token: string): string {
    return createHash('sha256').update(token, 'utf8').digest('hex');
  }

  private async createSixDigitCode(
    userId: string,
    type: 'email_verify' | 'password_reset',
    ttlMilliseconds: number,
  ): Promise<string> {
    for (let attempt = 0; attempt < 10; attempt += 1) {
      const code = randomInt(100000, 1000000).toString();
      try {
        await this.verificationTokens.save(
          this.verificationTokens.create({
            userId,
            type,
            tokenHash: this.digest(code),
            attempts: 0,
            expiresAt: new Date(Date.now() + ttlMilliseconds),
          }),
        );
        return code;
      } catch (error) {
        const databaseError = error as QueryFailedError & {
          driverError?: { code?: string };
        };
        if (databaseError.driverError?.code !== '23505') throw error;
      }
    }
    throw new InternalServerErrorException(
      'Unable to allocate a verification code',
    );
  }
}
