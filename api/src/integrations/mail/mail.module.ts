import { Global, Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { MAIL_PROVIDER } from './mail.interface';
import { MailPasswordResetDelivery } from './mail-password-reset.delivery';
import { NodemailerMailProvider } from './nodemailer-mail.provider';
import { SesMailProvider } from './ses-mail.provider';

@Global()
@Module({
  imports: [ConfigModule],
  providers: [
    NodemailerMailProvider,
    SesMailProvider,
    MailPasswordResetDelivery,
    {
      provide: MAIL_PROVIDER,
      useFactory: (
        config: ConfigService,
        smtp: NodemailerMailProvider,
        ses: SesMailProvider,
      ) => (config.get<string>('MAIL_PROVIDER', 'smtp') === 'ses' ? ses : smtp),
      inject: [ConfigService, NodemailerMailProvider, SesMailProvider],
    },
  ],
  exports: [MAIL_PROVIDER, MailPasswordResetDelivery],
})
export class MailModule {}
