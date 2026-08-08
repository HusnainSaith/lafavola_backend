export const PUSH_PROVIDER = Symbol('PUSH_PROVIDER');

export interface PushMessage {
  title: string;
  body: string;
  data: Record<string, string>;
}
export interface PushResult {
  messageId?: string;
  permanentFailure: boolean;
}
export interface PushNotificationProvider {
  sendToDevice(token: string, message: PushMessage): Promise<PushResult>;
}
