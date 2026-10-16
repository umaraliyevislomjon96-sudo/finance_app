import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

class SecureStorageService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      resetOnError: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  final LocalAuthentication _auth = LocalAuthentication();

  static const String _tokenKey = 'auth_jwt_token';
  static const String _pinHashKey = 'user_pin_hash';
  static const String _biometricsKey = 'biometrics_enabled';

  Future<void> saveAuthToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  Future<String?> getAuthToken() async {
    return await _storage.read(key: _tokenKey);
  }

  Future<void> savePinHash(String hash) async {
    await _storage.write(key: _pinHashKey, value: hash);
  }

  Future<String?> getPinHash() async {
    return await _storage.read(key: _pinHashKey);
  }

  Future<bool> authenticateWithBiometrics() async {
    final canCheck = await _auth.canCheckBiometrics;
    final isDeviceSupported = await _auth.isDeviceSupported();

    if (!canCheck || !isDeviceSupported) return false;

    return await _auth.authenticate(
      localizedReason: 'Подтвердите личность для доступа к финансовому ассистенту',
      options: const AuthenticationOptions(
        stickyAuth: true,
        biometricOnly: true,
      ),
    );
  }

  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
