// Error presentation helpers shared by every onboarding screen.
//
// Keeping them here (instead of one private copy per screen) is what stopped
// the login flows from drifting apart: the same `Exception: ` prefix was
// stripped in three files and left untouched in the other two.

/// Strips the wrapper `Exception: ` prefix and sanitizes raw technical errors
/// so low-level framework dumps (like GraphQL OperationException, ResponseFormatException,
/// or stack traces) never reach the UI verbatim.
String userFacingError(Object error) {
  var message = error.toString();
  if (message.startsWith('Exception: ')) {
    message = message.substring(11);
  }

  final lower = message.toLowerCase();
  if (lower.contains('responseformatexception') ||
      lower.contains('formatexception: unexpected character') ||
      lower.contains('unexpected character (at offset 0)')) {
    return 'Invalid response from server. Please verify your Instance URL.';
  }

  if (lower.contains('failed host lookup') ||
      lower.contains('socketexception') ||
      lower.contains('connection refused') ||
      lower.contains('network is unreachable')) {
    return 'Unable to reach the server. Please check your connection or Instance URL.';
  }

  if (lower.contains('operationexception') || message.contains('originalStackTrace:')) {
    return 'Unexpected server error. Please verify your Instance URL and credentials.';
  }

  return message;
}

/// True when the user dismissed the system browser or the embedded web flow.
///
/// `flutter_web_auth_2` reports cancellations as `CANCELED` on Android and as
/// `UserCancel`/`cancelled` elsewhere, so all spellings are covered here.
bool isUserCancellation(Object error) {
  final message = error.toString().toLowerCase();
  return message.contains('canceled') ||
      message.contains('cancelled') ||
      message.contains('usercancel');
}
