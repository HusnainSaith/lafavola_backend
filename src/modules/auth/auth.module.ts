import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { JwtModule } from '@nestjs/jwt';
import { PassportModule } from '@nestjs/passport';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Role } from '../roles/entities/role.entity';
import { UsersModule } from '../users/users.module';
import { AuthController } from './auth.controller';
import { AuthService } from './auth.service';
import { RefreshToken } from './entities/refresh-token.entity';
import { VerificationToken } from './entities/verification-token.entity';
import { JwtAuthGuard } from './guards/jwt-auth.guard';
import { PASSWORD_RESET_DELIVERY } from './interfaces/password-reset-delivery.interface';
import { JwtStrategy } from './strategies/jwt.strategy';
import { MailModule } from '../../integrations/mail/mail.module';
import { MailPasswordResetDelivery } from '../../integrations/mail/mail-password-reset.delivery';

@Module({
  imports: [
    UsersModule,
    PassportModule,
    TypeOrmModule.forFeature([RefreshToken, VerificationToken, Role]),
    JwtModule.registerAsync({
      imports: [ConfigModule],
      inject: [ConfigService],
      useFactory: (config: ConfigService) => ({
        secret: config.get('JWT_SECRET'),
        signOptions: { expiresIn: '15m' },
      }),
    }),
    ConfigModule,
    MailModule,
  ],
  controllers: [AuthController],
  providers: [
    AuthService,
    JwtStrategy,
    JwtAuthGuard,
    {
      provide: PASSWORD_RESET_DELIVERY,
      useExisting: MailPasswordResetDelivery,
    },
  ],
  exports: [AuthService, JwtAuthGuard],
})
export class AuthModule {}
