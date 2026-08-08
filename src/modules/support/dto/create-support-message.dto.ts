import {
  IsArray,
  IsOptional,
  IsNotEmpty,
  IsString,
  IsUUID,
  MaxLength,
} from 'class-validator';

export class CreateSupportMessageDto {
  @IsString() @IsNotEmpty() @MaxLength(5000) body: string;
  @IsOptional()
  @IsArray()
  @IsUUID(undefined, { each: true })
  attachmentMediaIds?: string[];
}
