import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppEnvironment {
  AppEnvironment._();

  static late final String _environmentName;
  static bool _isLoaded = false;

  static Future<void> load() async {
    if (_isLoaded) {
      return;
    }

    _environmentName = const String.fromEnvironment(
      'APP_ENV',
      defaultValue: 'local',
    );

    final fileName = _environmentName == 'cloud'
        ? 'assets/env/cloud.env'
        : 'assets/env/local.env';

    await dotenv.load(fileName: fileName);
    _isLoaded = true;
  }

  static String get environmentName =>
      dotenv.env['APP_ENV'] ?? _environmentName;

  static String get apiBaseUrl =>
      dotenv.env['API_BASE_URL'] ?? 'http://localhost:8000/api/v1';

  static String get wsBaseUrl =>
      dotenv.env['WS_BASE_URL'] ?? 'ws://localhost:8000/ws';

  static bool get useMockFallback =>
      (dotenv.env['USE_MOCK_FALLBACK'] ?? 'true').toLowerCase() == 'true';
}
