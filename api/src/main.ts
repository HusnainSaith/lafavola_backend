import { ForbiddenException, Logger } from '@nestjs/common';
import { NestFactory } from '@nestjs/core';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';
import { AppModule } from './app.module';
import { GlobalValidationPipe } from './common/pipes/global-validation.pipe';
// import { SecurityConfig } from './config/security.config';
import helmet from 'helmet';
import { labelSwaggerAudiences } from './config/swagger-audience';

function getAllowedOrigins() {
  // FRONTEND_URLS as comma-separated list
  const list = (process.env.FRONTEND_URLS || '')
    .split(',')
    .map((s) => s.trim())
    .filter(Boolean);

  // The Swagger UI is served by the API itself, so its browser requests carry
  // the API public origin. Configure this non-secret value in production.
  const apiPublicUrl = process.env.API_PUBLIC_URL?.trim().replace(/\/$/, '');
  if (apiPublicUrl) list.push(apiPublicUrl);

  // Swagger runs from the API origin. In development this needs to include
  // the local API host so Swagger's own Execute button is not blocked. Keep
  // production origins explicit through FRONTEND_URLS.
  if (process.env.NODE_ENV !== 'production') {
    const port = process.env.PORT || '3000';
    list.push(`http://localhost:${port}`, `http://127.0.0.1:${port}`);
  }
  return [...new Set(list)];
}

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  app.enableShutdownHooks();

  // URI versioning gives mobile clients a stable contract. New mobile/admin
  // integrations must target /api/v1; breaking changes belong in /api/v2.
  app.setGlobalPrefix('api/v1');

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
    allowedHeaders:
      'Content-Type, Authorization, X-Correlation-Id, Idempotency-Key',
    exposedHeaders: 'Authorization',
  });

  // Global validation pipe with strict validation
  app.useGlobalPipes(new GlobalValidationPipe());

  // Swagger documentation with proper bearer auth configuration
  const config = new DocumentBuilder()
    .setTitle('La Favola Pizza Restaurant API')
    .setDescription(
      'Routes are grouped by audience. Customer app developers should use sections prefixed "Customer App" and "Audience: Public / Customer App". Administrative and staff operations declare their required roles in their Audience tag and x-required-roles metadata.',
    )
    .setVersion('1.0')
    .addTag('Audience: Public / Customer App', 'No login required')
    .addTag('Audience: Admin App', 'Requires the admin role')
    .addTag('Audience: Support App', 'Requires the support role')
    .addTag(
      'Audience: Employee / Driver App',
      'Requires the employee/driver role',
    )
    .addBearerAuth(
      { type: 'http', scheme: 'bearer', bearerFormat: 'JWT' },
      'JWT-auth',
    )
    .addSecurityRequirements('JWT-auth')
    .build();

  const document = SwaggerModule.createDocument(app, config);
  labelSwaggerAudiences(document);
  const http = app.getHttpAdapter().getInstance();
  http.get('/api/docs', (_request, response) => {
    response.redirect(308, '/api/v1/docs');
  });
  http.get('/api/docs-json', (_request, response) => {
    response.redirect(308, '/api/v1/docs-json');
  });
  app.use('/api/v1/docs', (_request, response, next) => {
    response.setHeader(
      'Cache-Control',
      'no-store, no-cache, must-revalidate, proxy-revalidate',
    );
    response.setHeader('Pragma', 'no-cache');
    response.setHeader('Expires', '0');
    next();
  });
  SwaggerModule.setup('api/v1/docs', app, document, {
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

  const configuredOrigin = process.env.API_PUBLIC_URL?.trim().replace(
    /\/$/,
    '',
  );
  const serverOrigin =
    configuredOrigin || `http://localhost:${String(port)}`;
  Logger.log(`Server URL:     ${serverOrigin}`, 'Bootstrap');
  Logger.log(`API base URL:   ${serverOrigin}/api/v1`, 'Bootstrap');
  Logger.log(`Swagger UI URL: ${serverOrigin}/api/v1/docs`, 'Bootstrap');
}
void bootstrap();
