import {
  IsObject,
  IsOptional,
  IsString,
  IsUUID,
  MaxLength,
} from 'class-validator';

export class CreateFavoriteDto {
  @IsUUID() restaurantId: string;
  @IsOptional() @IsUUID() menuItemId?: string;
  @IsOptional() @IsUUID() sourceOrderItemId?: string;
  @IsOptional() @IsString() @MaxLength(120) label?: string;
  @IsOptional() @IsObject() configurationSnapshot?: Record<string, unknown>;
}
