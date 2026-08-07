import { Injectable, NotFoundException } from '@nestjs/common';
import { RefundRepository } from './repositories/refund.repository';
import { CreateRefundDto } from './dto/create-refund.dto';

@Injectable()
export class RefundsService {
  constructor(private readonly refunds: RefundRepository) {}

  create(customerId: string, dto: CreateRefundDto) {
    return this.refunds.save(
      this.refunds.create({
        ...dto,
        requestedByUserId: customerId,
        status: 'requested',
      }),
    );
  }

  listForOrder(orderId: string) {
    return this.refunds.findMany({
      where: { orderId },
      order: { createdAt: 'DESC' },
    });
  }

  async approve(id: string, staffNote?: string) {
    const refund = await this.refunds.findById(id);
    if (!refund) throw new NotFoundException('Refund not found');
    refund.status = 'approved' as any;
    refund.staffNote = staffNote;
    return this.refunds.save(refund);
  }
}
