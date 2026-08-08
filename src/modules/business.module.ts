import { Module } from '@nestjs/common';
import { AddressesModule } from './addresses/addresses.module';
import { AuditModule } from './audit/audit.module';
import { CartsModule } from './carts/carts.module';
import { CategoriesModule } from './categories/categories.module';
import { CheckoutModule } from './checkout/checkout.module';
import { CouponsModule } from './coupons/coupons.module';
import { CustomersModule } from './customers/customers.module';
import { DeliveriesModule } from './deliveries/deliveries.module';
import { FaqModule } from './faq/faq.module';
import { FavoritesModule } from './favorites/favorites.module';
import { IngredientsModule } from './ingredients/ingredients.module';
import { LoyaltyModule } from './loyalty/loyalty.module';
import { MediaModule } from './media/media.module';
import { MenuModule } from './menu/menu.module';
import { NotificationsModule } from './notifications/notifications.module';
import { OptionGroupsModule } from './option-groups/option-groups.module';
import { OrdersModule } from './orders/orders.module';
import { PaymentsModule } from './payments/payments.module';
import { PizzaBuilderModule } from './pizza-builder/pizza-builder.module';
import { PricingModule } from './pricing/pricing.module';
import { PromotionsModule } from './promotions/promotions.module';
import { RefundsModule } from './refunds/refunds.module';
import { ReportsModule } from './reports/reports.module';
import { RestaurantsModule } from './restaurants/restaurants.module';
import { StaffModule } from './staff/staff.module';
import { SupportModule } from './support/support.module';

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
