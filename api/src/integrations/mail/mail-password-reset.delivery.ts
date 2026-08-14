import { Inject, Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { PasswordResetDelivery } from '../../modules/auth/interfaces/password-reset-delivery.interface';
import { MAIL_PROVIDER, MailProvider } from './mail.interface';
import { escapeHtml } from './templates/template.util';

@Injectable()
export class MailPasswordResetDelivery implements PasswordResetDelivery {
  constructor(
    @Inject(MAIL_PROVIDER) private readonly mail: MailProvider,
    private readonly config: ConfigService,
  ) {}

  async sendPasswordReset(email: string, resetCode: string): Promise<void> {
    const safeCode = escapeHtml(resetCode);
    const template = {
      text: `Reset your La Favola password\n\nYour password reset code is: ${resetCode}\n\nThis code expires in 15 minutes and can be used once.`,
      html: `<h1>Reset your La Favola password</h1><p>Your password reset code is:</p><p style="font-size:32px;font-weight:bold;letter-spacing:8px"><code>${safeCode}</code></p><p>This code expires in 15 minutes and can be used once.</p>`,
    };
    await this.mail.send({
      to: email,
      subject: 'Reset your La Favola password',
      ...template,
    });
  }
}
