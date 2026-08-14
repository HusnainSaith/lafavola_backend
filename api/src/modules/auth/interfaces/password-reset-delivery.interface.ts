export const PASSWORD_RESET_DELIVERY = Symbol('PASSWORD_RESET_DELIVERY');

export interface PasswordResetDelivery {
  sendPasswordReset(email: string, resetCode: string): Promise<void>;
}

export class DeferredPasswordResetDelivery implements PasswordResetDelivery {
  async sendPasswordReset(): Promise<void> {
    // Never log or return the reset code from a public API response.
  }
}
