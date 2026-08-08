export const PASSWORD_RESET_DELIVERY = Symbol('PASSWORD_RESET_DELIVERY');

export interface PasswordResetDelivery {
  sendPasswordReset(email: string, rawToken: string): Promise<void>;
}

export class DeferredPasswordResetDelivery implements PasswordResetDelivery {
  async sendPasswordReset(): Promise<void> {
    // Provider adapter intentionally belongs to P1. Never log or return the token.
  }
}
