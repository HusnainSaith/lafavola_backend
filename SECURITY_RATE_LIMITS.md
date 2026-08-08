# Security Rate Limits

Nest Throttler is the only rate-limiting mechanism. The global policy permits 100 requests per 60 seconds. Authentication routes override it:

| Route | Limit |
|---|---:|
| `POST /auth/register` | 5/minute |
| `POST /auth/login` | 5/minute |
| `POST /auth/refresh` | 10/minute |
| `POST /auth/forgot-password` | 3/minute |
| `POST /auth/reset-password` | 5/minute |
| `POST /support/tickets/:id/messages` | 30/minute |
| `POST /notifications/devices` | 10/minute |

Production deployments running multiple instances should configure a shared throttler store.
