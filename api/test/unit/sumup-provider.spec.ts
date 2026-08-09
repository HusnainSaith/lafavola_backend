import {
  BadRequestException,
  ServiceUnavailableException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { SumUpPaymentProvider } from '../../src/integrations/sumup/sumup-payment.provider';
import {
  majorToMinor,
  minorToMajorString,
} from '../../src/integrations/sumup/sumup-money.util';

describe('SumUp payment provider', () => {
  const values: Record<string, unknown> = {
    SUMUP_ENABLED: true,
    SUMUP_API_BASE_URL: 'https://api.sumup.com',
    SUMUP_API_KEY: 'test-secret',
    SUMUP_MERCHANT_CODE: 'MERCHANT1',
    SUMUP_RETURN_URL: 'https://api.example.com/payments/webhooks/sumup',
    SUMUP_HOSTED_CHECKOUT_ENABLED: true,
    SUMUP_REQUEST_TIMEOUT_MS: 1000,
  };
  const config = {
    get: jest.fn((key: string, fallback?: unknown) => values[key] ?? fallback),
    getOrThrow: jest.fn((key: string) => {
      if (values[key] === undefined) throw new Error('missing');
      return values[key];
    }),
  } as unknown as ConfigService;

  afterEach(() => jest.restoreAllMocks());

  it('converts EUR minor units without internal floating-point arithmetic', () => {
    expect(minorToMajorString(1299)).toBe('12.99');
    expect(majorToMinor('12.99')).toBe(1299);
    expect(() => minorToMajorString(-1)).toThrow(BadRequestException);
  });

  it('creates an official hosted checkout payload with merchant and backend amount', async () => {
    const fetchMock = jest.spyOn(global, 'fetch').mockResolvedValue({
      ok: true,
      status: 201,
      json: async () => ({
        id: 'checkout-1',
        checkout_reference: 'LF-ORDER-1',
        amount: 12.99,
        currency: 'EUR',
        merchant_code: 'MERCHANT1',
        status: 'PENDING',
        hosted_checkout_url: 'https://checkout.sumup.com/pay/checkout-1',
        transactions: [],
      }),
    } as Response);
    const provider = new SumUpPaymentProvider(config);
    const result = await provider.createCheckout({
      checkoutReference: 'LF-ORDER-1',
      amountMinor: 1299,
      currency: 'EUR',
      description: 'Order 1',
    });
    const request = fetchMock.mock.calls[0];
    expect(request[0]).toBe('https://api.sumup.com/v0.1/checkouts');
    expect(JSON.parse(String(request[1]?.body))).toEqual(
      expect.objectContaining({
        checkout_reference: 'LF-ORDER-1',
        amount: 12.99,
        currency: 'EUR',
        merchant_code: 'MERCHANT1',
        hosted_checkout: { enabled: true },
      }),
    );
    expect(request[1]?.headers).toEqual(
      expect.objectContaining({ Authorization: 'Bearer test-secret' }),
    );
    expect(result).toEqual(
      expect.objectContaining({
        checkoutId: 'checkout-1',
        amountMinor: 1299,
        status: 'pending',
      }),
    );
  });

  it('retrieves checkout state and maps a successful transaction', async () => {
    jest.spyOn(global, 'fetch').mockResolvedValue({
      ok: true,
      status: 200,
      json: async () => ({
        id: 'checkout-1',
        checkout_reference: 'LF-1',
        amount: 20,
        currency: 'EUR',
        merchant_code: 'MERCHANT1',
        status: 'PAID',
        transactions: [
          {
            id: 'transaction-1',
            transaction_code: 'TX1',
            status: 'SUCCESSFUL',
          },
        ],
      }),
    } as Response);
    await expect(
      new SumUpPaymentProvider(config).getCheckout('checkout-1'),
    ).resolves.toEqual(
      expect.objectContaining({
        status: 'captured',
        transactionId: 'transaction-1',
      }),
    );
  });

  it('calls the official merchant transaction refund endpoint', async () => {
    const fetchMock = jest.spyOn(global, 'fetch').mockResolvedValue({
      ok: true,
      status: 200,
      json: async () => ({ id: 'refund-1' }),
    } as Response);
    await new SumUpPaymentProvider(config).refundPayment('transaction-1', 500);
    expect(fetchMock.mock.calls[0][0]).toBe(
      'https://api.sumup.com/v1.0/merchants/MERCHANT1/payments/transaction-1/refunds',
    );
    expect(JSON.parse(String(fetchMock.mock.calls[0][1]?.body))).toEqual({
      amount: 5,
    });
  });

  it('maps timeouts and transport errors without leaking provider data', async () => {
    jest
      .spyOn(global, 'fetch')
      .mockRejectedValue(new Error('secret provider response'));
    await expect(
      new SumUpPaymentProvider(config).getCheckout('checkout-1'),
    ).rejects.toThrow(ServiceUnavailableException);
  });
});
