class ApiConfig {
  /// Base API URL for backend services.
  /// Can be overridden at build time via:
  /// `--dart-define=API_BASE_URL=https://api.yourdomain.com/api/v1`
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://finance-app-odoh.onrender.com/api/v1',
  );

  // Generous on purpose: the free Render instance sleeps when idle and the
  // first request after that waits 30-60 s while it boots.
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 45);

  /// Health endpoint lives at the server root, outside `/api/v1`.
  static String get healthUrl => '${Uri.parse(baseUrl).origin}/health';
}
