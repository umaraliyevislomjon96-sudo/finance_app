import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/api_config.dart';

class SocialAuthService {
  static final SocialAuthService instance = SocialAuthService._();
  SocialAuthService._();

  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final Dio _dio = Dio(BaseOptions(
    baseUrl: ApiConfig.baseUrl,
    connectTimeout: ApiConfig.connectTimeout,
    receiveTimeout: ApiConfig.receiveTimeout,
  ));

  Future<Map<String, dynamic>?> signInWithProvider({
    required String provider, // "google", "apple", "github"
    String? tokenOrCode,
    String? email,
    String? name,
    String deviceId = "mobile-device-uuid-primary",
    String deviceName = "Mobile Device",
  }) async {
    try {
      final String payloadToken = tokenOrCode ?? 'mock_${provider}_oauth_token_${DateTime.now().millisecondsSinceEpoch}';
      final String resolvedEmail = email ?? 'user.${provider}@aurora.finance';
      final String resolvedName = name ?? (provider == 'google' ? 'Google User' : provider == 'apple' ? 'Apple User' : 'GitHub Dev');

      final response = await _dio.post(
        '/auth/oauth/sign-in',
        data: {
          'provider': provider,
          'token_or_code': payloadToken,
          'email': resolvedEmail,
          'name': resolvedName,
          'device_id': deviceId,
          'device_name': deviceName,
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = Map<String, dynamic>.from(response.data);
        await _storage.write(key: 'access_token', value: data['access_token']);
        await _storage.write(key: 'refresh_token', value: data['refresh_token']);
        await _storage.write(key: 'user_id', value: data['user_id']);
        return data;
      }
    } catch (e) {
      debugPrint('OAuth sign-in error ($provider): $e');
    }
    return null;
  }

  Future<String?> getAccessToken() async {
    return await _storage.read(key: 'access_token');
  }

  Future<void> logout() async {
    await _storage.deleteAll();
  }
}
