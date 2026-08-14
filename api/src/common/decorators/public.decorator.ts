import { applyDecorators, SetMetadata } from '@nestjs/common';
import { ApiExtension, ApiTags } from '@nestjs/swagger';

export const IS_PUBLIC_KEY = 'isPublic';
export const Public = () =>
  applyDecorators(
    SetMetadata(IS_PUBLIC_KEY, true),
    ApiExtension('x-audience', 'Public / Customer App'),
    ApiTags('Audience: Public / Customer App'),
  );
