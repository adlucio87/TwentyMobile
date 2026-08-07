import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:pocketcrm/core/network/custom_http_client.dart';
import 'package:pocketcrm/data/graphql/captcha_queries.dart';

/// Represents the captcha configuration retrieved from the Twenty server.
class CaptchaConfig {
  final String provider; // "GoogleRecaptcha" or "Turnstile"
  final String siteKey;

  CaptchaConfig({required this.provider, required this.siteKey});
}

/// Service responsible for:
/// 1. Querying the Twenty server to determine if captcha is required and which provider is used.
/// 2. Generating a captchaToken via a hidden WebView when needed.
class CaptchaService {
  CaptchaConfig? _cachedConfig;

  /// Fetches the captcha configuration from the server's clientConfig endpoint.
  /// Returns null if captcha is not enabled on the instance.
  Future<CaptchaConfig?> fetchCaptchaConfig(String instanceUrl) async {
    if (_cachedConfig != null) return _cachedConfig;

    try {
      final customHttpClient = TimeoutHttpClient(
        timeoutDuration: const Duration(seconds: 15),
      );
      final link = HttpLink(
        '$instanceUrl/metadata',
        httpClient: customHttpClient,
      );
      final client = GraphQLClient(
        link: link,
        cache: GraphQLCache(),
        queryRequestTimeout: const Duration(seconds: 15),
      );

      final result = await client.query(
        QueryOptions(document: gql(getClientConfigQuery)),
      );

      if (result.hasException) {
        debugPrint('CaptchaService: Failed to fetch clientConfig: ${result.exception}');
        return null;
      }

      final captchaData = result.data?['clientConfig']?['captcha'];
      if (captchaData == null) {
        debugPrint('CaptchaService: No captcha config found — captcha is disabled.');
        return null;
      }

      final provider = captchaData['provider'] as String?;
      final siteKey = captchaData['siteKey'] as String?;

      if (provider == null || siteKey == null || provider.isEmpty || siteKey.isEmpty) {
        debugPrint('CaptchaService: Captcha config incomplete — captcha is disabled.');
        return null;
      }

      _cachedConfig = CaptchaConfig(provider: provider, siteKey: siteKey);
      debugPrint('CaptchaService: Captcha enabled — provider=$provider');
      return _cachedConfig;
    } catch (e) {
      debugPrint('CaptchaService: Error fetching captcha config: $e');
      return null;
    }
  }

  /// Clears the cached config (useful when switching instances).
  void clearCache() {
    _cachedConfig = null;
  }

  /// Generates a captcha token using an invisible WebView.
  /// Returns the token string, or throws if generation fails.
  Future<String> generateCaptchaToken(CaptchaConfig config) async {
    final completer = Completer<String>();
    HeadlessInAppWebView? headlessWebView;
    Timer? timeoutTimer;

    // Safety timeout — 30s should be plenty for captcha resolution
    timeoutTimer = Timer(const Duration(seconds: 30), () {
      if (!completer.isCompleted) {
        headlessWebView?.dispose();
        completer.completeError(
          Exception('Captcha verification timed out. Please try again.'),
        );
      }
    });

    final html = _buildCaptchaHtml(config);

    headlessWebView = HeadlessInAppWebView(
      initialData: InAppWebViewInitialData(data: html),
      initialSettings: InAppWebViewSettings(
        javaScriptEnabled: true,
        // Allow Cloudflare/Google scripts to load
        allowUniversalAccessFromFileURLs: true,
        allowFileAccessFromFileURLs: true,
      ),
      onConsoleMessage: (controller, consoleMessage) {
        final message = consoleMessage.message;
        debugPrint('CaptchaWebView console: $message');

        // The JS in our HTML page sends the token via console.log with a prefix
        if (message.startsWith('CAPTCHA_TOKEN:')) {
          final token = message.substring('CAPTCHA_TOKEN:'.length).trim();
          if (token.isNotEmpty && !completer.isCompleted) {
            timeoutTimer?.cancel();
            headlessWebView?.dispose();
            completer.complete(token);
          }
        } else if (message.startsWith('CAPTCHA_ERROR:')) {
          final error = message.substring('CAPTCHA_ERROR:'.length).trim();
          if (!completer.isCompleted) {
            timeoutTimer?.cancel();
            headlessWebView?.dispose();
            completer.completeError(
              Exception('Captcha verification failed: $error'),
            );
          }
        }
      },
      onReceivedError: (controller, request, error) {
        debugPrint('CaptchaWebView load error: ${error.type} - ${error.description}');
        if (!completer.isCompleted) {
          timeoutTimer?.cancel();
          headlessWebView?.dispose();
          completer.completeError(
            Exception('Failed to load captcha verification. Check your connection.'),
          );
        }
      },
    );

    try {
      await headlessWebView.run();
    } catch (e) {
      timeoutTimer.cancel();
      headlessWebView.dispose();
      if (!completer.isCompleted) {
        completer.completeError(
          Exception('Failed to initialize captcha verification: $e'),
        );
      }
    }

    return completer.future;
  }

  /// Builds a minimal HTML page that loads the captcha script and auto-executes
  /// the invisible/managed challenge. The resulting token is sent back
  /// to Flutter via console.log with a "CAPTCHA_TOKEN:" prefix.
  String _buildCaptchaHtml(CaptchaConfig config) {
    if (config.provider.toLowerCase().contains('turnstile')) {
      return _buildTurnstileHtml(config.siteKey);
    } else {
      return _buildRecaptchaHtml(config.siteKey);
    }
  }

  String _buildTurnstileHtml(String siteKey) {
    return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <script src="https://challenges.cloudflare.com/turnstile/v0/api.js?onload=onTurnstileLoad" async defer></script>
  <script>
    function onTurnstileLoad() {
      try {
        turnstile.render('#captcha-container', {
          sitekey: '$siteKey',
          callback: function(token) {
            console.log('CAPTCHA_TOKEN:' + token);
          },
          'error-callback': function(err) {
            console.log('CAPTCHA_ERROR:' + (err || 'Unknown Turnstile error'));
          },
          'expired-callback': function() {
            console.log('CAPTCHA_ERROR:Token expired, please retry');
          },
          appearance: 'interaction-only',
          execution: 'render'
        });
      } catch(e) {
        console.log('CAPTCHA_ERROR:' + e.toString());
      }
    }
  </script>
</head>
<body>
  <div id="captcha-container"></div>
</body>
</html>
''';
  }

  String _buildRecaptchaHtml(String siteKey) {
    return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <script src="https://www.google.com/recaptcha/api.js?render=$siteKey"></script>
  <script>
    document.addEventListener('DOMContentLoaded', function() {
      try {
        grecaptcha.ready(function() {
          grecaptcha.execute('$siteKey', {action: 'login'}).then(function(token) {
            console.log('CAPTCHA_TOKEN:' + token);
          }).catch(function(err) {
            console.log('CAPTCHA_ERROR:' + (err || 'Unknown reCAPTCHA error'));
          });
        });
      } catch(e) {
        console.log('CAPTCHA_ERROR:' + e.toString());
      }
    });
  </script>
</head>
<body></body>
</html>
''';
  }
}
