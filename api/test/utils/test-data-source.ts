import 'dotenv/config';
import { Client } from 'pg';
import { join } from 'path';
import { DataSource } from 'typeorm';

export function getTestDatabaseName(): string {
  const name = process.env.DB_TEST_DATABASE?.trim();
  if (!name || !name.toLowerCase().endsWith('_test')) {
    throw new Error(
      'DB_TEST_DATABASE must be explicitly set and end with `_test`',
    );
  }
  if (name === process.env.DB_DATABASE) {
    throw new Error('DB_TEST_DATABASE must not equal DB_DATABASE');
  }
  return name;
}

function ssl() {
  return process.env.DB_SSL === 'true'
    ? { rejectUnauthorized: false as const }
    : false;
}

export async function ensureTestDatabase(): Promise<string> {
  const database = getTestDatabaseName();
  const client = new Client({
    host: process.env.DB_HOST,
    port: Number(process.env.DB_PORT || 5432),
    user: process.env.DB_USERNAME,
    password: process.env.DB_PASSWORD,
    database: 'postgres',
    ssl: ssl(),
  });
  await client.connect();
  try {
    const exists = await client.query(
      'SELECT 1 FROM pg_database WHERE datname = $1',
      [database],
    );
    if (exists.rowCount === 0) {
      const identifier = `"${database.replace(/"/g, '""')}"`;
      await client.query(`CREATE DATABASE ${identifier}`);
    }
  } finally {
    await client.end();
  }
  return database;
}

export function createTestDataSource(database = getTestDatabaseName()) {
  return new DataSource({
    type: 'postgres',
    host: process.env.DB_HOST,
    port: Number(process.env.DB_PORT || 5432),
    username: process.env.DB_USERNAME,
    password: process.env.DB_PASSWORD,
    database,
    ssl: ssl(),
    entities: [join(__dirname, '../../src/**/*.entity{.ts,.js}')],
    migrations: [join(__dirname, '../../src/database/migrations/*{.ts,.js}')],
    synchronize: false,
    migrationsRun: false,
    logging: false,
  });
}

export async function resetIsolatedTestDatabase(dataSource: DataSource) {
  getTestDatabaseName();
  if (!dataSource.isInitialized) await dataSource.initialize();
  await dataSource.query('DROP SCHEMA IF EXISTS public CASCADE');
  await dataSource.query('CREATE SCHEMA public');
}
