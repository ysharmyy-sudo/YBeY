import 'package:flutter/foundation.dart';

class ApiConfig {
  static const String _envBaseUrl =
      String.fromEnvironment('API_BASE_URL', defaultValue: '');

  static String get baseUrl {
    final String fromEnv = _envBaseUrl.trim();

    if (fromEnv.isNotEmpty) {
      return fromEnv.endsWith('/')
          ? fromEnv.substring(0, fromEnv.length - 1)
          : fromEnv;
    }

    // Web ke liye
    if (kIsWeb) {
      return 'http://127.0.0.1:8000';
    }

    // Android emulator ke liye
    return 'http://10.0.2.2:8000';
  }
}
