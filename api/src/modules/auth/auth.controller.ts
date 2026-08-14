import {
  Body,
  Controller,
  HttpCode,
  HttpStatus,
  Post,
  Request,
} from '@nestjs/common';
import { ApiBody, ApiOperation, ApiResponse, ApiTags } from '@nestjs/swagger';
import { Throttle } from '@nestjs/throttler';
import { BaseController } from '../../common/controllers/base.controller';
import { Public } from '../../common/decorators/public.decorator';
import { AuthService } from './auth.service';
import { AuthCredentialsDto } from './dto/auth-credentials.dto';
import {
  PasswordResetDto,
  RefreshTokenDto,
  ResetPasswordDto,
} from './dto/refresh-token.dto';
import { RegisterDto } from './dto/register.dto';
import { SocialLoginDto } from './dto/social-login.dto';
import { VerifyEmailCodeDto } from './dto/verify-token.dto';
import { SocialProvider } from './enums/social-provider.enum';

@ApiTags('Customer App - Authentication')
@Controller('auth')
export class AuthController extends BaseController {
  constructor(private readonly authService: AuthService) {
    super();
  }

  @Post('register')
  @Public()
  @Throttle({ default: { limit: 5, ttl: 60000 } })
  @ApiOperation({ summary: 'Register a customer or user account' })
  @ApiBody({ type: RegisterDto })
  @ApiResponse({
    status: 201,
    description: 'Account created; email verification is required before login',
  })
  @ApiResponse({ status: 400, description: 'Validation failed' })
  @ApiResponse({
    status: 409,
    description: 'Email or phone is already registered',
  })
  register(@Body() dto: RegisterDto) {
    return this.handleAsyncOperation(this.authService.register(dto));
  }

  @Post('login')
  @Public()
  @Throttle({ default: { limit: 5, ttl: 60000 } })
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Log in with account credentials' })
  @ApiBody({ type: AuthCredentialsDto })
  @ApiResponse({ status: 200, description: 'Authentication successful' })
  @ApiResponse({
    status: 401,
    description: 'Invalid credentials or email has not been verified',
  })
  login(@Body() dto: AuthCredentialsDto) {
    return this.handleAsyncOperation(this.authService.login(dto));
  }

  @Post('oauth/google')
  @Public()
  @Throttle({ default: { limit: 10, ttl: 60000 } })
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Sign in or register with a Google identity token' })
  @ApiBody({ type: SocialLoginDto })
  @ApiResponse({ status: 200, description: 'Google authentication successful' })
  @ApiResponse({ status: 401, description: 'Invalid Google identity token' })
  googleLogin(@Body() dto: SocialLoginDto) {
    return this.handleAsyncOperation(
      this.authService.socialLogin(SocialProvider.GOOGLE, dto),
    );
  }

  @Post('oauth/apple')
  @Public()
  @Throttle({ default: { limit: 10, ttl: 60000 } })
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Sign in or register with an Apple identity token' })
  @ApiBody({ type: SocialLoginDto })
  @ApiResponse({ status: 200, description: 'Apple authentication successful' })
  @ApiResponse({ status: 401, description: 'Invalid Apple identity token' })
  appleLogin(@Body() dto: SocialLoginDto) {
    return this.handleAsyncOperation(
      this.authService.socialLogin(SocialProvider.APPLE, dto),
    );
  }

  @Post('refresh')
  @Public()
  @Throttle({ default: { limit: 10, ttl: 60000 } })
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Exchange a refresh token for a new access token' })
  @ApiBody({ type: RefreshTokenDto })
  @ApiResponse({ status: 200, description: 'Access token refreshed' })
  @ApiResponse({
    status: 401,
    description: 'Refresh token is invalid or expired',
  })
  refresh(@Body() dto: RefreshTokenDto) {
    return this.handleAsyncOperation(this.authService.refreshToken(dto));
  }

  @Post('logout')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Revoke a refresh token and log out' })
  @ApiBody({ type: RefreshTokenDto })
  @ApiResponse({ status: 200, description: 'Logged out successfully' })
  logout(
    @Request() request: { user: { id: string } },
    @Body() dto: RefreshTokenDto,
  ) {
    return this.handleAsyncOperation(
      this.authService.logout(request.user.id, dto.refreshToken),
    );
  }

  @Post('forgot-password')
  @Public()
  @Throttle({ default: { limit: 3, ttl: 60000 } })
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Request a password-reset flow' })
  @ApiBody({ type: PasswordResetDto })
  @ApiResponse({
    status: 200,
    description: 'Password-reset request accepted',
  })
  requestPasswordReset(@Body() dto: PasswordResetDto) {
    return this.handleAsyncOperation(
      this.authService.requestPasswordReset(dto),
    );
  }

  @Post('reset-password')
  @Public()
  @Throttle({ default: { limit: 5, ttl: 60000 } })
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Reset password using only the emailed code' })
  @ApiBody({ type: ResetPasswordDto })
  @ApiResponse({ status: 200, description: 'Password reset successfully' })
  @ApiResponse({
    status: 401,
    description: 'Reset code is invalid, expired, or attempt-limited',
  })
  resetPassword(@Body() dto: ResetPasswordDto) {
    return this.handleAsyncOperation(this.authService.resetPassword(dto));
  }

  @Post('verify-email')
  @Public()
  @Throttle({ default: { limit: 10, ttl: 60000 } })
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Verify an email using the emailed 6-digit code' })
  @ApiBody({ type: VerifyEmailCodeDto })
  @ApiResponse({ status: 200, description: 'Email verified' })
  @ApiResponse({ status: 401, description: 'Code invalid or expired' })
  verifyEmail(@Body() dto: VerifyEmailCodeDto) {
    return this.handleAsyncOperation(this.authService.verifyEmail(dto.code));
  }

  @Post('request-email-verification')
  @Public()
  @Throttle({ default: { limit: 3, ttl: 60000 } })
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Send a new 6-digit email verification code' })
  @ApiBody({ type: PasswordResetDto })
  @ApiResponse({ status: 200, description: 'Verification request accepted' })
  requestEmailVerification(@Body() dto: PasswordResetDto) {
    return this.handleAsyncOperation(
      this.authService.resendEmailVerificationForEmail(dto.email),
    );
  }

  @Post('resend-verification')
  @Public()
  @Throttle({ default: { limit: 3, ttl: 60000 } })
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: 'Resend a 6-digit email verification code',
  })
  @ApiResponse({ status: 200, description: 'Verification request accepted' })
  resendVerification(@Body() dto: PasswordResetDto) {
    return this.handleAsyncOperation(
      this.authService.resendEmailVerificationForEmail(dto.email),
    );
  }
}
