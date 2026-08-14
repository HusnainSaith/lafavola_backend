import { Inject, Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { PasswordResetDelivery } from '../../modules/auth/interfaces/password-reset-delivery.interface';
import { MAIL_PROVIDER, MailProvider } from './mail.interface';
import { escapeHtml, linkTemplate } from './templates/template.util';

@Injectable()
export class MailPasswordResetDelivery implements PasswordResetDelivery {
  constructor(
    @Inject(MAIL_PROVIDER) private readonly mail: MailProvider,
    private readonly config: ConfigService,
  ) {}

  async sendPasswordReset(email: string, rawToken: string): Promise<void> {
    const base = this.config.getOrThrow<string>('PASSWORD_RESET_URL');
    const url = new URL(base);
    url.searchParams.set('token', rawToken);
    const template = linkTemplate({
      heading: 'Reset your La Favola password',
      introduction: 'Use the secure link below to choose a new password.',
      linkLabel: 'Reset password',
      url: url.toString(),
      expiration: 'This link expires in one hour and can be used once.',
    });
    template.text += `\n\nReset token (for manual entry):\n${rawToken}`;
    template.html += `<p><strong>Reset token (for manual entry):</strong></p><p><code style="word-break:break-all">${escapeHtml(rawToken)}</code></p>`;
    await this.mail.send({
      to: email,
      subject: 'Reset your La Favola password',
      ...template,
    });
  }
}
