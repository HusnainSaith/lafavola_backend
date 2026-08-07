export interface PresignedUploadResult {
  mediaAssetId: string;
  objectKey: string;
  uploadUrl: string;
  expiresInSeconds: number;
  requiredHeaders: Record<string, string>;
}
