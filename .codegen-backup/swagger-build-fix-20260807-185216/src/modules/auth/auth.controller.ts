import {
  Body,
  Controller,
  HttpCode,
  HttpStatus,
  Post,
} from '@nestjs/common';
import { ApiBearerAuth, ApiBody, ApiOperation, ApiParam, ApiQuery, ApiResponse, ApiTags } from '@nestjs/swagger';
import { AuthService } from './auth.service';
import { RegisterDto } from './dto/register.dto';
import { AuthCredentialsDto } from './dto/auth-credentials.dto';
import {
  RefreshTokenDto,
  PasswordResetDto,
  ResetPasswordDto,
} from './dto/refresh-token.dto';
import { BaseController } from '../../common/controllers/base.controller';

@ApiTags('Auth')
@Controller('auth')
export class AuthController extends BaseController {
  constructor(private readonly authService: AuthService) {
    super();
  }

  @Post('register')
  @ApiOperation({ summary: 'Register a customer or user account' })
  @ApiBody({ type: RegisterDto })
  @ApiResponse({ status: 201, description: 'Account created successfully' })
  @ApiResponse({ status: 400, description: 'Validation failed' })
  @ApiResponse({ status: 409, description: 'Email or phone is already registered' })
  register(@Body() dto: RegisterDto) {
    return this.handleAsyncOperation(this.authService.register(dto));
  }

  @Post('login')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Log in with account credentials' })
  @ApiBody({ type: AuthCredentialsDto })
  @ApiResponse({ status: 200, description: 'Authentication successful' })
  @ApiResponse({ status: 401, description: 'Invalid credentials' })
  login(@Body() dto: AuthCredentialsDto) {
    return this.handleAsyncOperation(this.authService.login(dto));
  }

  @Post('refresh')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Exchange a refresh token for a new access token' })
  @ApiBody({ type: RefreshTokenDto })
  @ApiResponse({ status: 200, description: 'Access token refreshed' })
  @ApiResponse({ status: 401, description: 'Refresh token is invalid or expired' })
  refresh(@Body() dto: RefreshTokenDto) {
    return this.handleAsyncOperation(this.authService.refreshToken(dto));
  }

  @Post('logout')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Revoke a refresh token and log out' })
  @ApiBody({ type: RefreshTokenDto })
  @ApiResponse({ status: 200, description: 'Logged out successfully' })
  logout(@Body() dto: RefreshTokenDto) {
    return this.handleAsyncOperation(
      this.authService.logout(dto.refreshToken),
    );
  }

  @Post('password-forgot')
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
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Reset the account password using a valid token' })
  @ApiBody({ type: ResetPasswordDto })
  @ApiResponse({ status: 200, description: 'Password reset successfully' })
  @ApiResponse({ status: 400, description: 'Reset token is invalid or expired' })
  resetPassword(@Body() dto: ResetPasswordDto) {
    return this.handleAsyncOperation(this.authService.resetPassword(dto));
  }
}
