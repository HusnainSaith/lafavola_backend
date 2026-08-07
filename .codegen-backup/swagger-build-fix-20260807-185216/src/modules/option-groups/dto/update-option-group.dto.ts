import { PartialType } from '@nestjs/swagger';
import { CreateOptionGroupDto } from './create-option-group.dto';
export class UpdateOptionGroupDto extends PartialType(CreateOptionGroupDto) {}

