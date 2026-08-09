# La Favola Application Layer Generator

This generated layer implements the NestJS controllers, services, and modules for the restaurant business flow.

## Included

- Restaurant/admin management
- Customer profile/preferences
- Delivery addresses
- Staff
- Menu/categories/ingredients/options
- Pizza builder and server-side pricing
- Cart
- Promotions/coupons
- Checkout transaction and immutable order snapshots
- Order history/status workflow
- Payment transaction persistence
- Pay-on-delivery collection
- Refund request/approval persistence
- Delivery assignment and location history
- Notifications/device tokens/preferences
- Favorites
- Loyalty balance/history/redemption
- Support tickets/messages
- FAQ
- Reports
- Audit service
- A single `BusinessModule` for easy root-module wiring

## Important third-party boundary

The generated application layer intentionally does not fake external provider behavior.

The following integrations still need their real provider adapters:
- Stripe PaymentIntent creation/confirmation and signature-verified webhooks
- AWS S3 presigned URL generation
- AWS SMS / End User Messaging
- Amazon SES or configured email provider
- Firebase Cloud Messaging delivery
- Google identity-token verification
- Apple identity-token verification

The services persist the required state and expose the correct business boundaries, but external provider calls must be implemented with real SDKs and credentials.

## Root module

After generation, import `BusinessModule` into `src/app.module.ts`.

```ts
import { BusinessModule } from './modules/business.module';

@Module({
  imports: [
    // existing ConfigModule, TypeOrmModule, AuthModule, RBAC modules...
    BusinessModule,
  ],
})
export class AppModule {}
```

## Run checks

```powershell
npm run format
npm run lint:check
npm run build
```

Then fix any mismatch caused by changes made to DTO/entity names after the domain generator was produced.
