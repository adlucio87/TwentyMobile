import 'package:flutter/foundation.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

/// Purges the browsing session kept by the embedded Google / SSO login.
///
/// The web login runs inside an `InAppWebView`, which owns its own cookie jar
/// and web storage (the Google session cookie plus the Twenty session cookie).
/// Logging out of the app clears the secure storage but **not** that jar, so a
/// later attempt could silently re-authenticate from a stale session — a real
/// problem on a shared device.
///
/// Every operation is best-effort: a platform failure must never break logout.
class WebAuthSessionCleaner {
  WebAuthSessionCleaner._();

  /// Clears cookies and web storage used by the embedded web login.
  static Future<void> clear() async {
    try {
      await CookieManager.instance().deleteAllCookies();
    } catch (e) {
      debugPrint('WebAuthSessionCleaner: cookie cleanup failed: $e');
    }
    try {
      await WebStorageManager.instance().deleteAllData();
    } catch (e) {
      debugPrint('WebAuthSessionCleaner: web storage cleanup failed: $e');
    }
  }
}
