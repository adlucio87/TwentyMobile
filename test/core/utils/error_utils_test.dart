import 'package:flutter_test/flutter_test.dart';
import 'package:pocketcrm/core/utils/error_utils.dart';

void main() {
  group('userFacingError', () {
    test('strips Exception: prefix from standard exceptions', () {
      final error = Exception('Simple error message');
      expect(userFacingError(error), 'Simple error message');
    });

    test('sanitizes ResponseFormatException and offset 0 FormatException', () {
      const error = 'OperationException(linkException: ResponseFormatException(originalException: FormatException: Unexpected character (at offset 0)))';
      expect(
        userFacingError(error),
        'Invalid response from server. Please verify your Instance URL.',
      );
    });

    test('sanitizes SocketException and connection refused', () {
      const error = 'SocketException: Connection refused (OS Error: Connection refused, errno = 111)';
      expect(
        userFacingError(error),
        'Unable to reach the server. Please check your connection or Instance URL.',
      );
    });

    test('sanitizes Failed host lookup', () {
      const error = 'ClientException: Failed host lookup: "crm.example.com"';
      expect(
        userFacingError(error),
        'Unable to reach the server. Please check your connection or Instance URL.',
      );
    });

    test('hides raw OperationException with stack traces', () {
      const error = 'OperationException(linkException: ServerException, originalStackTrace: *** *** pid: 1234)';
      expect(
        userFacingError(error),
        'Unexpected server error. Please verify your Instance URL and credentials.',
      );
    });
  });

  group('isUserCancellation', () {
    test('returns true for canceled error messages', () {
      expect(isUserCancellation('CANCELED'), isTrue);
      expect(isUserCancellation('User canceled'), isTrue);
      expect(isUserCancellation('usercancel'), isTrue);
      expect(isUserCancellation('operation cancelled by user'), isTrue);
    });

    test('returns false for actual network errors', () {
      expect(isUserCancellation('SocketException'), isFalse);
      expect(isUserCancellation('500 Internal Server Error'), isFalse);
    });
  });
}
