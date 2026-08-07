import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { DataSource } from 'typeorm';
import { CheckoutDto } from './dto/checkout.dto';
import { CartsService } from '../carts/carts.service';
import { Cart } from '../carts/entities/cart.entity';
import { CartItem } from '../carts/entities/cart-item.entity';
import { CartItemOption } from '../carts/entities/cart-item-option.entity';
import { Order } from '../orders/entities/order.entity';
import { OrderItem } from '../orders/entities/order-item.entity';
import { OrderItemOption } from '../orders/entities/order-item-option.entity';
import { OrderStatusHistory } from '../orders/entities/order-status-history.entity';
import { Restaurant } from '../restaurants/entities/restaurant.entity';
import { Coupon } from '../coupons/entities/coupon.entity';
import { CouponRedemption } from '../coupons/entities/coupon-redemption.entity';

@Injectable()
export class CheckoutService {
  constructor(
    private readonly dataSource: DataSource,
    private readonly carts: CartsService,
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
    const cartSummary = await this.carts.detail(customerId, dto.restaurantId);
    const { cart, items } = cartSummary;
    if (!items.length) throw new BadRequestException('Cart is empty');

    const restaurant = await this.dataSource.getRepository(Restaurant).findOne({
      where: { id: dto.restaurantId, isActive: true },
    });
    if (!restaurant) throw new NotFoundException('Restaurant not found');

    return this.dataSource.transaction(async (manager) => {
      const cartRepo = manager.getRepository(Cart);
      const cartItemRepo = manager.getRepository(CartItem);
      const cartOptionRepo = manager.getRepository(CartItemOption);
      const orderRepo = manager.getRepository(Order);
      const orderItemRepo = manager.getRepository(OrderItem);
      const orderOptionRepo = manager.getRepository(OrderItemOption);
      const historyRepo = manager.getRepository(OrderStatusHistory);

      const lockedCart = await cartRepo
        .createQueryBuilder('cart')
        .setLock('pessimistic_write')
        .where('cart.id = :id', { id: cart.id })
        .andWhere('cart.status = :status', { status: 'active' })
        .getOne();
      if (!lockedCart)
        throw new BadRequestException('Cart is no longer active');

      const lockedItems = await cartItemRepo.find({
        where: { cartId: cart.id },
        order: { createdAt: 'ASC' },
      });
      if (!lockedItems.length) throw new BadRequestException('Cart is empty');

      const subtotalMinor = lockedItems.reduce(
        (sum, item) => sum + Number(item.lineTotalMinor),
        0,
      );

      let coupon: Coupon | null = null;
      let discountMinor = 0;
      if (dto.couponCode) {
        coupon = await manager
          .getRepository(Coupon)
          .createQueryBuilder('coupon')
          .where('coupon.restaurant_id = :restaurantId', {
            restaurantId: dto.restaurantId,
          })
          .andWhere('LOWER(coupon.code) = LOWER(:code)', {
            code: dto.couponCode,
          })
          .andWhere('coupon.is_active = true')
          .andWhere('(coupon.starts_at IS NULL OR coupon.starts_at <= NOW())')
          .andWhere('(coupon.expires_at IS NULL OR coupon.expires_at > NOW())')
          .getOne();
        if (!coupon)
          throw new BadRequestException('Coupon is invalid or expired');
        discountMinor = this.computeCouponDiscount(coupon, subtotalMinor);
      }

      const deliveryFeeMinor =
        dto.orderType === 'delivery'
          ? Number(restaurant.deliveryFeeMinor ?? 0)
          : 0;
      if (coupon?.discountType === 'free_delivery') {
        discountMinor += deliveryFeeMinor;
      }

      const taxableMinor = Math.max(
        0,
        subtotalMinor + deliveryFeeMinor - discountMinor,
      );
      const taxMinor =
        restaurant.taxBehavior === 'excluded'
          ? Math.round(
              (taxableMinor * Number(restaurant.taxRateBasisPoints ?? 0)) /
                10000,
            )
          : 0;
      const grandTotalMinor = Math.max(
        0,
        subtotalMinor + deliveryFeeMinor + taxMinor - discountMinor,
      );

      const now = new Date();
      const estimated = new Date(
        now.getTime() +
          Number(restaurant.defaultDeliveryMinutes ?? 30) * 60_000,
      );

      const order = await orderRepo.save(
        orderRepo.create({
          restaurantId: restaurant.id,
          customerId,
          cartId: cart.id,
          orderType: dto.orderType ?? 'delivery',
          status:
            dto.paymentMethod === 'cash' ||
            dto.paymentMethod === 'card_on_delivery'
              ? 'placed'
              : 'pending_payment',
          paymentStatus:
            dto.paymentMethod === 'cash' ||
            dto.paymentMethod === 'card_on_delivery'
              ? 'collection_pending'
              : 'pending',
          paymentMethod: dto.paymentMethod,
          currency: 'EUR',
          subtotalMinor,
          optionChargesMinor: 0,
          discountMinor,
          loyaltyDiscountMinor: 0,
          deliveryFeeMinor,
          taxMinor,
          grandTotalMinor,
          deliveryAddressSnapshot: dto.deliveryAddress,
          deliveryInstructions: dto.deliveryInstructions,
          customerNote: dto.customerNote,
          estimatedDeliveryAt: estimated,
          scheduledFor: dto.scheduledFor
            ? new Date(dto.scheduledFor)
            : undefined,
          placedAt:
            dto.paymentMethod === 'cash' ||
            dto.paymentMethod === 'card_on_delivery'
              ? now
              : undefined,
          pricingSnapshot: {
            restaurantId: restaurant.id,
            taxBehavior: restaurant.taxBehavior,
            taxRateBasisPoints: restaurant.taxRateBasisPoints,
            couponCode: coupon?.code ?? null,
          },
          version: 1,
        }),
      );

      const cartOptions = lockedItems.length
        ? await cartOptionRepo
            .createQueryBuilder('option')
            .where('option.cart_item_id IN (:...ids)', {
              ids: lockedItems.map((i) => i.id),
            })
            .getMany()
        : [];

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

        const options = cartOptions.filter((o) => o.cartItemId === cartItem.id);
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

      if (coupon) {
        await manager.getRepository(CouponRedemption).save(
          manager.getRepository(CouponRedemption).create({
            couponId: coupon.id,
            customerId,
            orderId: order.id,
            discountMinor,
          }),
        );
      }

      lockedCart.status = 'converted';
      await cartRepo.save(lockedCart);

      return {
        orderId: order.id,
        orderNumber: order.orderNumber,
        status: order.status,
        paymentStatus: order.paymentStatus,
        amountMinor: grandTotalMinor,
        currency: 'EUR',
        estimatedDeliveryAt: order.estimatedDeliveryAt,
      };
    });
  }
}
