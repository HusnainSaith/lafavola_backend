import { DataSource } from 'typeorm';
import {
  createTestDataSource,
  ensureTestDatabase,
  resetIsolatedTestDatabase,
} from '../utils/test-data-source';

jest.setTimeout(120000);
const enabled = process.env.RUN_DB_TESTS === 'true';

(enabled ? describe : describe.skip)(
  'final PostgreSQL integrity regression',
  () => {
    let dataSource: DataSource;
    let roleId: string;
    let userId: string;

    beforeAll(async () => {
      dataSource = createTestDataSource(await ensureTestDatabase());
      await resetIsolatedTestDatabase(dataSource);
      await dataSource.runMigrations({ transaction: 'each' });
      [{ id: roleId }] = await dataSource.query(
        `INSERT INTO roles(name,is_system) VALUES ('integrity_customer',true) RETURNING id`,
      );
      [{ id: userId }] = await dataSource.query(
        `INSERT INTO users(email,phone,full_name,role_id) VALUES ('unique@example.com','+390001','Integrity User',$1) RETURNING id`,
        [roleId],
      );
    });

    afterAll(async () => {
      if (dataSource?.isInitialized) await dataSource.destroy();
    });

    it('enforces case-insensitive email and phone uniqueness', async () => {
      await expect(
        dataSource.query(
          `INSERT INTO users(email,full_name,role_id) VALUES ('UNIQUE@example.com','Duplicate',$1)`,
          [roleId],
        ),
      ).rejects.toMatchObject({ code: '23505' });
      await expect(
        dataSource.query(
          `INSERT INTO users(phone,full_name,role_id) VALUES ('+390001','Duplicate',$1)`,
          [roleId],
        ),
      ).rejects.toMatchObject({ code: '23505' });
    });

    it('enforces role-permission and active default-address uniqueness', async () => {
      const [{ id: permissionId }] = await dataSource.query(
        `INSERT INTO permissions(name,resource,action) VALUES ('integrity.read','integrity','read') RETURNING id`,
      );
      await dataSource.query(
        `INSERT INTO role_permissions(role_id,permission_id) VALUES ($1,$2)`,
        [roleId, permissionId],
      );
      await expect(
        dataSource.query(
          `INSERT INTO role_permissions(role_id,permission_id) VALUES ($1,$2)`,
          [roleId, permissionId],
        ),
      ).rejects.toMatchObject({ code: '23505' });

      const address = [userId, 'Via Roma 1', 'Roma', '00100'];
      await dataSource.query(
        `INSERT INTO customer_addresses(customer_id,address_line1,city,postal_code,is_default) VALUES ($1,$2,$3,$4,true)`,
        address,
      );
      await expect(
        dataSource.query(
          `INSERT INTO customer_addresses(customer_id,address_line1,city,postal_code,is_default) VALUES ($1,$2,$3,$4,true)`,
          address,
        ),
      ).rejects.toMatchObject({ code: '23505' });
    });

    it('enforces notification delivery idempotency and foreign keys', async () => {
      const [{ id: notificationId }] = await dataSource.query(
        `INSERT INTO notifications(user_id,type,title,body,event_key) VALUES ($1,'system','Test','Test','integrity-event') RETURNING id`,
        [userId],
      );
      const [{ id: deviceId }] = await dataSource.query(
        `INSERT INTO device_tokens(user_id,platform,token) VALUES ($1,'ios','integrity-device') RETURNING id`,
        [userId],
      );
      await dataSource.query(
        `INSERT INTO notification_deliveries(notification_id,device_token_id,channel) VALUES ($1,$2,'push')`,
        [notificationId, deviceId],
      );
      await expect(
        dataSource.query(
          `INSERT INTO notification_deliveries(notification_id,device_token_id,channel) VALUES ($1,$2,'push')`,
          [notificationId, deviceId],
        ),
      ).rejects.toMatchObject({ code: '23505' });
      await expect(
        dataSource.query(
          `INSERT INTO privacy_requests(user_id,request_type) VALUES ('00000000-0000-0000-0000-000000000001','export')`,
        ),
      ).rejects.toMatchObject({ code: '23503' });
    });

    it('persists consent withdrawal and privacy requests as an audit trail', async () => {
      await dataSource.query(
        `INSERT INTO privacy_consents(user_id,consent_type,policy_version,granted,withdrawn_at) VALUES ($1,'marketing','v1',false,NOW())`,
        [userId],
      );
      await dataSource.query(
        `INSERT INTO privacy_requests(user_id,request_type) VALUES ($1,'export')`,
        [userId],
      );
      const [result] = await dataSource.query(
        `SELECT
        (SELECT COUNT(*)::int FROM privacy_consents WHERE user_id=$1) AS consents,
        (SELECT COUNT(*)::int FROM privacy_requests WHERE user_id=$1 AND status='pending') AS requests`,
        [userId],
      );
      expect(result).toEqual({ consents: 1, requests: 1 });
    });
  },
);
