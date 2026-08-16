import { BadRequestException } from '@nestjs/common';
import { LoyaltyAccount } from '../../src/modules/loyalty/entities/loyalty-account.entity';
import { LoyaltyTransaction } from '../../src/modules/loyalty/entities/loyalty-transaction.entity';
import {
  LoyaltyService,
  LOYALTY_MINOR_PER_POINT_EARNED,
  LOYALTY_POINT_VALUE_MINOR,
} from '../../src/modules/loyalty/loyalty.service';

describe('LoyaltyService checkout integration', () => {
  function managerMocks(account: LoyaltyAccount | null) {
    const accountQb = {
      setLock: jest.fn().mockReturnThis(),
      where: jest.fn().mockReturnThis(),
      getOne: jest.fn().mockResolvedValue(account),
    };
    const accountRepository = {
      createQueryBuilder: jest.fn(() => accountQb),
      save: jest.fn((entity: LoyaltyAccount) => Promise.resolve(entity)),
      create: jest.fn((input: unknown) => input),
    };
    const transactionRepository = {
      save: jest.fn((entity: unknown) => Promise.resolve(entity)),
      create: jest.fn((input: unknown) => input),
    };
    const manager = {
      getRepository: jest.fn((entity: unknown) => {
        if (entity === LoyaltyAccount) return accountRepository;
        if (entity === LoyaltyTransaction) return transactionRepository;
        throw new Error('unexpected repository request');
      }),
    } as never;
    return { manager, accountRepository, transactionRepository };
  }

  const service = new LoyaltyService({} as never, {} as never);

  it('deducts points and computes the redemption discount', async () => {
    const account = { id: 'acc-1', pointsBalance: 1000 } as LoyaltyAccount;
    const { manager, accountRepository } = managerMocks(account);

    const result = await service.redeemForCheckout(
      manager,
      'cust-1',
      250,
      10_000,
    );

    expect(result.pointsRedeemed).toBe(250);
    expect(result.redemptionDiscountMinor).toBe(
      250 * LOYALTY_POINT_VALUE_MINOR,
    );
    expect(result.balanceAfter).toBe(750);
    expect(account.pointsBalance).toBe(750);
    expect(accountRepository.save).toHaveBeenCalledWith(account);
  });

  it('caps redemption to the eligible merchandise total', async () => {
    const account = { id: 'acc-1', pointsBalance: 1000 } as LoyaltyAccount;
    const { manager } = managerMocks(account);

    // capMinor = 120 minor => max 120 points redeemable.
    const result = await service.redeemForCheckout(
      manager,
      'cust-1',
      9999,
      120,
    );

    expect(result.pointsRedeemed).toBe(120);
    expect(result.redemptionDiscountMinor).toBe(120);
    expect(result.balanceAfter).toBe(880);
  });

  it('rejects redemption when the balance is insufficient', async () => {
    const account = { id: 'acc-1', pointsBalance: 10 } as LoyaltyAccount;
    const { manager } = managerMocks(account);

    await expect(
      service.redeemForCheckout(manager, 'cust-1', 100, 10_000),
    ).rejects.toBeInstanceOf(BadRequestException);
  });

  it('credits earned points and writes the ledger row', async () => {
    const account = {
      id: 'acc-1',
      pointsBalance: 500,
      lifetimePointsEarned: 0,
    } as LoyaltyAccount;
    const { manager, transactionRepository } = managerMocks(account);

    const result = await service.creditForCheckout(
      manager,
      'cust-1',
      'ord-1',
      1250,
    );

    expect(result.pointsEarned).toBe(
      Math.floor(1250 / LOYALTY_MINOR_PER_POINT_EARNED),
    );
    expect(result.balanceAfter).toBe(512);
    expect(account.pointsBalance).toBe(512);
    expect(account.lifetimePointsEarned).toBe(12);
    expect(transactionRepository.save).toHaveBeenCalledWith(
      expect.objectContaining({
        orderId: 'ord-1',
        type: 'earned',
        pointsDelta: 12,
      }),
    );
  });

  it('earns nothing for spend below one point threshold', async () => {
    const account = { id: 'acc-1', pointsBalance: 0 } as LoyaltyAccount;
    const { manager, transactionRepository } = managerMocks(account);

    const result = await service.creditForCheckout(
      manager,
      'cust-1',
      'ord-1',
      90,
    );

    expect(result.pointsEarned).toBe(0);
    expect(account.pointsBalance).toBe(0);
    expect(transactionRepository.save).not.toHaveBeenCalled();
  });
});
