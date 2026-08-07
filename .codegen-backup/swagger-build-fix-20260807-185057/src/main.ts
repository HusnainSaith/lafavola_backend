import { NestFactory } from '@nestjs/core';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';
import { AppModule } from './app.module';
import { HttpExceptionFilter } from './common/filters/http-exception.filter';
import { GlobalValidationPipe } from './common/pipes/global-validation.pipe';
// import { SecurityConfig } from './config/security.config';
import helmet from 'helmet';
import rateLimit from 'express-rate-limit';

function getAllowedOrigins() {
  // FRONTEND_URLS as comma-separated list
  const list = (process.env.FRONTEND_URLS || '')
    .split(',')
    .map((s) => s.trim())
    .filter(Boolean);

  // Add your API/Swagger and frontend domains explicitly
  // (adjust these to your real domains)
  const extra = [
    'https://adminapi.labverse.org', // API+Swagger origin
    'http://localhost:3000', // Local dev
    'https://labverse.org',
    'https://www.labverse.org',
  ];
  for (const e of extra) if (!list.includes(e)) list.push(e);
  return list;
}

async function bootstrap() {
  const app = await NestFactory.create(AppModule);

  app.getHttpAdapter().getInstance().set('trust proxy', 1);
  // Security middleware
  app.use(
    helmet({
      contentSecurityPolicy: {
        useDefaults: true,
        directives: {
          'img-src': ["'self'", 'data:', 'https:'],
          'script-src': ["'self'", "'unsafe-inline'"],
          'style-src': ["'self'", "'unsafe-inline'"],
        },
      },
      crossOriginEmbedderPolicy: false,
      crossOriginOpenerPolicy: { policy: 'same-origin-allow-popups' },
    }),
  );

  // Rate limit (be gentle for Swagger)
  app.use(
    rateLimit({
      windowMs: 60 * 1000,
      limit: 300,
      standardHeaders: true,
      legacyHeaders: false,
    }),
  );

  const allowed = getAllowedOrigins();
  app.enableCors({
    origin: (origin, cb) => {
      if (!origin) return cb(null, true);
      if (allowed.includes(origin)) return cb(null, true);
      return cb(new Error(`CORS blocked for origin: ${origin}`), false);
    },
    credentials: true,
    methods: 'GET,HEAD,PUT,PATCH,POST,DELETE,OPTIONS',
    allowedHeaders: 'Content-Type, Authorization',
    exposedHeaders: 'Authorization',
  });

  // Global validation pipe with strict validation
  app.useGlobalPipes(new GlobalValidationPipe());
  // Global exception filter
  app.useGlobalFilters(new HttpExceptionFilter());

  // Swagger documentation with proper bearer auth configuration
  const config = new DocumentBuilder()
    .setTitle('LabVerse API')
    .setDescription('Complete project management and CRM system API')
    .setVersion('1.0')
    .addBearerAuth(
      { type: 'http', scheme: 'bearer', bearerFormat: 'JWT' },
      'JWT-auth',
    )
    .build();

  const document = SwaggerModule.createDocument(app, config);
  SwaggerModule.setup('api/docs', app, document, {
    swaggerOptions: {
      persistAuthorization: true,
    },
  });

  const port = process.env.PORT || 3001;
  await app.listen(port);
  console.log(`Application is running on: http://localhost:${port}`);
  console.log(`Swagger docs available at: http://localhost:${port}/api/docs`);
}
bootstrap();
