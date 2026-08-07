import { ArrayMaxSize, IsArray, IsOptional, IsUUID } from 'class-validator';

export class BuildPizzaDto {
  @IsUUID() menuItemId: string;
  @IsUUID() menuItemSizeId: string;
  @IsOptional() @IsUUID() doughChoiceId?: string;
  @IsOptional() @IsUUID() sauceChoiceId?: string;
  @IsOptional() @IsUUID() cheeseChoiceId?: string;
  @IsArray()
  @ArrayMaxSize(30)
  @IsUUID(undefined, { each: true })
  toppingChoiceIds: string[];
}
