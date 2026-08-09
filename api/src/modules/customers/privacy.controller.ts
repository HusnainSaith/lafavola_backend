import { Body, Controller, Get, Param, Post, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiBody, ApiOperation, ApiTags } from '@nestjs/swagger';
import { AuthenticatedUser } from '../../common/interfaces/authenticated-user.interface';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CustomersService } from './customers.service';
import { CreatePrivacyRequestDto } from './dto/create-privacy-request.dto';
import { RecordPrivacyConsentDto } from './dto/record-privacy-consent.dto';

@ApiTags('Privacy')
@ApiBearerAuth('JWT-auth')
@Controller('customers/me/privacy')
@UseGuards(JwtAuthGuard)
export class PrivacyController {
  constructor(private readonly service: CustomersService) {}

  @Get('requests')
  @ApiOperation({ summary: 'List the customer privacy-request audit trail' })
  requests(@CurrentUser() user: AuthenticatedUser) {
    return this.service.privacyRequests(user.id);
  }

  @Post('requests')
  @ApiOperation({
    summary: 'Submit an export, correction, deletion or restriction request',
  })
  @ApiBody({ type: CreatePrivacyRequestDto })
  createRequest(
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: CreatePrivacyRequestDto,
  ) {
    return this.service.createPrivacyRequest(user.id, dto);
  }

  @Post('requests/:id/fulfill')
  @ApiOperation({
    summary:
      'Technically fulfill an owned export, restriction or deletion request',
  })
  fulfill(@CurrentUser() user: AuthenticatedUser, @Param('id') id: string) {
    return this.service.fulfillPrivacyRequest(user.id, id);
  }

  @Get('consents')
  @ApiOperation({ summary: 'List the customer consent audit trail' })
  consents(@CurrentUser() user: AuthenticatedUser) {
    return this.service.privacyConsents(user.id);
  }

  @Post('consents')
  @ApiOperation({ summary: 'Record grant or withdrawal for a policy version' })
  @ApiBody({ type: RecordPrivacyConsentDto })
  recordConsent(
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: RecordPrivacyConsentDto,
  ) {
    return this.service.recordPrivacyConsent(user.id, dto);
  }
}
