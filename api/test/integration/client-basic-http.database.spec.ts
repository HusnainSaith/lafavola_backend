import { INestApplication } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import * as request from 'supertest';
import { DataSource } from 'typeorm';
import { GlobalValidationPipe } from '../../src/common/pipes/global-validation.pipe';
import {
  createTestDataSource,
  ensureTestDatabase,
  resetIsolatedTestDatabase,
} from '../utils/test-data-source';

jest.setTimeout(120_000);
const enabled = process.env.RUN_DB_TESTS === 'true';

function findValue(value: unknown, key: string): unknown {
  if (!value || typeof value !== 'object') return undefined;
  if (key in value) return (value as Record<string, unknown>)[key];
  for (const child of Object.values(value as Record<string, unknown>)) {
    const found = findValue(child, key);
    if (found !== undefined) return found;
  }
  return undefined;
}

(enabled ? describe : describe.skip)(
  'client basic HTTP journey (PostgreSQL)',
  () => {
    let app: INestApplication;
    let database: DataSource;
    let restaurantId: string;
    let categoryId: string;
    let menuItemId: string;
    let sizeId: string;
    let accessToken: string;
    let refreshToken: string;
    let customerId: string;
    let addressId: string;
    let orderId: string;

    const auth = () => ({ Authorization: `Bearer ${accessToken}` });

    beforeAll(async () => {
      const testDatabase = await ensureTestDatabase();
      database = createTestDataSource(testDatabase);
      await resetIsolatedTestDatabase(database);
      await database.runMigrations({ transaction: 'each' });

      process.env.DB_DATABASE = testDatabase;
      process.env.MAIL_ENABLED = 'false';
      process.env.AWS_S3_ENABLED = 'false';
      process.env.SUMUP_ENABLED = 'false';
      process.env.AWS_REALTIME_ENABLED = 'false';
      process.env.PUSH_ENABLED = 'false';

      [{ id: restaurantId }] = await database.query(
        `INSERT INTO restaurants
         (name,slug,default_delivery_minutes,tax_rate_basis_points,tax_behavior,delivery_fee_minor)
         VALUES ('Client Journey','client-journey',30,1000,'excluded',250) RETURNING id`,
      );
      [{ id: categoryId }] = await database.query(
        `INSERT INTO menu_categories (restaurant_id,name,slug)
         VALUES ($1,'Pizza','pizza') RETURNING id`,
        [restaurantId],
      );
      [{ id: menuItemId }] = await database.query(
        `INSERT INTO menu_items
         (restaurant_id,category_id,name,slug,description,item_type,is_vegetarian,is_popular,preparation_minutes)
         VALUES ($1,$2,'Margherita','margherita','Tomato, mozzarella and basil','standard',true,true,15)
         RETURNING id`,
        [restaurantId, categoryId],
      );
      [{ id: sizeId }] = await database.query(
        `INSERT INTO menu_item_sizes (menu_item_id,size_code,display_name,base_price_minor)
         VALUES ($1,'medium','Medium',1200) RETURNING id`,
        [menuItemId],
      );

      const { AppModule } = await import('../../src/app.module');
      const module = await Test.createTestingModule({
        imports: [AppModule],
      }).compile();
      app = module.createNestApplication();
      app.useGlobalPipes(new GlobalValidationPipe());
      await app.init();
    });

    afterAll(async () => {
      if (app) await app.close();
      if (database?.isInitialized) await database.destroy();
    });

    it('registers, logs in, rotates the session and manages profile/address data', async () => {
      const registration = await request(app.getHttpServer())
        .post('/auth/register')
        .send({
          email: 'journey@example.com',
          phone: '+393331234567',
          password: 'StrongPass123',
          fullName: 'Journey Customer',
        })
        .expect(201);
      customerId = String(findValue(registration.body, 'id'));
      expect(customerId).toMatch(/^[0-9a-f-]{36}$/i);

      await request(app.getHttpServer())
        .post('/auth/register')
        .send({
          email: 'duplicate-phone@example.com',
          phone: '+393331234567',
          password: 'StrongPass123',
          fullName: 'Duplicate Phone',
        })
        .expect(409)
        .expect(({ body }) =>
          expect(body.message).toBe(
            'A user with this phone number already exists',
          ),
        );

      const login = await request(app.getHttpServer())
        .post('/auth/login')
        .send({ email: 'journey@example.com', password: 'StrongPass123' })
        .expect(200);
      accessToken = String(findValue(login.body, 'accessToken'));
      refreshToken = String(findValue(login.body, 'refreshToken'));
      expect(accessToken).toBeTruthy();
      expect(refreshToken).toBeTruthy();

      const refreshed = await request(app.getHttpServer())
        .post('/auth/refresh')
        .send({ refreshToken })
        .expect(200);
      const rotated = String(findValue(refreshed.body, 'refreshToken'));
      expect(rotated).not.toBe(refreshToken);
      await request(app.getHttpServer())
        .post('/auth/refresh')
        .send({ refreshToken })
        .expect(401);
      refreshToken = rotated;
      accessToken = String(findValue(refreshed.body, 'accessToken'));

      await request(app.getHttpServer())
        .patch('/customers/me/profile')
        .set(auth())
        .send({ preferredLanguage: 'it', marketingOptIn: true })
        .expect(200);
      await request(app.getHttpServer())
        .get('/customers/me/profile')
        .set(auth())
        .expect(200);

      const address = await request(app.getHttpServer())
        .post('/customers/me/addresses')
        .set(auth())
        .send({
          label: 'Home',
          recipientName: 'Journey Customer',
          phone: '+393331234567',
          addressLine1: 'Via Roma 1',
          city: 'Milan',
          postalCode: '20100',
          countryCode: 'IT',
          deliveryInstructions: 'Ring the bell',
          isDefault: true,
        })
        .expect(201);
      addressId = String(findValue(address.body, 'id'));
      const [{ defaults }] = await database.query(
        `SELECT COUNT(*)::int defaults FROM customer_addresses WHERE customer_id=$1 AND is_default=true`,
        [customerId],
      );
      expect(defaults).toBe(1);
    });

    it('browses/searches, uses the cart and checks out with authoritative cash totals', async () => {
      const menu = await request(app.getHttpServer())
        .get('/menu')
        .query({ restaurantId, categoryId, vegetarian: true })
        .expect(200);
      expect(JSON.stringify(menu.body)).toContain('Margherita');
      await request(app.getHttpServer())
        .get('/menu/search')
        .query({ restaurantId, q: 'Margherita' })
        .expect(200)
        .expect(({ body }) =>
          expect(JSON.stringify(body)).toContain('Margherita'),
        );
      await request(app.getHttpServer())
        .get('/restaurant/availability')
        .query({ orderType: 'delivery', menuItemId })
        .expect(200)
        .expect(({ body }) => {
          expect(findValue(body, 'timezone')).toBeTruthy();
          expect(findValue(body, 'leadMinutes')).toEqual(expect.any(Number));
          expect(findValue(body, 'serverNow')).toBeTruthy();
        });

      await request(app.getHttpServer())
        .post('/cart/items')
        .query({ restaurantId })
        .set(auth())
        .send({ menuItemId, menuItemSizeId: sizeId, quantity: 1 })
        .expect(201);
      const [{ id: cartId }] = await database.query(
        `SELECT id FROM carts WHERE customer_id=$1 AND restaurant_id=$2 AND status='active'`,
        [customerId, restaurantId],
      );
      const [{ id: cartItemId }] = await database.query(
        `SELECT id FROM cart_items WHERE cart_id=$1`,
        [cartId],
      );
      await request(app.getHttpServer())
        .patch(`/cart/items/${cartItemId}`)
        .set(auth())
        .send({ quantity: 2 })
        .expect(200);

      const checkout = await request(app.getHttpServer())
        .post('/checkout')
        .set(auth())
        .send({
          cartId,
          orderType: 'delivery',
          deliveryAddressId: addressId,
          paymentMethod: 'cash',
          idempotencyKey: 'basic-client-cash-checkout',
        })
        .expect(201);
      expect(findValue(checkout.body, 'orderType')).toBe('delivery');
      expect(findValue(checkout.body, 'serverNow')).toBeTruthy();
      expect(findValue(checkout.body, 'estimatedReadyAt')).toBeTruthy();
      expect(findValue(checkout.body, 'estimatedDeliveryAt')).toBeTruthy();
      orderId = String(findValue(checkout.body, 'orderId'));
      const [order] = await database.query(
        `SELECT subtotal_minor,tax_minor,delivery_fee_minor,grand_total_minor,payment_status,status
         FROM orders WHERE id=$1`,
        [orderId],
      );
      expect(order).toMatchObject({
        subtotal_minor: 2400,
        tax_minor: 265,
        delivery_fee_minor: 250,
        grand_total_minor: 2915,
        payment_status: 'collection_pending',
        status: 'placed',
      });
      expect(orderId).toMatch(/^[0-9a-f-]{36}$/i);
    });

    it('checks out pickup without an address, delivery fee, or raw customer input identifiers', async () => {
      await request(app.getHttpServer())
        .post('/cart/items')
        .query({ restaurantId })
        .set(auth())
        .send({ menuItemId, menuItemSizeId: sizeId, quantity: 1 })
        .expect(201);
      const [{ id: pickupCartId }] = await database.query(
        `SELECT id FROM carts WHERE customer_id=$1 AND restaurant_id=$2 AND status='active'`,
        [customerId, restaurantId],
      );

      const checkout = await request(app.getHttpServer())
        .post('/checkout')
        .set(auth())
        .send({
          cartId: pickupCartId,
          orderType: 'pickup',
          paymentMethod: 'cash',
          idempotencyKey: 'basic-client-pickup-checkout',
        })
        .expect(201);
      orderId = String(findValue(checkout.body, 'orderId'));
      const [order] = await database.query(
        `SELECT order_type,delivery_fee_minor,delivery_address_snapshot,
                estimated_ready_at,estimated_delivery_at
         FROM orders WHERE id=$1`,
        [orderId],
      );
      expect(order).toMatchObject({
        order_type: 'pickup',
        delivery_fee_minor: 0,
        delivery_address_snapshot: null,
        estimated_delivery_at: null,
      });
      expect(order.estimated_ready_at).toBeTruthy();

      const detail = await request(app.getHttpServer())
        .get(`/orders/me/${orderId}`)
        .set(auth())
        .expect(200);
      expect(findValue(detail.body, 'remainingSeconds')).toEqual(
        expect.any(Number),
      );
      const receipt = await request(app.getHttpServer())
        .get(`/orders/me/${orderId}/receipt`)
        .set(auth())
        .expect(200);
      expect(findValue(receipt.body, 'documentType')).toBe('order_receipt');
      expect(findValue(receipt.body, 'fiscalDocument')).toBe(false);
      expect(JSON.stringify(receipt.body)).not.toContain(addressId);
    });

    it('reads owned orders, favorites and quick reorder, then uses support and notifications', async () => {
      await request(app.getHttpServer())
        .get('/orders/me')
        .set(auth())
        .expect(200)
        .expect(({ body }) => expect(JSON.stringify(body)).toContain(orderId));
      await request(app.getHttpServer())
        .get(`/orders/me/${orderId}`)
        .set(auth())
        .expect(200);

      const favorite = await request(app.getHttpServer())
        .post('/favorites')
        .set(auth())
        .send({
          restaurantId,
          menuItemId,
          label: 'My Margherita',
          configurationSnapshot: { menuItemSizeId: sizeId, options: [] },
        })
        .expect(201);
      const favoriteId = String(findValue(favorite.body, 'id'));
      await request(app.getHttpServer())
        .post(`/favorites/${favoriteId}/cart`)
        .set(auth())
        .send({ quantity: 1 })
        .expect(201);
      const [{ count: activeItems }] = await database.query(
        `SELECT COUNT(*)::int count FROM cart_items ci JOIN carts c ON c.id=ci.cart_id
         WHERE c.customer_id=$1 AND c.status='active'`,
        [customerId],
      );
      expect(activeItems).toBe(1);

      const ticket = await request(app.getHttpServer())
        .post('/support/tickets')
        .set(auth())
        .send({
          orderId,
          category: 'order_issue',
          subject: 'Basic journey issue',
          message: 'Please check my order',
        })
        .expect(201);
      const ticketId = String(findValue(ticket.body, 'id'));
      await request(app.getHttpServer())
        .post(`/support/tickets/${ticketId}/messages`)
        .set(auth())
        .send({ body: 'Additional information' })
        .expect(201);
      const [{ messages }] = await database.query(
        `SELECT COUNT(*)::int messages FROM support_messages WHERE ticket_id=$1`,
        [ticketId],
      );
      expect(messages).toBe(2);

      await request(app.getHttpServer())
        .get('/notifications')
        .set(auth())
        .expect(200);
      await request(app.getHttpServer())
        .get('/reports/sales')
        .query({ from: '2026-01-01', to: '2026-12-31' })
        .set(auth())
        .expect(403);
    });

    it('logs out and revokes the final refresh session', async () => {
      await request(app.getHttpServer())
        .post('/auth/logout')
        .set(auth())
        .send({ refreshToken })
        .expect(200);
      await request(app.getHttpServer())
        .post('/auth/refresh')
        .send({ refreshToken })
        .expect(401);
      const [{ active }] = await database.query(
        `SELECT COUNT(*)::int active FROM refresh_tokens WHERE user_id=$1 AND is_revoked=false`,
        [customerId],
      );
      expect(active).toBe(0);
    });
  },
);
