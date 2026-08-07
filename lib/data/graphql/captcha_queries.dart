/// GraphQL query to fetch the CAPTCHA configuration from the Twenty server.
/// The `clientConfig` query is served on the `/metadata` endpoint (unauthenticated).
///
/// Returns the captcha provider type ("GoogleRecaptcha" or "Turnstile")
/// and the public siteKey needed to render the widget.
const String getClientConfigQuery = r'''
query GetClientConfig {
  clientConfig {
    captcha {
      provider
      siteKey
    }
  }
}
''';
