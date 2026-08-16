import { BadRequestException, Injectable } from '@nestjs/common';
import { DataSource, EntityManager } from 'typeorm';
import { RedeemLoyaltyPointsDto } from './dto/redeem-loyalty-points.dto';
import { LoyaltyAccount } from './entities/loyalty-account.entity';
import { LoyaltyTransaction } from './entities/loyalty-transaction.entity';
import { LoyaltyTransactionType } from './enums/loyalty-transaction-type.enum';
import { LoyaltyAccountRepository } from './repositories/loyalty-account.repository';

/**
 * Loyalty commercial defaults. Centralized so checkout, redemption and earning
 * stay consistent and can be tuned in one place.
 * - A redeemed point is worth 1 cent (1 minor unit).
 * - The customer earns 1 point for every full EUR (100 minor units) of
 *   merchandise spend.
 */
export const LOYALTY_POINT_VALUE_MINOR = 1;
export const LOYALTY_MINOR_PER_POINT_EARNED = 100;

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
      .orderBy('tx.createdAt', 'DESC')
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

  /**
   * Deduct points and compute the monetary discount they grant for a checkout.
   * Operates inside the caller-supplied transaction (manager) so it stays
   * atomic with order placement. Redemption is capped so it can never exceed
   * the eligible merchandise total, and the points actually consumed by the
   * cap are returned.
   */
  async redeemForCheckout(
    manager: EntityManager,
    customerId: string,
    points: number,
    capMinor?: number,
  ): Promise<{
    accountId: string;
    pointsRedeemed: number;
    redemptionDiscountMinor: number;
    balanceAfter: number;
  }> {
    if (!Number.isSafeInteger(points) || points <= 0) {
      throw new BadRequestException('Invalid loyalty-point redemption amount');
    }
    const account = await this.getOrCreateWithManager(manager, customerId);

    if (capMinor !== undefined) {
      const maxPoints = Math.floor(capMinor / LOYALTY_POINT_VALUE_MINOR);
      points = Math.min(points, Math.max(0, maxPoints));
    }
    if (points <= 0) {
      return {
        accountId: account.id,
        pointsRedeemed: 0,
        redemptionDiscountMinor: 0,
        balanceAfter: Number(account.pointsBalance),
      };
    }
    if (Number(account.pointsBalance) < points) {
      throw new BadRequestException('Insufficient loyalty points');
    }

    const redemptionDiscountMinor = points * LOYALTY_POINT_VALUE_MINOR;
    account.pointsBalance = Number(account.pointsBalance) - points;
    await manager.getRepository(LoyaltyAccount).save(account);

    return {
      accountId: account.id,
      pointsRedeemed: points,
      redemptionDiscountMinor,
      balanceAfter: Number(account.pointsBalance),
    };
  }

  /**
   * Record the redeemed ledger row for a completed checkout order.
   */
  async recordRedemption(
    manager: EntityManager,
    accountId: string,
    orderId: string,
    points: number,
    balanceAfter: number,
  ) {
    if (points <= 0) return;
    const txRepo = manager.getRepository(LoyaltyTransaction);
    await txRepo.save(
      txRepo.create({
        loyaltyAccountId: accountId,
        orderId,
        type: LoyaltyTransactionType.REDEEMED,
        pointsDelta: -points,
        balanceAfter,
        description: 'Loyalty points redeemed at checkout',
      }),
    );
  }
  /**
   * Credit the points a completed order earns and write the ledger row.
   * Earning is based on merchandise spend (subtotal + option charges).
   */
  async creditForCheckout(
    manager: EntityManager,
    customerId: string,
    orderId: string,
    spendMinor: number,
  ): Promise<{ pointsEarned: number; balanceAfter: number }> {
    const pointsEarned = Math.floor(
      Math.max(0, spendMinor) / LOYALTY_MINOR_PER_POINT_EARNED,
    );
    const account = await this.getOrCreateWithManager(manager, customerId);

    if (pointsEarned <= 0) {
      return { pointsEarned: 0, balanceAfter: Number(account.pointsBalance) };
    }

    account.pointsBalance = Number(account.pointsBalance) + pointsEarned;
    account.lifetimePointsEarned =
      Number(account.lifetimePointsEarned) + pointsEarned;
    await manager.getRepository(LoyaltyAccount).save(account);

    await manager.getRepository(LoyaltyTransaction).save(
      manager.getRepository(LoyaltyTransaction).create({
        loyaltyAccountId: account.id,
        orderId,
        type: LoyaltyTransactionType.EARNED,
        pointsDelta: pointsEarned,
        balanceAfter: Number(account.pointsBalance),
        description: 'Loyalty points earned from order',
      }),
    );

    return {
      pointsEarned,
      balanceAfter: Number(account.pointsBalance),
    };
  }

  private async getOrCreateWithManager(
    manager: EntityManager,
    customerId: string,
  ): Promise<LoyaltyAccount> {
    const repo = manager.getRepository(LoyaltyAccount);
    let account = await repo
      .createQueryBuilder('account')
      .setLock('pessimistic_write')
      .where('account.customer_id = :customerId', { customerId })
      .getOne();
    if (!account) {
      account = await repo.save(
        repo.create({
          customerId,
          pointsBalance: 0,
          lifetimePointsEarned: 0,
          tier: 'standard',
        }),
      );
    }
    return account;
  }
}
