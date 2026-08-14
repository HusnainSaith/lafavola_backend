import { ConfigService } from '@nestjs/config';
import { ServiceUnavailableException } from '@nestjs/common';
import { S3StorageProvider } from '../../src/integrations/aws/s3/s3.service';

describe('S3 storage provider', () => {
  it('does not initialize the AWS client when S3 is disabled', async () => {
    const values: Record<string, unknown> = { AWS_S3_ENABLED: false };
    const config = {
      get: jest.fn(
        (key: string, fallback?: unknown) => values[key] ?? fallback,
      ),
      getOrThrow: jest.fn((key: string) => {
        throw new Error(`Unexpected configuration lookup: ${key}`);
      }),
    } as unknown as ConfigService;

    const provider = new S3StorageProvider(config);

    await expect(
      provider.presignPut({
        key: 'test/file.jpg',
        contentType: 'image/jpeg',
        contentLength: 10,
        expiresInSeconds: 60,
      }),
    ).rejects.toBeInstanceOf(ServiceUnavailableException);
    expect(config.getOrThrow).not.toHaveBeenCalled();
  });
});
