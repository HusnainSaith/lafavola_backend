import { BadRequestException, Injectable } from '@nestjs/common';
import { DataSource } from 'typeorm';
import { RedeemLoyaltyPointsDto } from './dto/redeem-loyalty-points.dto';
import { LoyaltyAccount } from './entities/loyalty-account.entity';
import { LoyaltyTransaction } from './entities/loyalty-transaction.entity';
import { LoyaltyAccountRepository } from './repositories/loyalty-account.repository';

@Injectable()
export class LoyaltyService {
  constructor(
    private readonly dataSource: DataSource,
    private readonly accounts: LoyaltyAccountRepository,
  ) {}

  async getOrCreate(customerId: string): Promise<LoyaltyAccount> {
    let account = await this.accounts.findByCustomerId(customerId);
    if (!account) {
      account = await this.accounts.save(
        this.accounts.create({
          customerId,
          pointsBalance: 0,
          lifetimePointsEarned: 0,
          tier: 'standard',
        }),
      );
    }
    return account;
  }

  async balance(customerId: string) {
    const account = await this.getOrCreate(customerId);
    return { points: account.pointsBalance, tier: account.tier };
  }

  history(customerId: string) {
    return this.dataSource
      .getRepository(LoyaltyTransaction)
      .createQueryBuilder('tx')
      .innerJoin(
        LoyaltyAccount,
        'account',
        'account.id = tx.loyalty_account_id',
      )
      .where('account.customer_id = :customerId', { customerId })
      .orderBy('tx.created_at', 'DESC')
      .getMany();
  }

  async redeem(customerId: string, dto: RedeemLoyaltyPointsDto) {
    return this.dataSource.transaction(async (manager) => {
      const accountRepo = manager.getRepository(LoyaltyAccount);
      const txRepo = manager.getRepository(LoyaltyTransaction);

      const account = await accountRepo
        .createQueryBuilder('account')
        .setLock('pessimistic_write')
        .where('account.customer_id = :customerId', { customerId })
        .getOne();
      if (!account) throw new BadRequestException('Loyalty account not found');
      if (Number(account.pointsBalance) < dto.points) {
        throw new BadRequestException('Insufficient loyalty points');
      }

      account.pointsBalance = Number(account.pointsBalance) - dto.points;
      await accountRepo.save(account);
      return txRepo.save(
        txRepo.create({
          loyaltyAccountId: account.id,
          orderId: dto.orderId,
          type: 'redeemed',
          pointsDelta: -dto.points,
          balanceAfter: account.pointsBalance,
          description: 'Loyalty points redeemed',
        }),
      );
    });
  }
}
