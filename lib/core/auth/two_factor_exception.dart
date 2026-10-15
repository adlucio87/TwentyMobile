/// Thrown when the server requires 2FA verification.
/// Carries the [loginToken] from step 1 so the OTP screen can
/// complete authentication via `getAuthTokensFromOTP`.
class TwoFactorRequiredException implements Exception {
  final String loginToken;
  final String instanceUrl;

  /// Auth method that started the flow (`email` or `sso`), so the OTP step
  /// persists the right one instead of always degrading an SSO login to email.
  final String authMethod;

  TwoFactorRequiredException({
    required this.loginToken,
    required this.instanceUrl,
    this.authMethod = 'email',
  });

  @override
  String toString() => 'TwoFactorRequiredException';
}
