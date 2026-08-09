export const STORAGE_PROVIDER = Symbol('STORAGE_PROVIDER');

export interface PresignPutInput {
  key: string;
  contentType: string;
  contentLength: number;
  expiresInSeconds: number;
}

export interface StoredObjectMetadata {
  contentType?: string;
  contentLength?: number;
}

export interface PutObjectInput {
  key: string;
  contentType: string;
  body: Buffer;
}

export interface StorageProvider {
  readonly providerName: string;
  readonly bucket: string;
  presignPut(input: PresignPutInput): Promise<string>;
  put(input: PutObjectInput): Promise<void>;
  head(key: string): Promise<StoredObjectMetadata>;
  delete(key: string): Promise<void>;
  publicUrl(key: string): string | undefined;
}
