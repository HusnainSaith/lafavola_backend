import {
  BadGatewayException,
  Injectable,
  ServiceUnavailableException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import {
  CreateProviderCheckoutInput,
  PaymentProviderPort,
  ProviderCheckout,
  ProviderPaymentStatus,
  ProviderRefundResult,
} from '../../modules/payments/interfaces/payment-provider.interface';
import { majorToMinor, minorToMajorString } from './sumup-money.util';

interface SumUpTransaction {
  id?: string;
  transaction_code?: string;
  status?: string;
  merchant_code?: string;
}

interface SumUpCheckout {
  id: string;
  checkout_reference: string;
  amount: number | string;
  currency: string;
  merchant_code: string;
  status: string;
  hosted_checkout_url?: string;
  transactions?: SumUpTransaction[];
}

@Injectable()
export class SumUpPaymentProvider implements PaymentProviderPort {
  constructor(private readonly config: ConfigService) {}

  async createCheckout(input: CreateProviderCheckoutInput) {
    const hosted = this.config.get<boolean>(
      'SUMUP_HOSTED_CHECKOUT_ENABLED',
      true,
    );
    return this.requestCheckout('/v0.1/checkouts', {
      method: 'POST',
      body: JSON.stringify({
        checkout_reference: input.checkoutReference,
        amount: Number(minorToMajorString(input.amountMinor)),
        currency: input.currency,
        merchant_code: this.merchantCode(),
        description: input.description,
        return_url: this.config.getOrThrow<string>('SUMUP_RETURN_URL'),
        hosted_checkout: { enabled: hosted },
      }),
    });
  }

  getCheckout(checkoutId: string) {
    return this.requestCheckout(
      `/v0.1/checkouts/${encodeURIComponent(checkoutId)}`,
      {
        method: 'GET',
      },
    );
  }

  async deactivateCheckout(checkoutId: string) {
    await this.request(`/v0.1/checkouts/${encodeURIComponent(checkoutId)}`, {
      method: 'DELETE',
    });
  }

  async refundPayment(
    providerTransactionId: string,
    amountMinor: number,
  ): Promise<ProviderRefundResult> {
    const result = await this.request<Record<string, unknown>>(
      `/v1.0/merchants/${encodeURIComponent(this.merchantCode())}/payments/${encodeURIComponent(providerTransactionId)}/refunds`,
      {
        method: 'POST',
        body: JSON.stringify({
          amount: Number(minorToMajorString(amountMinor)),
        }),
      },
    );
    return {
      providerRefundId:
        String(result?.id ?? result?.transaction_id ?? '') || undefined,
      status: 'refunded',
    };
  }

  private async requestCheckout(path: string, init: RequestInit) {
    const raw = await this.request<SumUpCheckout>(path, init);
    const transaction =
      raw.transactions?.find((item) => item.status === 'SUCCESSFUL') ??
      raw.transactions?.[0];
    return {
      checkoutId: raw.id,
      checkoutReference: raw.checkout_reference,
      merchantCode: raw.merchant_code,
      amountMinor: majorToMinor(raw.amount),
      currency: raw.currency as 'EUR',
      status: this.mapStatus(raw.status),
      hostedCheckoutUrl: raw.hosted_checkout_url,
      transactionId: transaction?.id,
      transactionCode: transaction?.transaction_code,
    } satisfies ProviderCheckout;
  }

  private mapStatus(status: string): ProviderPaymentStatus {
    if (status === 'PAID') return 'captured';
    if (status === 'FAILED') return 'failed';
    if (status === 'EXPIRED') return 'cancelled';
    return 'pending';
  }

  private merchantCode() {
    return this.config.getOrThrow<string>('SUMUP_MERCHANT_CODE');
  }

  private async request<T>(path: string, init: RequestInit): Promise<T> {
    if (!this.config.get<boolean>('SUMUP_ENABLED', false)) {
      throw new ServiceUnavailableException('Online payments are unavailable');
    }
    const controller = new AbortController();
    const timeout = setTimeout(
      () => controller.abort(),
      this.config.get<number>('SUMUP_REQUEST_TIMEOUT_MS', 10_000),
    );
    try {
      const response = await fetch(
        `${this.config.getOrThrow<string>('SUMUP_API_BASE_URL')}${path}`,
        {
          ...init,
          signal: controller.signal,
          headers: {
            Authorization: `Bearer ${this.config.getOrThrow<string>('SUMUP_API_KEY')}`,
            'Content-Type': 'application/json',
          },
        },
      );
      if (!response.ok) {
        throw new BadGatewayException('Payment provider rejected the request');
      }
      if (response.status === 204) return {} as T;
      return (await response.json()) as T;
    } catch (error) {
      if (error instanceof BadGatewayException) throw error;
      throw new ServiceUnavailableException('Payment provider is unavailable');
    } finally {
      clearTimeout(timeout);
    }
  }
}
