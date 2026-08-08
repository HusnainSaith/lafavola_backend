import { Injectable, ServiceUnavailableException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { App, cert, getApps, initializeApp } from 'firebase-admin/app';
import { getMessaging } from 'firebase-admin/messaging';
import {
  PushMessage,
  PushNotificationProvider,
  PushResult,
} from './push.interface';

@Injectable()
export class FirebasePushProvider implements PushNotificationProvider {
  private app?: App;
  constructor(private readonly config: ConfigService) {}

  async sendToDevice(token: string, message: PushMessage): Promise<PushResult> {
    if (!this.config.get<boolean>('PUSH_ENABLED', false))
      return { permanentFailure: false };
    try {
      const messageId = await getMessaging(this.firebaseApp()).send({
        token,
        notification: { title: message.title, body: message.body },
        data: message.data,
      });
      return { messageId, permanentFailure: false };
    } catch (error) {
      const code = String((error as { code?: string }).code ?? '');
      if (
        [
          'messaging/invalid-registration-token',
          'messaging/registration-token-not-registered',
        ].includes(code)
      ) {
        return { permanentFailure: true };
      }
      throw new ServiceUnavailableException('Push delivery is unavailable');
    }
  }

  private firebaseApp() {
    if (this.app) return this.app;
    this.app =
      getApps()[0] ??
      initializeApp({
        credential: cert({
          projectId: this.config.getOrThrow<string>('FIREBASE_PROJECT_ID'),
          clientEmail: this.config.getOrThrow<string>('FIREBASE_CLIENT_EMAIL'),
          privateKey: this.config
            .getOrThrow<string>('FIREBASE_PRIVATE_KEY')
            .replace(/\\n/g, '\n'),
        }),
      });
    return this.app;
  }
}
