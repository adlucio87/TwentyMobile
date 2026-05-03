import 'package:http/http.dart' as http;

class TimeoutHttpClient extends http.BaseClient {
  final http.Client _inner = http.Client();
  final Duration timeoutDuration;

  TimeoutHttpClient({this.timeoutDuration = const Duration(seconds: 30)});

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    return _inner.send(request).timeout(timeoutDuration);
  }
}
