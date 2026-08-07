import {
  IsArray,
  IsOptional,
  IsString,
  IsUUID,
  MaxLength,
} from 'class-validator';

export class CreateSupportMessageDto {
  @IsString() @MaxLength(5000) body: string;
  @IsOptional()
  @IsArray()
  @IsUUID(undefined, { each: true })
  attachmentMediaIds?: string[];
}
