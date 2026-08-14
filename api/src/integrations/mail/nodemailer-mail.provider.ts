import {
  Injectable,
  Logger,
  ServiceUnavailableException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as nodemailer from 'nodemailer';
import type { Transporter } from 'nodemailer';
import { MailMessage, MailProvider } from './mail.interface';

@Injectable()
export class NodemailerMailProvider implements MailProvider {
  private readonly logger = new Logger(NodemailerMailProvider.name);
  private readonly transporter?: Transporter;

  constructor(private readonly config: ConfigService) {
    if (
      this.config.get<boolean>('MAIL_ENABLED', false) &&
      this.config.get<string>('MAIL_PROVIDER', 'smtp') === 'smtp'
    ) {
      this.transporter = nodemailer.createTransport({
        host: this.config.getOrThrow<string>('MAIL_HOST'),
        port: this.config.getOrThrow<number>('MAIL_PORT'),
        secure: this.config.getOrThrow<boolean>('MAIL_SECURE'),
        auth: {
          user: this.config.getOrThrow<string>('MAIL_USER'),
          pass: this.config.getOrThrow<string>('MAIL_PASSWORD'),
        },
      });
    }
  }

  async send(message: MailMessage): Promise<{ messageId?: string }> {
    if (!this.transporter) return {};
    try {
      const result = await this.transporter.sendMail({
        from: {
          name: this.config.getOrThrow<string>('MAIL_FROM_NAME'),
          address: this.config.getOrThrow<string>('MAIL_FROM_EMAIL'),
        },
        to: message.to,
        subject: message.subject,
        text: message.text,
        html: message.html,
        headers: message.idempotencyKey
          ? { 'X-La-Favola-Event-Id': message.idempotencyKey }
          : undefined,
      });
      return { messageId: result.messageId };
    } catch {
      this.logger.error('SMTP delivery failed');
      throw new ServiceUnavailableException(
        'Email delivery is temporarily unavailable',
      );
    }
  }
}
