import { Expose } from 'class-transformer';
import { IsString, MaxLength } from 'class-validator';

export class SumUpWebhookDto {
  @Expose({ name: 'event_type' })
  @IsString()
  @MaxLength(160)
  eventType: string;

  @IsString()
  @MaxLength(255)
  id: string;
}
