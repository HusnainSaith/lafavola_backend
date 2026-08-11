import { Global, Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { NestFactory } from '@nestjs/core';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';
import { writeFileSync } from 'fs';
import { resolve } from 'path';
import { DataSource } from 'typeorm';
import { AppController } from '../src/app.controller';
import { AppService } from '../src/app.service';
import { BusinessModule } from '../src/modules/business.module';
import { AuthModule } from '../src/modules/auth/auth.module';
import { PermissionsModule } from '../src/modules/permissions/permissions.module';
import { RolePermissionsModule } from '../src/modules/role-permissions/role-permissions.module';
import { RolesModule } from '../src/modules/roles/roles.module';
import { UsersModule } from '../src/modules/users/users.module';
import { PushModule } from '../src/integrations/push/push.module';
import { RealtimeModule } from '../src/integrations/realtime/realtime.module';
import { OutboxModule } from '../src/queue/outbox.module';
import { SharedModule } from '../src/modules/shared/shared.module';

const metadataDataSource = {
  entityMetadatas: [],
  options: { type: 'postgres' },
  getRepository: () => ({}),
  getTreeRepository: () => ({}),
  getMongoRepository: () => ({}),
};

@Global()
@Module({
  providers: [{ provide: DataSource, useValue: metadataDataSource }],
  exports: [DataSource],
})
class MetadataPersistenceModule {}

// The API document is controller metadata, not a runtime health check. Keeping
// the root module free of TypeOrmModule.forRoot avoids requiring local or live
// database secrets solely to regenerate Swagger.
@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      envFilePath: ['.env.local', '.env'],
    }),
    MetadataPersistenceModule,
    SharedModule,
    RealtimeModule,
    PushModule,
    OutboxModule,
    UsersModule,
    RolesModule,
    AuthModule,
    PermissionsModule,
    RolePermissionsModule,
    BusinessModule,
  ],
  controllers: [AppController],
  providers: [AppService],
})
class OpenApiModule {}

async function generate() {
  // Swagger generation only needs controller metadata. Preview mode avoids
  // instantiating database and provider clients, making the contract build
  // deterministic in CI and on developer machines without production secrets.
  const app = await NestFactory.create(OpenApiModule, {
    logger: ['error'],
    abortOnError: false,
    preview: true,
  });
  app.setGlobalPrefix('api/v1');
  const config = new DocumentBuilder()
    .setTitle('La Favola Pizza Restaurant API')
    .setDescription(
      'Customer ordering, pizza customization, checkout, payments, delivery tracking, promotions, support, and restaurant administration API',
    )
    .setVersion('1.0')
    .addBearerAuth(
      { type: 'http', scheme: 'bearer', bearerFormat: 'JWT' },
      'JWT-auth',
    )
    .addSecurityRequirements('JWT-auth')
    .build();
  const document = SwaggerModule.createDocument(app, config);
  writeFileSync(
    resolve(process.cwd(), 'openapi.json'),
    `${JSON.stringify(document, null, 2)}\n`,
  );
  await app.close();
}

generate().catch((error: unknown) => {
  process.stderr.write(
    `${error instanceof Error ? error.message : 'OpenAPI generation failed'}\n`,
  );
  process.exitCode = 1;
});
