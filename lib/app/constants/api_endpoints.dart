import 'package:flutter/foundation.dart';

class ApiEndpoints {
  // Android emulator: pass http://10.0.2.2:3000/api/v1/ via --dart-define.
  static const String configuredBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );
  static String get baseUrl => configuredBaseUrl.isNotEmpty
      ? configuredBaseUrl
      : kIsWeb
      ? Uri.base.resolve('/api/v1/').toString()
      : 'http://localhost:3000/api/v1/';
  // No live socket integration exists yet.
  static const String socketUrl = String.fromEnvironment('SOCKET_URL');
}
