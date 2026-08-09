import { IsInt, Max, Min } from 'class-validator';

export class AddFavoriteToCartDto {
  @IsInt()
  @Min(1)
  @Max(50)
  quantity: number = 1;
}
