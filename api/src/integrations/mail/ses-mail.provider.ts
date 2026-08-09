import { SESv2Client, SendEmailCommand } from '@aws-sdk/client-sesv2';
import {
  Injectable,
  Logger,
  ServiceUnavailableException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { MailMessage, MailProvider } from './mail.interface';

@Injectable()
export class SesMailProvider implements MailProvider {
  private readonly logger = new Logger(SesMailProvider.name);
  private readonly client?: SESv2Client;

  constructor(private readonly config: ConfigService) {
    if (
      this.config.get<boolean>('MAIL_ENABLED', false) &&
      this.config.get<string>('MAIL_PROVIDER') === 'ses'
    ) {
      this.client = new SESv2Client({
        region: this.config.getOrThrow<string>('AWS_SES_REGION'),
        ...(this.config.get<string>('AWS_SES_ACCESS_KEY_ID') &&
        this.config.get<string>('AWS_SES_SECRET_ACCESS_KEY')
          ? {
              credentials: {
                accessKeyId: this.config.getOrThrow<string>(
                  'AWS_SES_ACCESS_KEY_ID',
                ),
                secretAccessKey: this.config.getOrThrow<string>(
                  'AWS_SES_SECRET_ACCESS_KEY',
                ),
              },
            }
          : {}),
      });
    }
  }

  async send(message: MailMessage): Promise<{ messageId?: string }> {
    if (!this.client) return {};
    try {
      const result = await this.client.send(
        new SendEmailCommand({
          FromEmailAddress: this.config.getOrThrow<string>('MAIL_FROM_EMAIL'),
          Destination: { ToAddresses: [message.to] },
          Content: {
            Simple: {
              Subject: { Data: message.subject, Charset: 'UTF-8' },
              Body: {
                Text: { Data: message.text, Charset: 'UTF-8' },
                Html: { Data: message.html, Charset: 'UTF-8' },
              },
            },
          },
          EmailTags: message.idempotencyKey
            ? [{ Name: 'la_favola_event_id', Value: message.idempotencyKey }]
            : undefined,
        }),
      );
      return { messageId: result.MessageId };
    } catch {
      this.logger.error('SES delivery failed');
      throw new ServiceUnavailableException(
        'Email delivery is temporarily unavailable',
      );
    }
  }
}
