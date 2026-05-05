/// Thrown when the server requires 2FA verification.
/// Carries the [loginToken] from step 1 so the OTP screen can
/// complete authentication via `getAuthTokensFromOTP`.
class TwoFactorRequiredException implements Exception {
  final String loginToken;
  final String instanceUrl;

  TwoFactorRequiredException({
    required this.loginToken,
    required this.instanceUrl,
  });

  @override
  String toString() => 'TwoFactorRequiredException';
}
