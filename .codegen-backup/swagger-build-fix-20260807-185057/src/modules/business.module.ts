import { Module } from '@nestjs/common';
import { RestaurantsModule } from './restaurants/restaurants.module';
import { CustomersModule } from './customers/customers.module';
import { AddressesModule } from './addresses/addresses.module';
import { StaffModule } from './staff/staff.module';
import { MediaModule } from './media/media.module';
import { CategoriesModule } from './categories/categories.module';
import { IngredientsModule } from './ingredients/ingredients.module';
import { MenuModule } from './menu/menu.module';
import { OptionGroupsModule } from './option-groups/option-groups.module';
import { PricingModule } from './pricing/pricing.module';
import { PizzaBuilderModule } from './pizza-builder/pizza-builder.module';
import { CartsModule } from './carts/carts.module';
import { PromotionsModule } from './promotions/promotions.module';
import { CouponsModule } from './coupons/coupons.module';
import { CheckoutModule } from './checkout/checkout.module';
import { OrdersModule } from './orders/orders.module';
import { PaymentsModule } from './payments/payments.module';
import { RefundsModule } from './refunds/refunds.module';
import { DeliveriesModule } from './deliveries/deliveries.module';
import { NotificationsModule } from './notifications/notifications.module';
import { FavoritesModule } from './favorites/favorites.module';
import { LoyaltyModule } from './loyalty/loyalty.module';
import { SupportModule } from './support/support.module';
import { FaqModule } from './faq/faq.module';
import { ReportsModule } from './reports/reports.module';
import { AuditModule } from './audit/audit.module';

@Module({
  imports: [
    AuditModule,
    RestaurantsModule,
    CustomersModule,
    AddressesModule,
    StaffModule,
    MediaModule,
    CategoriesModule,
    IngredientsModule,
    MenuModule,
    OptionGroupsModule,
    PricingModule,
    PizzaBuilderModule,
    CartsModule,
    PromotionsModule,
    CouponsModule,
    CheckoutModule,
    OrdersModule,
    PaymentsModule,
    RefundsModule,
    DeliveriesModule,
    NotificationsModule,
    FavoritesModule,
    LoyaltyModule,
    SupportModule,
    FaqModule,
    ReportsModule,
  ],
  exports: [
    RestaurantsModule,
    CustomersModule,
    AddressesModule,
    StaffModule,
    MediaModule,
    CategoriesModule,
    IngredientsModule,
    MenuModule,
    OptionGroupsModule,
    PricingModule,
    PizzaBuilderModule,
    CartsModule,
    PromotionsModule,
    CouponsModule,
    CheckoutModule,
    OrdersModule,
    PaymentsModule,
    RefundsModule,
    DeliveriesModule,
    NotificationsModule,
    FavoritesModule,
    LoyaltyModule,
    SupportModule,
    FaqModule,
    ReportsModule,
  ],
})
export class BusinessModule {}
