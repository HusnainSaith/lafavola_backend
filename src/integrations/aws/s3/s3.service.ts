import {
  DeleteObjectCommand,
  HeadObjectCommand,
  PutObjectCommand,
  S3Client,
} from '@aws-sdk/client-s3';
import { getSignedUrl } from '@aws-sdk/s3-request-presigner';
import {
  Injectable,
  Logger,
  ServiceUnavailableException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import {
  PresignPutInput,
  PutObjectInput,
  StorageProvider,
  StoredObjectMetadata,
} from '../../storage/storage.interface';

@Injectable()
export class S3StorageProvider implements StorageProvider {
  readonly providerName = 'aws_s3';
  readonly bucket: string;
  private readonly client: S3Client;
  private readonly logger = new Logger(S3StorageProvider.name);

  constructor(private readonly config: ConfigService) {
    this.bucket = this.config.get<string>('AWS_S3_BUCKET', '');
    this.client = new S3Client({
      region: this.config.get<string>('AWS_REGION'),
      ...(this.config.get<string>('AWS_ACCESS_KEY_ID') &&
      this.config.get<string>('AWS_SECRET_ACCESS_KEY')
        ? {
            credentials: {
              accessKeyId: this.config.getOrThrow<string>('AWS_ACCESS_KEY_ID'),
              secretAccessKey: this.config.getOrThrow<string>(
                'AWS_SECRET_ACCESS_KEY',
              ),
            },
          }
        : {}),
    });
  }

  async presignPut(input: PresignPutInput): Promise<string> {
    this.assertConfigured();
    try {
      return await getSignedUrl(
        this.client,
        new PutObjectCommand({
          Bucket: this.bucket,
          Key: input.key,
          ContentType: input.contentType,
          ContentLength: input.contentLength,
        }),
        { expiresIn: input.expiresInSeconds },
      );
    } catch {
      this.failure('presign');
    }
  }

  async put(input: PutObjectInput): Promise<void> {
    this.assertConfigured();
    try {
      await this.client.send(
        new PutObjectCommand({
          Bucket: this.bucket,
          Key: input.key,
          ContentType: input.contentType,
          Body: input.body,
        }),
      );
    } catch {
      this.failure('upload');
    }
  }

  async head(key: string): Promise<StoredObjectMetadata> {
    this.assertConfigured();
    try {
      const result = await this.client.send(
        new HeadObjectCommand({ Bucket: this.bucket, Key: key }),
      );
      return {
        contentType: result.ContentType,
        contentLength: result.ContentLength,
      };
    } catch {
      this.failure('metadata');
    }
  }

  async delete(key: string): Promise<void> {
    this.assertConfigured();
    try {
      await this.client.send(
        new DeleteObjectCommand({ Bucket: this.bucket, Key: key }),
      );
    } catch {
      this.failure('delete');
    }
  }

  publicUrl(key: string): string | undefined {
    const base = this.config
      .get<string>('AWS_S3_PUBLIC_BASE_URL')
      ?.replace(/\/$/, '');
    return base
      ? `${base}/${key.split('/').map(encodeURIComponent).join('/')}`
      : undefined;
  }

  private assertConfigured() {
    if (!this.bucket || !this.config.get<string>('AWS_REGION')) {
      throw new ServiceUnavailableException('Object storage is unavailable');
    }
  }

  private failure(operation: string): never {
    this.logger.error(`S3 ${operation} operation failed`);
    throw new ServiceUnavailableException('Object storage is unavailable');
  }
}
