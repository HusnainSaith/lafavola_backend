import 'reflect-metadata';
import { ConfigService } from '@nestjs/config';
import { DataSource } from 'typeorm';
import { PaymentsService } from '../../src/modules/payments/payments.service';
import { PaymentTransactionRepository } from '../../src/modules/payments/repositories/payment-transaction.repository';
import { RefundsService } from '../../src/modules/refunds/refunds.service';
import { PaymentProviderPort } from '../../src/modules/payments/interfaces/payment-provider.interface';
import {
  createTestDataSource,
  ensureTestDatabase,
  resetIsolatedTestDatabase,
} from '../utils/test-data-source';

jest.setTimeout(120_000);
const enabled = process.env.RUN_DB_TESTS === 'true';

(enabled ? describe : describe.skip)(
  'SumUp PostgreSQL payment integrity',
  () => {
    let dataSource: DataSource;
    let orderId: string;
    let paymentId: string;
    let customerId: string;
    const provider: jest.Mocked<PaymentProviderPort> = {
      createCheckout: jest.fn(),
      getCheckout: jest.fn(),
      deactivateCheckout: jest.fn(),
      refundPayment: jest.fn(),
    };

    beforeAll(async () => {
      dataSource = createTestDataSource(await ensureTestDatabase());
      await resetIsolatedTestDatabase(dataSource);
      await dataSource.runMigrations({ transaction: 'each' });
      const [{ id: restaurantId }] = await dataSource.query(
        `INSERT INTO restaurants (name,slug) VALUES ('Payments Test','payments-test') RETURNING id`,
      );
      const [{ id: roleId }] = await dataSource.query(
        `INSERT INTO roles (name,is_system) VALUES ('customer',true) RETURNING id`,
      );
      [{ id: customerId }] = await dataSource.query(
        `INSERT INTO users (email,full_name,role_id) VALUES ('payments@example.com','Payments Customer',$1) RETURNING id`,
        [roleId],
      );
      [{ id: orderId }] = await dataSource.query(
        `INSERT INTO orders (restaurant_id,customer_id,order_type,payment_method,subtotal_minor,tax_minor,grand_total_minor)
       VALUES ($1,$2,'pickup','card',1800,200,2000) RETURNING id`,
        [restaurantId, customerId],
      );
      const [{ id }] = await dataSource.query(
        `INSERT INTO payment_transactions
       (order_id,customer_id,provider,payment_method_type,provider_checkout_id,checkout_reference,
        provider_transaction_id,amount_minor,currency,status,metadata)
       VALUES ($1,$2,'sumup','card','checkout-1','LF-TEST-1','transaction-1',2000,'EUR','captured','{}') RETURNING id`,
        [orderId, customerId],
      );
      paymentId = id;
    });

    afterAll(async () => {
      if (dataSource?.isInitialized) await dataSource.destroy();
    });

    it('lists only safe owned payment references and atomically changes the default', async () => {
      const [{ id: firstId }] = await dataSource.query(
        `INSERT INTO customer_payment_methods
         (customer_id,provider,provider_payment_method_id,payment_method_type,card_brand,card_last4,is_default)
         VALUES ($1,'stripe','secret-provider-reference-1','card','visa','1111',true) RETURNING id`,
        [customerId],
      );
      const [{ id: secondId }] = await dataSource.query(
        `INSERT INTO customer_payment_methods
         (customer_id,provider,provider_payment_method_id,payment_method_type,card_brand,card_last4,is_default)
         VALUES ($1,'stripe','secret-provider-reference-2','card','mastercard','2222',false) RETURNING id`,
        [customerId],
      );
      const service = new PaymentsService(
        dataSource,
        new PaymentTransactionRepository(dataSource),
        {} as ConfigService,
        {} as any,
        provider,
      );

      const methods = await service.listMethods(customerId);
      expect(methods).toHaveLength(2);
      expect(JSON.stringify(methods)).not.toContain(
        'secret-provider-reference',
      );
      await service.makeMethodDefault(customerId, secondId);
      const defaults = await dataSource.query(
        `SELECT id FROM customer_payment_methods WHERE customer_id=$1 AND is_default=true AND archived_at IS NULL`,
        [customerId],
      );
      expect(defaults).toEqual([{ id: secondId }]);

      await service.archiveMethod(customerId, secondId);
      const active = await service.listMethods(customerId);
      expect(active).toHaveLength(1);
      expect(active[0]).toMatchObject({ id: firstId, isDefault: true });
    });

    it('verifies a paid checkout once and creates one receipt/state transition', async () => {
      await dataSource.query(
        `UPDATE orders SET status='pending_payment',payment_status='pending' WHERE id=$1`,
        [orderId],
      );
      await dataSource.query(
        `UPDATE payment_transactions SET status='pending',captured_at=NULL WHERE id=$1`,
        [paymentId],
      );
      const config = {
        getOrThrow: jest.fn().mockReturnValue('MERCHANT1'),
      } as unknown as ConfigService;
      const outbox = { enqueue: jest.fn().mockResolvedValue(undefined) } as any;
      const service = new PaymentsService(
        dataSource,
        new PaymentTransactionRepository(dataSource),
        config,
        outbox,
        provider,
      );
      const checkout = {
        checkoutId: 'checkout-1',
        checkoutReference: 'LF-TEST-1',
        merchantCode: 'MERCHANT1',
        amountMinor: 2000,
        currency: 'EUR' as const,
        status: 'captured' as const,
        transactionId: 'transaction-1',
      };
      await service.synchronizeCheckout(checkout, 'CHECKOUT_STATUS_CHANGED');
      await service.synchronizeCheckout(checkout, 'CHECKOUT_STATUS_CHANGED');
      const [order] = await dataSource.query(
        `SELECT status,payment_status FROM orders WHERE id=$1`,
        [orderId],
      );
      const [{ count: receipts }] = await dataSource.query(
        `SELECT COUNT(*)::int count FROM payment_receipts WHERE payment_transaction_id=$1`,
        [paymentId],
      );
      const [{ count: events }] = await dataSource.query(
        `SELECT COUNT(*)::int count FROM payment_webhook_events WHERE provider='sumup'`,
        [],
      );
      expect(order).toEqual({ status: 'placed', payment_status: 'paid' });
      expect(receipts).toBe(1);
      expect(events).toBe(1);
      expect(outbox.enqueue).toHaveBeenCalledTimes(1);
    });

    it('serializes concurrent refunds so cumulative value cannot exceed payment', async () => {
      await dataSource.query(`DELETE FROM refunds`);
      await dataSource.query(
        `UPDATE payment_transactions SET status='captured' WHERE id=$1`,
        [paymentId],
      );
      const rows: Array<{ id: string }> = await dataSource.query(
        `INSERT INTO refunds (order_id,payment_transaction_id,amount_minor,reason,status,idempotency_key)
       VALUES ($1,$2,1500,'test','requested','refund-a'),($1,$2,1500,'test','requested','refund-b') RETURNING id`,
        [orderId, paymentId],
      );
      provider.refundPayment.mockResolvedValue({
        status: 'refunded',
        providerRefundId: 'provider-refund',
      });
      const service = new RefundsService(dataSource, provider);
      const results = await Promise.allSettled(
        rows.map(({ id }) => service.approve(id)),
      );
      expect(
        results.filter(({ status }) => status === 'fulfilled'),
      ).toHaveLength(1);
      expect(
        results.filter(({ status }) => status === 'rejected'),
      ).toHaveLength(1);
      const [{ total }] = await dataSource.query(
        `SELECT COALESCE(SUM(amount_minor),0)::int total FROM refunds WHERE status='refunded'`,
      );
      expect(total).toBe(1500);
      expect(provider.refundPayment).toHaveBeenCalledTimes(1);
    });

    it('records a provider refund failure without falsely increasing refunded state', async () => {
      const [{ id }] = await dataSource.query(
        `INSERT INTO refunds (order_id,payment_transaction_id,amount_minor,reason,status,idempotency_key)
       VALUES ($1,$2,500,'failure-test','requested','refund-failure') RETURNING id`,
        [orderId, paymentId],
      );
      provider.refundPayment.mockRejectedValueOnce(
        new Error('provider detail'),
      );
      await expect(
        new RefundsService(dataSource, provider).approve(id),
      ).rejects.toThrow();
      const [refund] = await dataSource.query(
        `SELECT status FROM refunds WHERE id=$1`,
        [id],
      );
      const [payment] = await dataSource.query(
        `SELECT status FROM payment_transactions WHERE id=$1`,
        [paymentId],
      );
      expect(refund.status).toBe('failed');
      expect(payment.status).toBe('partially_refunded');
    });
  },
);
