import { NotFoundException } from '@nestjs/common';
import { RefreshToken } from '../../src/modules/auth/entities/refresh-token.entity';
import { CustomersService } from '../../src/modules/customers/customers.service';
import { PrivacyRequest } from '../../src/modules/customers/entities/privacy-request.entity';

describe('customer account ownership contracts', () => {
  const customerId = '10000000-0000-4000-8000-000000000001';
  const sessionId = '20000000-0000-4000-8000-000000000001';
  const privacyRequestId = '30000000-0000-4000-8000-000000000001';

  const buildService = ({
    sessions = [],
    privacyRequest = null,
  }: {
    sessions?: Array<Partial<RefreshToken>>;
    privacyRequest?: Partial<PrivacyRequest> | null;
  } = {}) => {
    const refreshRepository = {
      find: jest.fn().mockResolvedValue(sessions),
      findOne: jest.fn().mockResolvedValue(sessions[0] ?? null),
      save: jest.fn(async (value) => value),
    };
    const privacyRepository = {
      find: jest.fn().mockResolvedValue(privacyRequest ? [privacyRequest] : []),
      findOne: jest.fn().mockResolvedValue(privacyRequest),
    };
    const dataSource = {
      getRepository: jest.fn((entity) => {
        if (entity === RefreshToken) return refreshRepository;
        if (entity === PrivacyRequest) return privacyRepository;
        throw new Error(`Unexpected repository ${String(entity)}`);
      }),
    };
    return {
      service: new CustomersService(dataSource as never, {} as never),
      refreshRepository,
      privacyRepository,
    };
  };

  it('lists only owned refresh-session metadata without token material', async () => {
    const createdAt = new Date('2026-08-01T10:00:00.000Z');
    const expiresAt = new Date('2026-09-01T10:00:00.000Z');
    const { service, refreshRepository } = buildService({
      sessions: [
        {
          id: sessionId,
          userId: customerId,
          tokenHash: 'must-never-be-returned',
          createdAt,
          expiresAt,
          isRevoked: false,
        },
      ],
    });

    const result = await service.securitySessions(customerId);

    expect(refreshRepository.find).toHaveBeenCalledWith({
      where: { userId: customerId },
      order: { createdAt: 'DESC' },
      take: 100,
    });
    expect(result).toEqual([
      {
        id: sessionId,
        createdAt,
        expiresAt,
        revoked: false,
        revokedAt: null,
      },
    ]);
    expect(result[0]).not.toHaveProperty('tokenHash');
    expect(result[0]).not.toHaveProperty('userId');
  });

  it('revokes an owned session idempotently and scopes lookup by owner', async () => {
    const active = {
      id: sessionId,
      userId: customerId,
      isRevoked: false,
    } as RefreshToken;
    const { service, refreshRepository } = buildService({ sessions: [active] });

    await service.revokeSecuritySession(customerId, sessionId);
    await service.revokeSecuritySession(customerId, sessionId);

    expect(refreshRepository.findOne).toHaveBeenCalledWith({
      where: { id: sessionId, userId: customerId },
    });
    expect(active.isRevoked).toBe(true);
    expect(active.revokedAt).toBeInstanceOf(Date);
    expect(refreshRepository.save).toHaveBeenCalledTimes(1);
  });

  it('does not reveal whether a foreign refresh session exists', async () => {
    const { service, refreshRepository } = buildService();
    refreshRepository.findOne.mockResolvedValue(null);

    await expect(
      service.revokeSecuritySession(customerId, sessionId),
    ).rejects.toThrow(NotFoundException);
    expect(refreshRepository.findOne).toHaveBeenCalledWith({
      where: { id: sessionId, userId: customerId },
    });
  });

  it('lists only closed owned privacy-request customer views', async () => {
    const requestedAt = new Date('2026-08-10T10:00:00.000Z');
    const { service, privacyRepository } = buildService({
      privacyRequest: {
        id: privacyRequestId,
        userId: customerId,
        requestType: 'export',
        status: 'pending',
        requestedAt,
        notes: 'internal reviewer note',
      },
    });

    const result = await service.privacyRequests(customerId);

    expect(privacyRepository.find).toHaveBeenCalledWith({
      where: { userId: customerId },
      order: { requestedAt: 'DESC' },
      take: 100,
    });
    expect(result).toEqual([
      {
        id: privacyRequestId,
        requestType: 'export',
        status: 'pending',
        requestedAt,
        completedAt: null,
      },
    ]);
    expect(Object.keys(result[0]).sort()).toEqual(
      ['completedAt', 'id', 'requestedAt', 'requestType', 'status'].sort(),
    );
  });
  it('returns only an owned privacy request customer view', async () => {
    const requestedAt = new Date('2026-08-10T10:00:00.000Z');
    const { service, privacyRepository } = buildService({
      privacyRequest: {
        id: privacyRequestId,
        userId: customerId,
        requestType: 'export',
        status: 'pending',
        requestedAt,
        notes: 'internal reviewer note',
      },
    });

    const result = await service.privacyRequest(customerId, privacyRequestId);

    expect(privacyRepository.findOne).toHaveBeenCalledWith({
      where: { id: privacyRequestId, userId: customerId },
    });
    expect(result).toEqual({
      id: privacyRequestId,
      requestType: 'export',
      status: 'pending',
      requestedAt,
      completedAt: null,
    });
    expect(result).not.toHaveProperty('userId');
    expect(result).not.toHaveProperty('notes');
  });

  it('returns not found for a missing or foreign privacy request', async () => {
    const { service, privacyRepository } = buildService();
    privacyRepository.findOne.mockResolvedValue(null);

    await expect(
      service.privacyRequest(customerId, privacyRequestId),
    ).rejects.toThrow(NotFoundException);
    expect(privacyRepository.findOne).toHaveBeenCalledWith({
      where: { id: privacyRequestId, userId: customerId },
    });
  });
});
