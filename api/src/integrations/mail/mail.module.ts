import { Global, Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { MAIL_PROVIDER } from './mail.interface';
import { MailPasswordResetDelivery } from './mail-password-reset.delivery';
import { NodemailerMailProvider } from './nodemailer-mail.provider';

@Global()
@Module({
  imports: [ConfigModule],
  providers: [
    NodemailerMailProvider,
    MailPasswordResetDelivery,
    { provide: MAIL_PROVIDER, useExisting: NodemailerMailProvider },
  ],
  exports: [MAIL_PROVIDER, MailPasswordResetDelivery],
})
export class MailModule {}
