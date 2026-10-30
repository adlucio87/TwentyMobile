import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pocketcrm/data/connectors/twenty_connector.dart';

void main() {
  group('TwentyConnector.validateInstance', () {
    test('auto-prepends https:// and strips trailing slashes', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path == '/healthz') {
          return http.Response(jsonEncode({'status': 'ok'}), 200);
        }
        return http.Response('Not Found', 404);
      });

      final result = await TwentyConnector.validateInstance(
        'crm.example.com/',
        httpClient: mockClient,
      );

      expect(result, 'https://crm.example.com');
    });

    test('validates successfully when /healthz returns status ok', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path == '/healthz') {
          return http.Response(jsonEncode({'status': 'ok'}), 200);
        }
        return http.Response('Not Found', 404);
      });

      final result = await TwentyConnector.validateInstance(
        'https://app.twenty.com',
        httpClient: mockClient,
      );

      expect(result, 'https://app.twenty.com');
    });

    test('validates successfully when /client-config returns Twenty config', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path == '/healthz') {
          return http.Response('Disabled', 404);
        }
        if (request.url.path == '/client-config') {
          return http.Response(
            jsonEncode({'appVersion': 'v2.53.1', 'authProviders': []}),
            200,
          );
        }
        return http.Response('Not Found', 404);
      });

      final result = await TwentyConnector.validateInstance(
        'https://twenty.company.com',
        httpClient: mockClient,
      );

      expect(result, 'https://twenty.company.com');
    });

    test('validates successfully when /metadata GraphQL query responds', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path == '/healthz' || request.url.path == '/client-config') {
          return http.Response('Not Found', 404);
        }
        if (request.url.path == '/metadata' && request.method == 'POST') {
          return http.Response(
            jsonEncode({
              'data': {'__typename': 'Query'},
            }),
            200,
          );
        }
        return http.Response('Not Found', 404);
      });

      final result = await TwentyConnector.validateInstance(
        'https://twenty.company.com',
        httpClient: mockClient,
      );

      expect(result, 'https://twenty.company.com');
    });

    test('throws notTwentyInstance when endpoints return HTML 404 (non-Twenty server)', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          '<!DOCTYPE HTML><html><head><title>404 Not Found</title></head></html>',
          404,
          headers: {'content-type': 'text/html'},
        );
      });

      expect(
        () => TwentyConnector.validateInstance(
          'https://dexterisys.com',
          httpClient: mockClient,
        ),
        throwsA(
          isA<InstanceValidationException>().having(
            (e) => e.error,
            'error',
            InstanceValidationError.notTwentyInstance,
          ),
        ),
      );
    });

    test('throws unreachable when host lookup fails', () async {
      final mockClient = MockClient((request) async {
        throw http.ClientException('Failed host lookup: "crm.doesnotexist.xyz"');
      });

      expect(
        () => TwentyConnector.validateInstance(
          'https://crm.doesnotexist.xyz',
          httpClient: mockClient,
        ),
        throwsA(
          isA<InstanceValidationException>().having(
            (e) => e.error,
            'error',
            InstanceValidationError.unreachable,
          ),
        ),
      );
    });

    test('throws invalidUrl when input is empty or invalid', () async {
      expect(
        () => TwentyConnector.validateInstance('   '),
        throwsA(
          isA<InstanceValidationException>().having(
            (e) => e.error,
            'error',
            InstanceValidationError.invalidUrl,
          ),
        ),
      );
    });
  });
}
