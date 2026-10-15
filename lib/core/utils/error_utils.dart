// Error presentation helpers shared by every onboarding screen.
//
// Keeping them here (instead of one private copy per screen) is what stopped
// the login flows from drifting apart: the same `Exception: ` prefix was
// stripped in three files and left untouched in the other two.

/// Strips the wrapper `Exception: ` prefix so raw framework errors never reach
/// the UI verbatim.
String userFacingError(Object error) {
  final message = error.toString();
  return message.startsWith('Exception: ') ? message.substring(11) : message;
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
