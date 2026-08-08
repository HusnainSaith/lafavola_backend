import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsInt, IsOptional, Max, Min } from 'class-validator';

export class FinalizeUploadDto {
  @ApiPropertyOptional()
  @IsOptional()
  @IsInt()
  @Min(1)
  @Max(20000)
  width?: number;
  @ApiPropertyOptional()
  @IsOptional()
  @IsInt()
  @Min(1)
  @Max(20000)
  height?: number;
}

export class UploadAuthorizationResponseDto {
  assetId: string;
  uploadUrl: string;
  expiresInSeconds: number;
  method: 'PUT';
  requiredHeaders: Record<string, string>;
}
