class ApiConfig {
  /// Base API URL for backend services.
  /// Can be overridden at build time via:
  /// `--dart-define=API_BASE_URL=https://api.yourdomain.com/api/v1`
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://finance-app-odoh.onrender.com/api/v1',
  );

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);
}
