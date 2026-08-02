/// User-facing strings — mobile app (professional product tone).
library;

class ProductCopy {
  ProductCopy._();

  /// Guest / showcase account (API demo + local seed).
  static const guestAccessCta = 'Continue as guest';
  static const guestAccessHint = 'Preview with sample cases — read-only';
  static const guestSessionStarted = 'Guest session started';
  static const guestAccountType = 'Guest account · read-only preview';
  static const guestEditDisabled = 'Changes are disabled in guest mode';

  static const emailVerifySent = 'Verification email sent';
  static const emailVerifyBody =
      'Open the link in the email on this phone. It will return you to the app.';
  static const emailVerifiedSignIn = 'Email verified. Sign in with your password.';
  static const emailVerifiedDone = 'Email verified — welcome';
  static const resendVerification = 'Resend verification email';
  static const resendVerificationSent =
      "Sent — check your inbox and spam folder. Didn't sign up with this email before? "
      'There may be nothing to confirm.';
}
