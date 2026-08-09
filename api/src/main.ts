import { ForbiddenException } from '@nestjs/common';
import { NestFactory } from '@nestjs/core';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';
import { AppModule } from './app.module';
import { GlobalValidationPipe } from './common/pipes/global-validation.pipe';
// import { SecurityConfig } from './config/security.config';
import helmet from 'helmet';

function getAllowedOrigins() {
  // FRONTEND_URLS as comma-separated list
  const list = (process.env.FRONTEND_URLS || '')
    .split(',')
    .map((s) => s.trim())
    .filter(Boolean);

  // Add your API/Swagger and frontend domains explicitly
  // (adjust these to your real domains)
  return list;
}

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  app.enableShutdownHooks();

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

  const allowed = getAllowedOrigins();
  app.enableCors({
    origin: (origin, cb) => {
      if (!origin) return cb(null, true);
      if (allowed.includes(origin)) return cb(null, true);
      return cb(
        new ForbiddenException(`CORS blocked for origin: ${origin}`),
        false,
      );
    },
    credentials: true,
    methods: 'GET,HEAD,PUT,PATCH,POST,DELETE,OPTIONS',
    allowedHeaders: 'Content-Type, Authorization',
    exposedHeaders: 'Authorization',
  });

  // Global validation pipe with strict validation
  app.useGlobalPipes(new GlobalValidationPipe());

  // Swagger documentation with proper bearer auth configuration
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
  app.use('/api/docs', (_request, response, next) => {
    response.setHeader(
      'Cache-Control',
      'no-store, no-cache, must-revalidate, proxy-revalidate',
    );
    response.setHeader('Pragma', 'no-cache');
    response.setHeader('Expires', '0');
    next();
  });
  SwaggerModule.setup('api/docs', app, document, {
    swaggerOptions: {
      persistAuthorization: true,
      requestInterceptor: (request: {
        headers: Record<string, string | undefined>;
      }) => {
        if (!request.headers.Authorization) {
          try {
            const swaggerWindow = window as unknown as {
              ui?: {
                authSelectors?: {
                  authorized?: () => {
                    toJS?: () => Record<string, { value?: string }>;
                  };
                };
              };
              localStorage: Storage;
            };
            const activeAuthorization =
              swaggerWindow.ui?.authSelectors?.authorized?.()?.toJS?.() ?? {};
            const savedAuthorization = JSON.parse(
              swaggerWindow.localStorage.getItem('authorized') || '{}',
            ) as Record<string, { value?: string }>;
            const token = (
              activeAuthorization['JWT-auth']?.value ??
              savedAuthorization['JWT-auth']?.value
            )?.trim();
            if (token) {
              request.headers.Authorization = /^Bearer\s/i.test(token)
                ? token
                : `Bearer ${token}`;
            }
          } catch {
            // Swagger UI will surface the normal 401 response when no valid
            // persisted authorization value is available.
          }
        }
        return request;
      },
    },
  });

  const port = process.env.PORT || 3001;
  await app.listen(port);
}
bootstrap();
