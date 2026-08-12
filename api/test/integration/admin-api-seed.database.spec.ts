import { INestApplication } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import * as bcrypt from 'bcryptjs';
import { randomBytes } from 'node:crypto';
import { DataSource } from 'typeorm';
import { seedAdminDemo } from '../../scripts/seed-admin-demo-via-api';
import { GlobalValidationPipe } from '../../src/common/pipes/global-validation.pipe';
import {
  createTestDataSource,
  ensureTestDatabase,
  resetIsolatedTestDatabase,
} from '../utils/test-data-source';

jest.setTimeout(180_000);
const enabled = process.env.RUN_DB_TESTS === 'true';

(enabled ? describe : describe.skip)(
  'admin demo seed through authenticated HTTP (PostgreSQL)',
  () => {
    let app: INestApplication;
    let database: DataSource;
    const adminEmail = 'api-seed-admin@lafavola.test';
    const adminPassword = `${randomBytes(24).toString('base64url')}Aa1!`;
    const demoPassword = `${randomBytes(24).toString('base64url')}Aa1!`;

    beforeAll(async () => {
      const testDatabase = await ensureTestDatabase();
      database = createTestDataSource(testDatabase);
      await resetIsolatedTestDatabase(database);
      await database.runMigrations({ transaction: 'each' });

      process.env.NODE_ENV = 'test';
      process.env.DB_DATABASE = testDatabase;
      process.env.MAIL_ENABLED = 'false';
      process.env.AWS_S3_ENABLED = 'false';
      process.env.SUMUP_ENABLED = 'false';
      process.env.AWS_REALTIME_ENABLED = 'false';
      process.env.PUSH_ENABLED = 'false';

      const [restaurant] = await database.query(
        `INSERT INTO restaurants (name,slug)
         VALUES ('La Favola Restaurant','la-favola-restaurant')
         RETURNING id`,
      );
      const [adminRole] = await database.query(
        `SELECT id FROM roles WHERE name='admin'`,
      );
      const [admin] = await database.query(
        `INSERT INTO users (email,password,full_name,role_id,status,email_verified_at)
         VALUES ($1,$2,'API Seed Administrator',$3,'active',CURRENT_TIMESTAMP)
         RETURNING id`,
        [adminEmail, await bcrypt.hash(adminPassword, 10), adminRole.id],
      );
      await database.query(
        `INSERT INTO permissions (name,description,resource,action)
         VALUES
           ('roles.read','Read roles','roles','read'),
           ('users.read','Read users','users','read'),
           ('users.create','Create users','users','create')
         ON CONFLICT (name) DO NOTHING`,
      );
      await database.query(
        `INSERT INTO role_permissions (role_id,permission_id)
         SELECT $1,p.id FROM permissions p
         WHERE p.name IN ('roles.read','users.read','users.create')
         ON CONFLICT (role_id,permission_id) DO NOTHING`,
        [adminRole.id],
      );
      await database.query(
        `INSERT INTO staff_members
         (user_id,restaurant_id,employee_code,job_title,is_active)
         VALUES ($1,$2,'LF-ADMIN-SEED','Administrator',true)`,
        [admin.id, restaurant.id],
      );

      const { AppModule } = await import('../../src/app.module');
      const module = await Test.createTestingModule({
        imports: [AppModule],
      }).compile();
      app = module.createNestApplication();
      app.useGlobalPipes(new GlobalValidationPipe());
      await app.listen(0, '127.0.0.1');
    });

    afterAll(async () => {
      if (app) await app.close();
      if (database?.isInitialized) await database.destroy();
    });

    it('copies the public menu and representative app data using API writes only', async () => {
      const baseUrl = await app.getUrl();
      const first = await seedAdminDemo({
        baseUrl,
        adminEmail,
        adminPassword,
        demoPassword,
        namespace: 'e2e-admin-seed',
      });
      expect(first).toMatchObject({
        success: true,
        transport: 'authenticated HTTP only',
        categories: 5,
        menuItems: 48,
        ingredients: 10,
        drivers: 1,
        customers: 1,
        posOrders: 2,
        deliveryOrders: 1,
        supportTickets: 1,
      });

      const second = await seedAdminDemo({
        baseUrl,
        adminEmail,
        adminPassword,
        demoPassword,
        namespace: 'e2e-admin-seed',
      });
      expect(second.menuCreated).toBe(0);
      expect(second.menuUpdated).toBe(48);

      const [counts] = await database.query(`
        SELECT
          (SELECT COUNT(*)::int FROM menu_categories) AS categories,
          (SELECT COUNT(*)::int FROM menu_items) AS menu_items,
          (SELECT COUNT(*)::int FROM ingredients) AS ingredients,
          (SELECT COUNT(*)::int FROM staff_members WHERE LOWER(job_title)='driver') AS drivers,
          (SELECT COUNT(*)::int FROM users u JOIN roles r ON r.id=u.role_id WHERE r.name='client') AS customers,
          (SELECT COUNT(*)::int FROM orders) AS orders,
          (SELECT COUNT(*)::int FROM support_tickets) AS support_tickets
      `);
      expect(counts).toEqual({
        categories: 5,
        menu_items: 48,
        ingredients: 10,
        drivers: 1,
        customers: 1,
        orders: 3,
        support_tickets: 1,
      });
    });
  },
);
