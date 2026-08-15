import { DataSource } from 'typeorm';
import {
  createTestDataSource,
  ensureTestDatabase,
  resetIsolatedTestDatabase,
} from '../utils/test-data-source';

jest.setTimeout(120000);

const enabled = process.env.RUN_DB_TESTS === 'true';
const expectedTables = [
  'users',
  'roles',
  'permissions',
  'customer_profiles',
  'customer_addresses',
  'restaurants',
  'menu_items',
  'ingredients',
  'option_groups',
  'carts',
  'promotions',
  'coupons',
  'orders',
  'payment_transactions',
  'delivery_tracking',
  'notifications',
  'favorites',
  'loyalty_accounts',
  'support_tickets',
  'audit_logs',
  'idempotency_keys',
  'outbox_events',
];

(enabled ? describe : describe.skip)('fresh database migrations', () => {
  let dataSource: DataSource;

  beforeAll(async () => {
    const database = await ensureTestDatabase();
    dataSource = createTestDataSource(database);
    await resetIsolatedTestDatabase(dataSource);
  });

  afterAll(async () => {
    if (dataSource?.isInitialized) await dataSource.destroy();
  });

  it('discovers and applies every migration with synchronize disabled', async () => {
    expect(dataSource.options.synchronize).toBe(false);
    const migrationCount = dataSource.migrations.length;
    expect(migrationCount).toBeGreaterThan(0);
    const executed = await dataSource.runMigrations({ transaction: 'each' });
    expect(executed).toHaveLength(migrationCount);

    const rows: Array<{ table_name: string }> = await dataSource.query(
      `SELECT table_name FROM information_schema.tables
       WHERE table_schema = 'public' AND table_name = ANY($1)`,
      [expectedTables],
    );
    expect(new Set(rows.map((row) => row.table_name))).toEqual(
      new Set(expectedTables),
    );
  });

  it('has no pending migrations on the second run', async () => {
    expect(await dataSource.showMigrations()).toBe(false);
    expect(await dataSource.runMigrations({ transaction: 'each' })).toEqual([]);
  });
});
