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
    } catch (error: unknown) {
      // Keep recipient addresses and message contents out of logs, while
      // retaining the AWS error metadata needed to diagnose credentials,
      // permissions, sandbox restrictions, and unverified identities.
      const details = this.safeErrorDetails(error);
      this.logger.error(`SES delivery failed: ${JSON.stringify(details)}`);
      throw new ServiceUnavailableException(
        'Email delivery is temporarily unavailable',
      );
    }
  }

  private safeErrorDetails(error: unknown): Record<string, unknown> {
    if (!error || typeof error !== 'object') return { name: 'UnknownError' };

    const awsError = error as {
      name?: unknown;
      code?: unknown;
      $metadata?: { httpStatusCode?: unknown; requestId?: unknown };
    };
    return {
      name:
        typeof awsError.name === 'string' ? awsError.name : 'UnknownError',
      code: typeof awsError.code === 'string' ? awsError.code : undefined,
      statusCode: awsError.$metadata?.httpStatusCode,
      requestId: awsError.$metadata?.requestId,
    };
  }
}
