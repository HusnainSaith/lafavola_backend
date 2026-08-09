import {
  IsEnum,
  IsOptional,
  IsString,
  IsUUID,
  MaxLength,
} from 'class-validator';
import { SupportTicketCategory } from '../enums/support-ticket-category.enum';
import { SupportTicketPriority } from '../enums/support-ticket-priority.enum';

export class CreateSupportTicketDto {
  @IsOptional() @IsUUID() orderId?: string;
  @IsEnum(SupportTicketCategory) category: SupportTicketCategory;
  @IsString() @MaxLength(200) subject: string;
  @IsOptional() @IsEnum(SupportTicketPriority) priority?: SupportTicketPriority;
  @IsString() @MaxLength(5000) message: string;
}
