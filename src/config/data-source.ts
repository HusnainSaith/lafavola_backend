import 'dotenv/config';
import { join } from 'path';
import { DataSource } from 'typeorm';

export const AppDataSource = new DataSource({
  type: 'postgres',

  host: process.env.DB_HOST,
  port: Number(process.env.DB_PORT),
  username: process.env.DB_USERNAME,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_DATABASE,

  entities: [join(__dirname, '../**/*.entity{.ts,.js}')],

  migrations: [join(__dirname, '../database/migrations/*{.ts,.js}')],

  synchronize: false,
  logging: process.env.NODE_ENV === 'development',
});
