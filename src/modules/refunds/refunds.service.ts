import {
  BadRequestException,
  ConflictException,
  Inject,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { DataSource, Not } from 'typeorm';
import { Order } from '../orders/entities/order.entity';
import { PaymentTransaction } from '../payments/entities/payment-transaction.entity';
import {
  PAYMENT_PROVIDER,
  PaymentProviderPort,
} from '../payments/interfaces/payment-provider.interface';
import { CreateRefundDto } from './dto/create-refund.dto';
import { Refund } from './entities/refund.entity';

@Injectable()
export class RefundsService {
  constructor(
    private readonly dataSource: DataSource,
    @Inject(PAYMENT_PROVIDER) private readonly provider: PaymentProviderPort,
  ) {}

  async create(customerId: string, dto: CreateRefundDto) {
    return this.dataSource.transaction(async (manager) => {
      const order = await manager.getRepository(Order).findOne({
        where: { id: dto.orderId, customerId },
        lock: { mode: 'pessimistic_write' },
      });
      if (!order) throw new NotFoundException('Order not found');
      const payment = await manager.getRepository(PaymentTransaction).findOne({
        where: { orderId: order.id, provider: 'sumup', status: Not('failed') },
        order: { createdAt: 'DESC' },
        lock: { mode: 'pessimistic_write' },
      });
      if (
        !payment ||
        !payment.providerTransactionId ||
        !['captured', 'partially_refunded'].includes(payment.status)
      ) {
        throw new BadRequestException(
          'Order does not have a refundable payment',
        );
      }
      const repo = manager.getRepository(Refund);
      const existing = await repo.findOne({
        where: {
          paymentTransactionId: payment.id,
          idempotencyKey: dto.idempotencyKey,
        },
      });
      if (existing) return existing;
      const committed = await repo
        .createQueryBuilder('refund')
        .select('COALESCE(SUM(refund.amountMinor), 0)', 'total')
        .where('refund.paymentTransactionId = :paymentId', {
          paymentId: payment.id,
        })
        .andWhere('refund.status IN (:...statuses)', {
          statuses: ['approved', 'processing', 'refunded'],
        })
        .getRawOne<{ total: string }>();
      if (
        Number(committed?.total ?? 0) + dto.amountMinor >
        payment.amountMinor
      ) {
        throw new ConflictException(
          'Refund amount exceeds the remaining refundable amount',
        );
      }
      return repo.save(
        repo.create({
          orderId: order.id,
          paymentTransactionId: payment.id,
          requestedByUserId: customerId,
          amountMinor: dto.amountMinor,
          reason: dto.reason,
          customerReason: dto.customerReason,
          idempotencyKey: dto.idempotencyKey,
          status: 'requested',
        }),
      );
    });
  }

  listForOrder(customerId: string, orderId: string) {
    return this.dataSource
      .getRepository(Refund)
      .createQueryBuilder('refund')
      .innerJoin(Order, 'order', 'order.id = refund.order_id')
      .where('refund.order_id = :orderId', { orderId })
      .andWhere('order.customer_id = :customerId', { customerId })
      .orderBy('refund.created_at', 'DESC')
      .getMany();
  }

  async get(customerId: string, id: string) {
    const refund = await this.dataSource
      .getRepository(Refund)
      .createQueryBuilder('refund')
      .innerJoin(Order, 'order', 'order.id = refund.order_id')
      .where('refund.id = :id', { id })
      .andWhere('order.customer_id = :customerId', { customerId })
      .getOne();
    if (!refund) throw new NotFoundException('Refund not found');
    return refund;
  }

  async approve(id: string, staffNote?: string) {
    let providerFailure = false;
    try {
      return await this.dataSource.transaction(async (manager) => {
        const repo = manager.getRepository(Refund);
        const refund = await repo.findOne({
          where: { id },
          lock: { mode: 'pessimistic_write' },
        });
        if (!refund) throw new NotFoundException('Refund not found');
        if (refund.status === 'refunded') return refund;
        if (refund.status !== 'requested')
          throw new ConflictException(
            'Refund cannot be processed in its current state',
          );
        const payment = await manager
          .getRepository(PaymentTransaction)
          .findOne({
            where: { id: refund.paymentTransactionId },
            lock: { mode: 'pessimistic_write' },
          });
        if (!payment?.providerTransactionId)
          throw new BadRequestException('Provider transaction is unavailable');
        const totals = await repo
          .createQueryBuilder('other')
          .select('COALESCE(SUM(other.amountMinor), 0)', 'total')
          .where('other.paymentTransactionId = :paymentId', {
            paymentId: payment.id,
          })
          .andWhere('other.id <> :id', { id: refund.id })
          .andWhere('other.status IN (:...statuses)', {
            statuses: ['approved', 'processing', 'refunded'],
          })
          .getRawOne<{ total: string }>();
        if (
          Number(totals?.total ?? 0) + refund.amountMinor >
          payment.amountMinor
        ) {
          throw new ConflictException(
            'Refund amount exceeds the remaining refundable amount',
          );
        }
        refund.status = 'processing';
        refund.staffNote = staffNote;
        await repo.save(refund);
        try {
          const result = await this.provider.refundPayment(
            payment.providerTransactionId,
            refund.amountMinor,
          );
          refund.providerRefundId = result.providerRefundId;
          refund.status = result.status;
          refund.processedAt = new Date();
          await repo.save(refund);
          const refunded = Number(totals?.total ?? 0) + refund.amountMinor;
          payment.status =
            refunded === payment.amountMinor
              ? 'refunded'
              : 'partially_refunded';
          await manager.getRepository(PaymentTransaction).save(payment);
          const order = await manager.getRepository(Order).findOne({
            where: { id: payment.orderId },
            lock: { mode: 'pessimistic_write' },
          });
          if (order) {
            order.paymentStatus = payment.status;
            await manager.getRepository(Order).save(order);
          }
          return refund;
        } catch (error) {
          providerFailure = true;
          throw error;
        }
      });
    } catch (error) {
      if (providerFailure) {
        await this.dataSource
          .getRepository(Refund)
          .update(
            { id },
            { status: 'failed', processedAt: new Date(), staffNote },
          );
      }
      throw error;
    }
  }
}
