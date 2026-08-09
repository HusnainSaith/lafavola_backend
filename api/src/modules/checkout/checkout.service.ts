import {
  BadRequestException,
  ConflictException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { DataSource, In } from 'typeorm';
import { createHash } from 'crypto';
import { CustomerAddress } from '../addresses/entities/customer-address.entity';
import { CartsService } from '../carts/carts.service';
import { CartItemOption } from '../carts/entities/cart-item-option.entity';
import { CartItem } from '../carts/entities/cart-item.entity';
import { Cart } from '../carts/entities/cart.entity';
import { CouponRedemption } from '../coupons/entities/coupon-redemption.entity';
import { Coupon } from '../coupons/entities/coupon.entity';
import { MenuItem } from '../menu/entities/menu-item.entity';
import { OrderItemOption } from '../orders/entities/order-item-option.entity';
import { OrderItem } from '../orders/entities/order-item.entity';
import { OrderStatusHistory } from '../orders/entities/order-status-history.entity';
import { Order } from '../orders/entities/order.entity';
import { Restaurant } from '../restaurants/entities/restaurant.entity';
import { CheckoutDto } from './dto/checkout.dto';
import { PricingService } from '../pricing/pricing.service';
import { OrderTotalsService } from '../pricing/order-totals.service';
import { PromotionRedemption } from '../promotions/entities/promotion-redemption.entity';
import { PromotionsService } from '../promotions/promotions.service';
import { IdempotencyKey } from '../audit/entities/idempotency-key.entity';
import { OutboxService } from '../../queue/outbox.service';

@Injectable()
export class CheckoutService {
  constructor(
    private readonly dataSource: DataSource,
    private readonly carts: CartsService,
    private readonly pricing: PricingService,
    private readonly promotions: PromotionsService,
    private readonly orderTotals: OrderTotalsService,
    private readonly outbox: OutboxService,
  ) {}

  private computeCouponDiscount(coupon: Coupon, subtotalMinor: number): number {
    if (subtotalMinor < Number(coupon.minOrderMinor ?? 0)) return 0;

    if (coupon.discountType === 'percentage') {
      const raw = Math.floor(
        (subtotalMinor * Number(coupon.discountValue)) / 100,
      );

      return coupon.maxDiscountMinor
        ? Math.min(raw, Number(coupon.maxDiscountMinor))
        : raw;
    }

    if (coupon.discountType === 'fixed_amount') {
      return Math.min(Number(coupon.discountValue), subtotalMinor);
    }

    return 0;
  }

  async checkout(customerId: string, dto: CheckoutDto) {
    const keyHash = dto.idempotencyKey
      ? createHash('sha256').update(dto.idempotencyKey).digest('hex')
      : undefined;
    const requestHash = createHash('sha256')
      .update(
        JSON.stringify({
          cartId: dto.cartId,
          deliveryAddressId: dto.deliveryAddressId,
          paymentMethod: dto.paymentMethod,
          savedPaymentMethodId: dto.savedPaymentMethodId ?? null,
          couponCode: dto.couponCode?.trim().toLowerCase() ?? null,
          customerNote: dto.customerNote ?? null,
          deliveryInstructions: dto.deliveryInstructions ?? null,
          scheduledFor: dto.scheduledFor ?? null,
        }),
      )
      .digest('hex');
    if (keyHash) {
      const previous = await this.dataSource
        .getRepository(IdempotencyKey)
        .findOne({
          where: { actorUserId: customerId, scope: 'checkout', keyHash },
        });
      if (previous && previous.requestHash !== requestHash) {
        throw new ConflictException(
          'Idempotency key was already used for a different checkout request',
        );
      }
      if (previous?.responseBody) return previous.responseBody;
    }
    const cartSummary = await this.carts.detailById(customerId, dto.cartId);
    const { cart, items } = cartSummary;

    if (!items.length) {
      throw new BadRequestException('Cart is empty');
    }

    const restaurant = await this.dataSource.getRepository(Restaurant).findOne({
      where: { id: cart.restaurantId, isActive: true },
    });

    if (!restaurant) {
      throw new NotFoundException('Restaurant not found');
    }

    const address = await this.dataSource
      .getRepository(CustomerAddress)
      .findOne({
        where: {
          id: dto.deliveryAddressId,
          customerId,
          isActive: true,
        },
      });

    if (!address) {
      throw new NotFoundException('Delivery address not found');
    }

    return this.dataSource.transaction(async (manager) => {
      const cartRepo = manager.getRepository(Cart);
      const cartItemRepo = manager.getRepository(CartItem);
      const cartOptionRepo = manager.getRepository(CartItemOption);
      const orderRepo = manager.getRepository(Order);
      const orderItemRepo = manager.getRepository(OrderItem);
      const orderOptionRepo = manager.getRepository(OrderItemOption);
      const historyRepo = manager.getRepository(OrderStatusHistory);
      const idempotencyRepo = manager.getRepository(IdempotencyKey);

      let idempotency: IdempotencyKey | null = null;
      if (keyHash) {
        await idempotencyRepo
          .createQueryBuilder()
          .insert()
          .values({
            actorUserId: customerId,
            scope: 'checkout',
            keyHash,
            requestHash,
            expiresAt: new Date(Date.now() + 24 * 60 * 60 * 1000),
          })
          .orIgnore()
          .execute();
        idempotency = await idempotencyRepo
          .createQueryBuilder('key')
          .setLock('pessimistic_write')
          .where('key.actor_user_id = :customerId', { customerId })
          .andWhere('key.scope = :scope', { scope: 'checkout' })
          .andWhere('key.key_hash = :keyHash', { keyHash })
          .getOne();
        if (idempotency?.requestHash !== requestHash) {
          throw new ConflictException(
            'Idempotency key was already used for a different checkout request',
          );
        }
        if (idempotency?.responseBody) return idempotency.responseBody;
      }

      const lockedCart = await cartRepo
        .createQueryBuilder('cart')
        .setLock('pessimistic_write')
        .where('cart.id = :id', { id: cart.id })
        .andWhere('cart.customer_id = :customerId', { customerId })
        .andWhere('cart.status = :status', { status: 'active' })
        .getOne();

      if (!lockedCart) {
        throw new BadRequestException('Cart is no longer active');
      }

      const lockedItems = await cartItemRepo.find({
        where: { cartId: lockedCart.id },
        order: { createdAt: 'ASC' },
      });

      if (!lockedItems.length) {
        throw new BadRequestException('Cart is empty');
      }

      const cartOptions = await cartOptionRepo
        .createQueryBuilder('option')
        .where('option.cart_item_id IN (:...ids)', {
          ids: lockedItems.map((item) => item.id),
        })
        .getMany();
      for (const cartItem of lockedItems) {
        const options = cartOptions.filter(
          (option) => option.cartItemId === cartItem.id,
        );
        const current = await this.pricing.calculate({
          menuItemId: cartItem.menuItemId,
          sizeId: cartItem.menuItemSizeId,
          quantity: cartItem.quantity,
          options: options.map((option) => ({
            optionGroupId: option.optionGroupId,
            optionChoiceId: option.optionChoiceId,
            ingredientId: option.ingredientId,
            action: option.action as 'add' | 'remove' | 'replace',
            quantity: Number(option.quantity),
          })),
        });
        cartItem.baseUnitPriceMinor = current.basePriceMinor;
        cartItem.optionsUnitPriceMinor = current.optionAdjustmentsMinor;
        cartItem.unitPriceMinor = current.unitPriceMinor;
        cartItem.lineTotalMinor = current.lineTotalMinor;
      }
      await cartItemRepo.save(lockedItems);
      const subtotalMinor = lockedItems.reduce(
        (sum, item) => sum + Number(item.baseUnitPriceMinor) * item.quantity,
        0,
      );
      const optionChargesMinor = lockedItems.reduce(
        (sum, item) => sum + Number(item.optionsUnitPriceMinor) * item.quantity,
        0,
      );
      const merchandiseTotalMinor = subtotalMinor + optionChargesMinor;

      if (merchandiseTotalMinor < Number(restaurant.minimumOrderMinor ?? 0)) {
        throw new BadRequestException(
          `Minimum order amount is ${restaurant.minimumOrderMinor} minor units`,
        );
      }

      let coupon: Coupon | null = null;
      let discountMinor = 0;

      if (dto.couponCode) {
        coupon = await manager
          .getRepository(Coupon)
          .createQueryBuilder('coupon')
          .where('coupon.restaurant_id = :restaurantId', {
            restaurantId: restaurant.id,
          })
          .andWhere('LOWER(coupon.code) = LOWER(:code)', {
            code: dto.couponCode,
          })
          .andWhere('coupon.is_active = true')
          .andWhere('(coupon.starts_at IS NULL OR coupon.starts_at <= NOW())')
          .andWhere('(coupon.expires_at IS NULL OR coupon.expires_at > NOW())')
          .setLock('pessimistic_write')
          .getOne();

        if (!coupon) {
          throw new BadRequestException('Coupon is invalid or expired');
        }

        const redemptionRepo = manager.getRepository(CouponRedemption);
        const totalUses = await redemptionRepo.count({
          where: { couponId: coupon.id },
        });
        const customerUses = await redemptionRepo.count({
          where: { couponId: coupon.id, customerId },
        });
        if (
          (coupon.totalUsageLimit !== undefined &&
            totalUses >= coupon.totalUsageLimit) ||
          (coupon.perCustomerLimit !== undefined &&
            customerUses >= coupon.perCustomerLimit)
        ) {
          throw new BadRequestException('Coupon usage limit has been reached');
        }

        discountMinor = this.computeCouponDiscount(
          coupon,
          merchandiseTotalMinor,
        );
      }

      const deliveryFeeMinor = Number(restaurant.deliveryFeeMinor ?? 0);
      const menuItems = await manager.getRepository(MenuItem).find({
        where: { id: In(lockedItems.map((item) => item.menuItemId)) },
      });
      const menuById = new Map(menuItems.map((item) => [item.id, item]));
      const promotionResult = await this.promotions.evaluateAutomatic(manager, {
        restaurantId: restaurant.id,
        customerId,
        subtotalMinor: merchandiseTotalMinor,
        deliveryFeeMinor,
        hasCoupon: Boolean(coupon),
        lock: true,
        lines: lockedItems.map((item) => ({
          menuItemId: item.menuItemId,
          categoryId: menuById.get(item.menuItemId)?.categoryId,
          lineTotalMinor: Number(item.lineTotalMinor),
        })),
      });
      const couponDiscountMinor = discountMinor;
      const promotionDiscountMinor = promotionResult.promotionDiscountMinor;
      const loyaltyDiscountMinor = 0;
      const deliveryDiscountMinor = Math.min(
        deliveryFeeMinor,
        promotionResult.deliveryDiscountMinor +
          (coupon?.discountType === 'free_delivery' ? deliveryFeeMinor : 0),
      );

      const totals = this.orderTotals.calculate({
        subtotalMinor,
        optionChargesMinor,
        deliveryFeeMinor,
        promotionDiscountMinor,
        couponDiscountMinor,
        loyaltyDiscountMinor,
        deliveryDiscountMinor,
        taxRateBasisPoints: Number(restaurant.taxRateBasisPoints ?? 0),
        taxExcluded: restaurant.taxBehavior === 'excluded',
      });
      const { taxMinor, grandTotalMinor } = totals;

      const now = new Date();
      const estimatedDeliveryAt = new Date(
        now.getTime() + Number(restaurant.defaultDeliveryMinutes) * 60_000,
      );

      const collectionOnDelivery = ['cash', 'card_on_delivery'].includes(
        String(dto.paymentMethod),
      );

      const order = await orderRepo.save(
        orderRepo.create({
          restaurantId: restaurant.id,
          customerId,
          cartId: lockedCart.id,
          orderType: 'delivery',
          status: collectionOnDelivery ? 'placed' : 'pending_payment',
          paymentStatus: collectionOnDelivery
            ? 'collection_pending'
            : 'pending',
          paymentMethod: String(dto.paymentMethod),
          currency: 'EUR',
          subtotalMinor,
          optionChargesMinor,
          discountMinor:
            promotionDiscountMinor +
            couponDiscountMinor +
            deliveryDiscountMinor,
          promotionDiscountMinor,
          couponDiscountMinor,
          loyaltyDiscountMinor,
          deliveryFeeMinor,
          taxMinor,
          grandTotalMinor,
          deliveryAddressSnapshot: {
            id: address.id,
            label: address.label,
            recipientName: address.recipientName,
            phone: address.phone,
            addressLine1: address.addressLine1,
            addressLine2: address.addressLine2,
            city: address.city,
            province: address.province,
            postalCode: address.postalCode,
            countryCode: address.countryCode,
            latitude: address.latitude,
            longitude: address.longitude,
          },
          deliveryInstructions:
            dto.deliveryInstructions ?? address.deliveryInstructions,
          customerNote: dto.customerNote,
          estimatedDeliveryAt,
          scheduledFor: dto.scheduledFor
            ? new Date(dto.scheduledFor)
            : undefined,
          placedAt: collectionOnDelivery ? now : undefined,
          pricingSnapshot: {
            restaurantId: restaurant.id,
            taxBehavior: restaurant.taxBehavior,
            taxRateBasisPoints: restaurant.taxRateBasisPoints,
            couponCode: coupon?.code ?? null,
            promotionDiscountMinor,
            couponDiscountMinor,
            loyaltyDiscountMinor,
            deliveryDiscountMinor,
            appliedPromotions: promotionResult.appliedPromotions,
            unsupportedPromotions: promotionResult.unsupportedPromotions,
          },
          version: '1',
        }),
      );

      for (const cartItem of lockedItems) {
        const orderItem = await orderItemRepo.save(
          orderItemRepo.create({
            orderId: order.id,
            menuItemId: cartItem.menuItemId,
            menuItemSizeId: cartItem.menuItemSizeId,
            itemNameSnapshot: cartItem.itemNameSnapshot,
            sizeNameSnapshot: cartItem.sizeNameSnapshot,
            quantity: cartItem.quantity,
            baseUnitPriceMinor: cartItem.baseUnitPriceMinor,
            optionsUnitPriceMinor: cartItem.optionsUnitPriceMinor,
            unitPriceMinor: cartItem.unitPriceMinor,
            lineTotalMinor: cartItem.lineTotalMinor,
            specialInstructions: cartItem.specialInstructions,
            configurationSnapshot: {
              configurationHash: cartItem.configurationHash,
            },
          }),
        );

        const options = cartOptions.filter(
          (option) => option.cartItemId === cartItem.id,
        );

        if (options.length) {
          await orderOptionRepo.save(
            options.map((option) =>
              orderOptionRepo.create({
                orderItemId: orderItem.id,
                optionGroupId: option.optionGroupId,
                optionChoiceId: option.optionChoiceId,
                ingredientId: option.ingredientId,
                action: option.action,
                optionNameSnapshot: option.optionNameSnapshot,
                quantity: option.quantity,
                unitPriceAdjustmentMinor: option.unitPriceAdjustmentMinor,
                totalPriceAdjustmentMinor: option.totalPriceAdjustmentMinor,
              }),
            ),
          );
        }
      }

      await historyRepo.save(
        historyRepo.create({
          orderId: order.id,
          previousStatus: undefined,
          newStatus: String(order.status),
          changedByUserId: customerId,
          note: 'Order created',
        }),
      );
      if (collectionOnDelivery) {
        await this.outbox.enqueue(manager, {
          aggregateType: 'order',
          aggregateId: order.id,
          eventType: 'order.confirmed',
          payload: { orderId: order.id },
        });
      }

      if (coupon) {
        await manager.getRepository(CouponRedemption).save(
          manager.getRepository(CouponRedemption).create({
            couponId: coupon.id,
            customerId,
            orderId: order.id,
            discountMinor:
              couponDiscountMinor +
              (coupon.discountType === 'free_delivery' ? deliveryFeeMinor : 0),
          }),
        );
      }

      if (promotionResult.appliedPromotions.length) {
        const promotionRedemptionRepo =
          manager.getRepository(PromotionRedemption);
        await promotionRedemptionRepo.save(
          promotionResult.appliedPromotions.map((promotion) =>
            promotionRedemptionRepo.create({
              promotionId: promotion.id,
              customerId,
              orderId: order.id,
              discountMinor:
                promotion.discountMinor + promotion.deliveryDiscountMinor,
            }),
          ),
        );
      }

      lockedCart.status = 'converted';
      await cartRepo.save(lockedCart);

      const result = {
        orderId: order.id,
        orderNumber: order.orderNumber,
        status: order.status,
        paymentStatus: order.paymentStatus,
        amountMinor: grandTotalMinor,
        currency: 'EUR',
        subtotalMinor,
        optionChargesMinor,
        deliveryFeeMinor,
        taxMinor,
        promotionDiscountMinor,
        couponDiscountMinor,
        loyaltyDiscountMinor,
        deliveryDiscountMinor,
        appliedPromotions: promotionResult.appliedPromotions,
        estimatedDeliveryAt: order.estimatedDeliveryAt,
      };
      if (idempotency) {
        idempotency.responseStatus = 201;
        idempotency.responseBody = result as unknown as Record<string, unknown>;
        await idempotencyRepo.save(idempotency);
      }
      return result;
    });
  }
}
