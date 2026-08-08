import { SocialProvider } from '../enums/social-provider.enum';

export const SOCIAL_IDENTITY_VERIFIER = Symbol('SOCIAL_IDENTITY_VERIFIER');

export interface VerifiedSocialIdentity {
  subject: string;
  email?: string;
  emailVerified: boolean;
  fullName?: string;
}

export interface SocialIdentityVerifier {
  verify(
    provider: SocialProvider,
    idToken: string,
  ): Promise<VerifiedSocialIdentity>;
}
