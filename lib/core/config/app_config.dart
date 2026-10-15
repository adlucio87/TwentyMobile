class AppConfig {
  static const String glitchtipDsn =
      'https://ea9513cfee7b444f89c544908d31062c@app.glitchtip.com/21571';

  /// Build with `--dart-define=ERROR_REPORTING=false` to compile error reporting
  /// out entirely (self-hosted or privacy-sensitive deployments). The settings
  /// toggle is then hidden.
  static const bool errorReportingBuildEnabled =
      bool.fromEnvironment('ERROR_REPORTING', defaultValue: true);

  static const String errorReportingPrefKey = 'error_reporting_enabled';

  // ---------------------------------------------------------------------------
  // OAuth 2.0 (PKCE) — see README "OAuth 2.0 PKCE" for the setup steps.
  // ---------------------------------------------------------------------------

  /// Custom scheme the system browser hands the authorization code back to
  /// (`pocketcrm://oauth/callback`). Declared in ios/Runner/Info.plist and
  /// android/app/src/main/AndroidManifest.xml.
  static const String oauthCallbackScheme = 'pocketcrm';

  /// Twenty's own redirect propagator on the instance.
  ///
  /// It is the preferred callback: it lives on the instance domain (no third
  /// party sees the authorization code) and turns the redirect into a 302 to
  /// the custom scheme. It only accepts arbitrary callback URLs while
  /// multi-workspace is disabled, hence the HTTPS fallback below.
  static const String oauthPropagatorPath = '/auth/oauth-propagator/callback';

  /// HTTPS bouncer page used when the instance cannot redirect to a custom
  /// scheme (multi-workspace enabled) or when its capabilities are unknown.
  ///
  /// Override at build time with
  /// `--dart-define=OAUTH_REDIRECT_URI=https://your.domain/oauth/callback`.
  static const String oauthBouncerRedirectUri = String.fromEnvironment(
    'OAUTH_REDIRECT_URI',
    defaultValue: 'https://luciosoft-twentymobilecrm.web.app/oauth/callback',
  );

  /// OAuth scopes requested from Twenty.
  static const List<String> oauthScopes = ['api', 'profile'];

  /// Public registry used to look up and share pre-registered TwentyMobile
  /// OAuth client IDs per Twenty CRM instance, so multi-user teams share a
  /// single application on Twenty CRM rather than creating duplicates.
  ///
  /// Override at build time with
  /// `--dart-define=OAUTH_REGISTRY_URL=https://your.domain/api/oauth-client`.
  static const String oauthRegistryUrl = String.fromEnvironment(
    'OAUTH_REGISTRY_URL',
    defaultValue: 'https://twentymobilecrm.luciosoft.it/api/oauth-client',
  );
}
