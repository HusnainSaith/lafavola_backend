import { BadRequestException, Injectable } from '@nestjs/common';
import { DataSource } from 'typeorm';
import { PaymentTransactionRepository } from './repositories/payment-transaction.repository';
import { PaymentTransaction } from './entities/payment-transaction.entity';
import { CustomerPaymentMethod } from './entities/customer-payment-method.entity';
import { PaymentWebhookEvent } from './entities/payment-webhook-event.entity';
import { PaymentReceipt } from './entities/payment-receipt.entity';
import { Order } from '../orders/entities/order.entity';
import { CreatePaymentIntentDto } from './dto/create-payment-intent.dto';
import { SavePaymentMethodDto } from './dto/save-payment-method.dto';
import { CollectPaymentDto } from './dto/collect-payment.dto';
import { requireEntity } from '../../common/utils/service-errors.util';

@Injectable()
export class PaymentsService {
  constructor(
    private readonly dataSource: DataSource,
    private readonly transactions: PaymentTransactionRepository,
  ) {}

  listMethods(customerId: string) {
    return this.dataSource.getRepository(CustomerPaymentMethod).find({
      where: { customerId, archivedAt: null as any },
      order: { isDefault: 'DESC', createdAt: 'DESC' },
    });
  }

  async saveMethod(customerId: string, dto: SavePaymentMethodDto) {
    const repo = this.dataSource.getRepository(CustomerPaymentMethod);
    if (dto.isDefault) {
      await repo.update({ customerId, isDefault: true }, { isDefault: false });
    }
    return repo.save(
      repo.create({
        ...dto,
        customerId,
        provider: 'stripe',
      }),
    );
  }

  async createIntent(customerId: string, dto: CreatePaymentIntentDto) {
    const order = requireEntity(
      await this.dataSource.getRepository(Order).findOne({
        where: { id: dto.orderId, customerId },
      }),
      'Order not found',
    );
    if (String(order.paymentStatus) === 'paid') {
      throw new BadRequestException('Order is already paid');
    }

    const existing = dto.idempotencyKey
      ? await this.transactions.findOne({
          where: { orderId: order.id, idempotencyKey: dto.idempotencyKey },
        })
      : null;
    if (existing) return existing;

    return this.transactions.save(
      this.transactions.create({
        orderId: order.id,
        customerId,
        paymentMethodId: dto.savedPaymentMethodId,
        provider: 'stripe',
        paymentMethodType: dto.paymentMethodType,
        amountMinor: Number(order.grandTotalMinor),
        currency: 'EUR',
        status: 'pending',
        idempotencyKey: dto.idempotencyKey,
        metadata: {
          orderNumber: order.orderNumber,
          requiresProviderConfirmation: true,
        },
      }),
    );
  }

  async collectOnDelivery(
    orderId: string,
    collectorUserId: string,
    dto: CollectPaymentDto,
  ) {
    const order = requireEntity(
      await this.dataSource.getRepository(Order).findOne({ where: { id: orderId } }),
      'Order not found',
    );
    if (!['cash', 'card_on_delivery'].includes(String(order.paymentMethod))) {
      throw new BadRequestException('Order is not configured for pay-on-delivery');
    }
    return this.dataSource.transaction(async (manager) => {
      const txRepo = manager.getRepository(PaymentTransaction);
      const orderRepo = manager.getRepository(Order);
      const receiptRepo = manager.getRepository(PaymentReceipt);

      const transaction = await txRepo.save(
        txRepo.create({
          orderId: order.id,
          customerId: order.customerId,
          provider: dto.paymentMethodType === 'cash' ? 'cash' : 'external_terminal',
          paymentMethodType: dto.paymentMethodType,
          amountMinor: Number(order.grandTotalMinor),
          currency: 'EUR',
          status: 'captured',
          capturedAt: new Date(),
          metadata: { collectorUserId },
        }),
      );
      order.paymentStatus = 'paid' as any;
      await orderRepo.save(order);

      await receiptRepo.save(
        receiptRepo.create({
          orderId: order.id,
          paymentTransactionId: transaction.id,
          receiptNumber: `LF-R-${Date.now()}-${order.orderNumber}`,
          amountMinor: Number(order.grandTotalMinor),
          taxMinor: Number(order.taxMinor),
          currency: 'EUR',
          receiptData: { paymentMethod: dto.paymentMethodType },
        }),
      );
      return transaction;
    });
  }

  async recordWebhook(providerEventId: string, eventType: string, payload: unknown) {
    const repo = this.dataSource.getRepository(PaymentWebhookEvent);
    const existing = await repo.findOne({ where: { provider: 'stripe', providerEventId } });
    if (existing) return existing;
    return repo.save(
      repo.create({
        provider: 'stripe',
        providerEventId,
        eventType,
        payload: payload as any,
        processingStatus: 'pending',
        attempts: 0,
      }),
    );
  }
}
