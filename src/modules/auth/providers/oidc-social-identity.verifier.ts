import {
  Injectable,
  ServiceUnavailableException,
  UnauthorizedException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { createRemoteJWKSet, jwtVerify, JWTPayload } from 'jose';
import { SocialProvider } from '../enums/social-provider.enum';
import {
  SocialIdentityVerifier,
  VerifiedSocialIdentity,
} from '../interfaces/social-identity-verifier.interface';

@Injectable()
export class OidcSocialIdentityVerifier implements SocialIdentityVerifier {
  private readonly googleKeys = createRemoteJWKSet(
    new URL('https://www.googleapis.com/oauth2/v3/certs'),
  );
  private readonly appleKeys = createRemoteJWKSet(
    new URL('https://appleid.apple.com/auth/keys'),
  );

  constructor(private readonly config: ConfigService) {}

  async verify(
    provider: SocialProvider,
    idToken: string,
  ): Promise<VerifiedSocialIdentity> {
    const audiences = this.audiences(provider);
    if (!audiences.length) {
      throw new ServiceUnavailableException(
        `${provider === SocialProvider.GOOGLE ? 'Google' : 'Apple'} OAuth is not configured`,
      );
    }

    try {
      const { payload } =
        provider === SocialProvider.GOOGLE
          ? await jwtVerify(idToken, this.googleKeys, {
              issuer: ['https://accounts.google.com', 'accounts.google.com'],
              audience: audiences,
              algorithms: ['RS256'],
            })
          : await jwtVerify(idToken, this.appleKeys, {
              issuer: 'https://appleid.apple.com',
              audience: audiences,
              algorithms: ['RS256'],
            });
      return this.identity(payload);
    } catch (error) {
      if (error instanceof ServiceUnavailableException) throw error;
      throw new UnauthorizedException(`Invalid ${provider} identity token`);
    }
  }

  private audiences(provider: SocialProvider): string[] {
    const key =
      provider === SocialProvider.GOOGLE
        ? 'GOOGLE_OAUTH_CLIENT_IDS'
        : 'APPLE_OAUTH_CLIENT_IDS';
    return String(this.config.get<string>(key, ''))
      .split(',')
      .map((value) => value.trim())
      .filter(Boolean);
  }

  private identity(payload: JWTPayload): VerifiedSocialIdentity {
    if (!payload.sub)
      throw new UnauthorizedException('Identity has no subject');
    const email =
      typeof payload.email === 'string'
        ? payload.email.toLowerCase().trim()
        : undefined;
    const verified = payload.email_verified;
    const emailVerified = verified === true || verified === 'true';
    const fullName =
      typeof payload.name === 'string' && payload.name.trim()
        ? payload.name.trim()
        : [payload.given_name, payload.family_name]
            .filter((value) => typeof value === 'string' && value.trim())
            .join(' ') || undefined;
    return { subject: payload.sub, email, emailVerified, fullName };
  }
}
