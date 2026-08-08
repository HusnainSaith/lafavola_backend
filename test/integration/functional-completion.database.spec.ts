import { ConfigService } from '@nestjs/config';
import { DataSource } from 'typeorm';
import { OutboxService } from '../../src/queue/outbox.service';
import { CustomersService } from '../../src/modules/customers/customers.service';
import { CustomerProfileRepository } from '../../src/modules/customers/repositories/customer-profile.repository';
import { PrivacyRequestType } from '../../src/modules/customers/enums/privacy-request-type.enum';
import { DeliveriesService } from '../../src/modules/deliveries/deliveries.service';
import { DeliveryAssignmentStatus } from '../../src/modules/deliveries/enums/delivery-assignment-status.enum';
import { DeliveryTrackingRepository } from '../../src/modules/deliveries/repositories/delivery-tracking.repository';
import { PaymentMethodType } from '../../src/modules/payments/enums/payment-method-type.enum';
import { PaymentsService } from '../../src/modules/payments/payments.service';
import { PaymentTransactionRepository } from '../../src/modules/payments/repositories/payment-transaction.repository';
import { ReportsService } from '../../src/modules/reports/reports.service';
import {
  createTestDataSource,
  ensureTestDatabase,
  resetIsolatedTestDatabase,
} from '../utils/test-data-source';

jest.setTimeout(120000);
const enabled = process.env.RUN_DB_TESTS === 'true';

(enabled ? describe : describe.skip)(
  'functional completion PostgreSQL flows',
  () => {
    let db: DataSource;
    let customerId: string;
    let driverId: string;
    let otherDriverId: string;
    let adminId: string;
    let restaurantId: string;
    const outbox = new OutboxService();

    beforeAll(async () => {
      db = createTestDataSource(await ensureTestDatabase());
      await resetIsolatedTestDatabase(db);
      await db.runMigrations({ transaction: 'each' });
      const [{ id: customerRole }, { id: employeeRole }, { id: adminRole }] =
        await db.query(
          `INSERT INTO roles(name,is_system) VALUES ('client',true),('employee',true),('admin',true) RETURNING id`,
        );
      [
        { id: customerId },
        { id: driverId },
        { id: otherDriverId },
        { id: adminId },
      ] = await db.query(
        `INSERT INTO users(email,full_name,role_id) VALUES
         ('flow-customer@example.com','Customer',$1),
         ('flow-driver@example.com','Driver',$2),
         ('flow-driver-2@example.com','Other Driver',$2),
         ('flow-admin@example.com','Admin',$3) RETURNING id`,
        [customerRole, employeeRole, adminRole],
      );
      [{ id: restaurantId }] = await db.query(
        `INSERT INTO restaurants(name,slug,country_code,currency,timezone,default_delivery_minutes,delivery_fee_minor,minimum_order_minor,tax_rate_basis_points,tax_behavior)
       VALUES ('Flow Restaurant','flow','IT','EUR','Europe/Rome',30,100,0,1000,'excluded') RETURNING id`,
      );
    });

    afterAll(async () => {
      if (db?.isInitialized) await db.destroy();
    });

    async function insertOrder(
      suffix: string,
      values: {
        restaurant?: string;
        customer?: string;
        status: string;
        paymentStatus: string;
        paymentMethod: string;
        subtotal: number;
        options?: number;
        discount?: number;
        delivery?: number;
        tax?: number;
        grand: number;
        createdAt?: string;
      },
    ) {
      const [order] = await db.query(
        `INSERT INTO orders(order_number,restaurant_id,customer_id,order_type,status,payment_status,payment_method,currency,
        subtotal_minor,option_charges_minor,discount_minor,promotion_discount_minor,coupon_discount_minor,loyalty_discount_minor,
        delivery_fee_minor,tax_minor,grand_total_minor,delivery_address_snapshot,pricing_snapshot,version,created_at)
       VALUES ($1,$2,$3,'delivery',$4,$5,$6,'EUR',$7,$8,$9,0,0,0,$10,$11,$12,'{}','{}',1,COALESCE($13::timestamptz,NOW())) RETURNING id`,
        [
          `FLOW-${suffix}`,
          values.restaurant ?? restaurantId,
          values.customer ?? customerId,
          values.status,
          values.paymentStatus,
          values.paymentMethod,
          values.subtotal,
          values.options ?? 0,
          values.discount ?? 0,
          values.delivery ?? 0,
          values.tax ?? 0,
          values.grand,
          values.createdAt ?? null,
        ],
      );
      return order.id as string;
    }

    it('synchronizes delivery, pay-on-delivery, receipt, history and outbox state', async () => {
      const orderId = await insertOrder('DELIVERY', {
        status: 'ready',
        paymentStatus: 'collection_pending',
        paymentMethod: 'cash',
        subtotal: 1000,
        delivery: 100,
        tax: 100,
        grand: 1200,
      });
      const delivery = new DeliveriesService(
        db,
        new DeliveryTrackingRepository(db),
        outbox,
      );
      await delivery.assign(orderId, adminId, { driverUserId: driverId });
      await expect(
        delivery.transition(
          orderId,
          DeliveryAssignmentStatus.ACCEPTED,
          otherDriverId,
        ),
      ).rejects.toBeDefined();
      await delivery.transition(
        orderId,
        DeliveryAssignmentStatus.ACCEPTED,
        driverId,
      );
      await delivery.transition(
        orderId,
        DeliveryAssignmentStatus.PICKED_UP,
        driverId,
      );
      await delivery.transition(
        orderId,
        DeliveryAssignmentStatus.EN_ROUTE,
        driverId,
      );
      await expect(
        delivery.transition(
          orderId,
          DeliveryAssignmentStatus.DELIVERED,
          driverId,
        ),
      ).rejects.toBeDefined();

      const payments = new PaymentsService(
        db,
        new PaymentTransactionRepository(db),
        new ConfigService({}),
        outbox,
        {} as never,
      );
      const paymentDto = {
        orderId,
        paymentMethodType: PaymentMethodType.CASH,
        idempotencyKey: 'flow-cash-collection',
      };
      await expect(
        payments.collectOnDelivery(orderId, otherDriverId, paymentDto),
      ).rejects.toBeDefined();
      const collections = await Promise.allSettled([
        payments.collectOnDelivery(orderId, driverId, paymentDto),
        payments.collectOnDelivery(orderId, driverId, {
          ...paymentDto,
          idempotencyKey: 'flow-cash-collection-race',
        }),
      ]);
      expect(
        collections.filter((result) => result.status === 'fulfilled'),
      ).toHaveLength(1);
      const payment = (
        collections.find((result) => result.status === 'fulfilled') as {
          status: 'fulfilled';
          value: { amountMinor: number };
        }
      ).value;
      expect(payment.amountMinor).toBe(1200);
      await expect(
        payments.collectOnDelivery(orderId, driverId, paymentDto),
      ).rejects.toBeDefined();
      await delivery.transition(
        orderId,
        DeliveryAssignmentStatus.ARRIVING,
        driverId,
      );
      await delivery.transition(
        orderId,
        DeliveryAssignmentStatus.DELIVERED,
        driverId,
      );
      const [state] = await db.query(
        `SELECT o.status,o.payment_status AS "paymentStatus",da.status AS delivery,
        (SELECT COUNT(*)::int FROM payment_receipts WHERE order_id=o.id) AS receipts,
        (SELECT COUNT(*)::int FROM order_status_history WHERE order_id=o.id) AS history,
        (SELECT COUNT(*)::int FROM delivery_tracking_events e JOIN delivery_tracking t ON t.id=e.tracking_id WHERE t.order_id=o.id) AS events
       FROM orders o JOIN delivery_assignments da ON da.order_id=o.id WHERE o.id=$1`,
        [orderId],
      );
      expect(state).toEqual({
        status: 'delivered',
        paymentStatus: 'paid',
        delivery: 'delivered',
        receipts: 1,
        history: 3,
        events: 5,
      });
    });

    it('serializes concurrent acceptance so only the assigned driver succeeds', async () => {
      const orderId = await insertOrder('ACCEPT-RACE', {
        status: 'ready',
        paymentStatus: 'paid',
        paymentMethod: 'card',
        subtotal: 1000,
        grand: 1000,
      });
      const delivery = new DeliveriesService(
        db,
        new DeliveryTrackingRepository(db),
        outbox,
      );
      await delivery.assign(orderId, adminId, { driverUserId: driverId });
      const results = await Promise.allSettled([
        delivery.transition(
          orderId,
          DeliveryAssignmentStatus.ACCEPTED,
          driverId,
        ),
        delivery.transition(
          orderId,
          DeliveryAssignmentStatus.ACCEPTED,
          otherDriverId,
        ),
      ]);
      expect(
        results.filter((result) => result.status === 'fulfilled'),
      ).toHaveLength(1);
    });

    it('calculates exact recognized, refunded, net and daily report values', async () => {
      const [{ id: reportingRestaurant }] = await db.query(
        `INSERT INTO restaurants(name,slug,country_code,currency,timezone,default_delivery_minutes,delivery_fee_minor,minimum_order_minor,tax_rate_basis_points,tax_behavior)
       VALUES ('Reporting','reporting','IT','EUR','Europe/Rome',25,100,0,1000,'excluded') RETURNING id`,
      );
      const first = await insertOrder('REPORT-1', {
        restaurant: reportingRestaurant,
        status: 'delivered',
        paymentStatus: 'paid',
        paymentMethod: 'card',
        subtotal: 1000,
        options: 100,
        discount: 200,
        delivery: 100,
        tax: 100,
        grand: 1100,
        createdAt: '2026-08-01T12:00:00Z',
      });
      const second = await insertOrder('REPORT-2', {
        restaurant: reportingRestaurant,
        status: 'closed',
        paymentStatus: 'partially_refunded',
        paymentMethod: 'card',
        subtotal: 2000,
        discount: 200,
        delivery: 200,
        tax: 200,
        grand: 2200,
        createdAt: '2026-08-02T12:00:00Z',
      });
      await insertOrder('REPORT-EXCLUDED', {
        restaurant: reportingRestaurant,
        status: 'cancelled',
        paymentStatus: 'paid',
        paymentMethod: 'card',
        subtotal: 9999,
        grand: 9999,
        createdAt: '2026-08-02T12:00:00Z',
      });
      await db.query(
        `INSERT INTO refunds(order_id,amount_minor,reason,status) VALUES ($1,500,'customer_request','refunded')`,
        [second],
      );
      await db.query(
        `INSERT INTO order_items(order_id,item_name_snapshot,quantity,base_unit_price_minor,options_unit_price_minor,unit_price_minor,line_total_minor,configuration_snapshot)
       VALUES ($1,'Margherita',2,500,0,500,1000,'{}'),($2,'Diavola',1,2200,0,2200,2200,'{}')`,
        [first, second],
      );
      const reports = new ReportsService(db);
      const query = {
        restaurantId: reportingRestaurant,
        from: '2026-08-01',
        to: '2026-08-02',
      };
      await expect(reports.sales(query)).resolves.toMatchObject({
        totalOrders: 3,
        successfulOrders: 2,
        grossSalesMinor: 3700,
        recognizedRevenueMinor: 3300,
        discountMinor: 400,
        taxMinor: 300,
        deliveryFeesMinor: 300,
        refundsMinor: 500,
        netRevenueMinor: 2800,
        averageOrderValueMinor: 1650,
      });
      const daily = await reports.dailyRevenue(query);
      expect(daily.map((row) => row.netRevenueMinor)).toEqual([1100, 1700]);
      await expect(reports.popularItems(query)).resolves.toMatchObject([
        { name: 'Margherita', quantity: 2 },
        { name: 'Diavola', quantity: 1 },
      ]);
    });

    it('exports only owned safe data and anonymizes without deleting financial records', async () => {
      await db.query(
        `INSERT INTO customer_profiles(user_id,marketing_opt_in) VALUES ($1,true)`,
        [customerId],
      );
      const service = new CustomersService(
        db,
        new CustomerProfileRepository(db),
      );
      const exportRequest = await service.createPrivacyRequest(customerId, {
        requestType: PrivacyRequestType.EXPORT,
      });
      await expect(
        service.fulfillPrivacyRequest(adminId, exportRequest.id),
      ).rejects.toBeDefined();
      const exported = await service.fulfillPrivacyRequest(
        customerId,
        exportRequest.id,
      );
      expect(JSON.stringify(exported.result)).not.toMatch(
        /password|refresh_token|verification_token/i,
      );
      expect((exported.result.account as { email: string }).email).toBe(
        'flow-customer@example.com',
      );

      const deletion = await service.createPrivacyRequest(customerId, {
        requestType: PrivacyRequestType.DELETION,
      });
      await service.fulfillPrivacyRequest(customerId, deletion.id);
      const [user] = await db.query(
        `SELECT email,phone,password,status,archived_at IS NOT NULL AS archived FROM users WHERE id=$1`,
        [customerId],
      );
      const [{ count: retainedOrders }] = await db.query(
        `SELECT COUNT(*)::int count FROM orders WHERE order_number LIKE 'FLOW-%'`,
      );
      expect(user).toEqual({
        email: null,
        phone: null,
        password: null,
        status: 'deleted',
        archived: true,
      });
      expect(retainedOrders).toBeGreaterThan(0);
    });
  },
);
