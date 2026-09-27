class AppConfig {
  static const String glitchtipDsn =
      'https://ea9513cfee7b444f89c544908d31062c@app.glitchtip.com/21571';

  /// Build with `--dart-define=ERROR_REPORTING=false` to compile error reporting
  /// out entirely (self-hosted or privacy-sensitive deployments). The settings
  /// toggle is then hidden.
  static const bool errorReportingBuildEnabled =
      bool.fromEnvironment('ERROR_REPORTING', defaultValue: true);

  static const String errorReportingPrefKey = 'error_reporting_enabled';
}
