import * as dotenv from 'dotenv';
import { join, resolve } from 'path';
import { DataSource } from 'typeorm';
import { SnakeNamingStrategy } from 'typeorm-naming-strategies';

// The TypeORM CLI does not bootstrap Nest's ConfigModule. Load the same files
// explicitly, relative to the API directory from which npm invokes the CLI.
dotenv.config({
  path: [resolve(process.cwd(), '.env.local'), resolve(process.cwd(), '.env')],
});

function requiredEnvironmentValue(name: string): string {
  const value = process.env[name];
  if (typeof value !== 'string' || !value.trim()) {
    throw new Error(
      `Missing required environment variable ${name}. ` +
        `Run the migration from the API directory containing .env (current directory: ${process.cwd()}).`,
    );
  }
  return value;
}

export const AppDataSource = new DataSource({
  type: 'postgres',

  host: requiredEnvironmentValue('DB_HOST'),
  port: Number(requiredEnvironmentValue('DB_PORT')),
  username: requiredEnvironmentValue('DB_USERNAME'),
  password: requiredEnvironmentValue('DB_PASSWORD'),
  database: requiredEnvironmentValue('DB_DATABASE'),

  entities: [join(__dirname, '../**/*.entity{.ts,.js}')],

  migrations: [join(__dirname, '../database/migrations/*{.ts,.js}')],

  synchronize: false,
  logging: process.env.TYPEORM_LOGGING === 'true',
  namingStrategy: new SnakeNamingStrategy(),
  ssl: process.env.DB_SSL === 'true' ? { rejectUnauthorized: false } : false,
});
