import { BadRequestException, NotFoundException } from '@nestjs/common';
import { MailPasswordResetDelivery } from '../../src/integrations/mail/mail-password-reset.delivery';
import { MediaPurpose } from '../../src/modules/media/dto/create-upload-url.dto';
import { MediaService } from '../../src/modules/media/media.service';

describe('mail templates and media storage boundary', () => {
  it('delivers a password reset token in the link and as visible text', async () => {
    const mail = { send: jest.fn().mockResolvedValue({}) };
    const config = {
      getOrThrow: jest.fn().mockReturnValue('https://app.example/reset'),
    };
    const delivery = new MailPasswordResetDelivery(mail, config as never);
    await delivery.sendPasswordReset('customer@example.com', 'raw-secret');
    expect(mail.send).toHaveBeenCalledWith(
      expect.objectContaining({
        to: 'customer@example.com',
        text: expect.stringContaining('token=raw-secret'),
      }),
    );
    expect(mail.send).toHaveBeenCalledWith(
      expect.objectContaining({
        html: expect.stringContaining(
          '<code style="word-break:break-all">raw-secret</code>',
        ),
        text: expect.stringContaining(
          'Reset token (for manual entry):\nraw-secret',
        ),
      }),
    );
    expect(config.getOrThrow).toHaveBeenCalledWith('PASSWORD_RESET_URL');
  });

  function mediaFixture() {
    const assets = {
      create: jest.fn((value) => value),
      save: jest.fn(async (value) => ({ id: 'asset-id', ...value })),
      findOne: jest.fn(),
    };
    const storage = {
      providerName: 'aws_s3',
      bucket: 'test-bucket',
      presignPut: jest.fn().mockResolvedValue('https://signed.example/put'),
      put: jest.fn().mockResolvedValue(undefined),
      head: jest.fn(),
      delete: jest.fn(),
      publicUrl: jest.fn((key) => `https://cdn.example/${key}`),
    };
    const service = new MediaService({} as never, assets as never, storage);
    return { service, assets, storage };
  }

  it('authorizes an avatar with a server-generated scoped key', async () => {
    const { service, assets, storage } = mediaFixture();
    const result = await service.authorizeUpload('user-id', {
      purpose: MediaPurpose.AVATAR,
      fileName: '../../chosen-key.jpg',
      mimeType: 'image/jpeg',
      sizeBytes: 1_000,
    });
    const persisted = assets.create.mock.calls[0][0];
    expect(persisted.objectKey).toMatch(
      /^customers\/user-id\/avatars\/[0-9a-f-]{36}\.jpg$/,
    );
    expect(persisted.objectKey).not.toContain('chosen-key');
    expect(storage.presignPut).toHaveBeenCalledWith(
      expect.objectContaining({ expiresInSeconds: 300 }),
    );
    expect(result).toEqual(
      expect.objectContaining({ assetId: 'asset-id', method: 'PUT' }),
    );
  });

  it('rejects dangerous or oversized avatar uploads before signing', async () => {
    const { service, storage } = mediaFixture();
    await expect(
      service.authorizeUpload('user-id', {
        purpose: MediaPurpose.AVATAR,
        fileName: 'payload.svg',
        mimeType: 'image/svg+xml',
        sizeBytes: 100,
      }),
    ).rejects.toBeInstanceOf(BadRequestException);
    await expect(
      service.authorizeUpload('user-id', {
        purpose: MediaPurpose.AVATAR,
        fileName: 'large.jpg',
        mimeType: 'image/jpeg',
        sizeBytes: 6 * 1024 * 1024,
      }),
    ).rejects.toBeInstanceOf(BadRequestException);
    expect(storage.presignPut).not.toHaveBeenCalled();
  });

  it('verifies object metadata before finalization', async () => {
    const { service, assets, storage } = mediaFixture();
    assets.findOne.mockResolvedValue({
      id: 'asset-id',
      uploadedByUserId: 'user-id',
      status: 'pending',
      objectKey: 'customers/user-id/avatars/id.jpg',
      mimeType: 'image/jpeg',
      sizeBytes: '1000',
      purpose: MediaPurpose.AVATAR,
    });
    storage.head.mockResolvedValue({
      contentType: 'image/png',
      contentLength: 1000,
    });
    await expect(
      service.finalize('user-id', 'asset-id', {}),
    ).rejects.toBeInstanceOf(BadRequestException);
  });

  it('never deletes another user media or a caller supplied key', async () => {
    const { service, assets, storage } = mediaFixture();
    assets.findOne.mockResolvedValue({
      id: 'asset-id',
      uploadedByUserId: 'owner-id',
      objectKey: 'trusted/key.jpg',
    });
    await expect(
      service.remove('attacker-id', 'asset-id'),
    ).rejects.toBeInstanceOf(NotFoundException);
    expect(storage.delete).not.toHaveBeenCalled();
  });
});
