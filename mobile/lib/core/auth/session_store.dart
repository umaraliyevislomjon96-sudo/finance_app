import 'dart:math';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Tokens and identity of the signed-in user, persisted in the platform keystore.
class Session {
  final String accessToken;
  final String refreshToken;
  final String userId;
  final String phone;

  const Session({
    required this.accessToken,
    required this.refreshToken,
    required this.userId,
    required this.phone,
  });

  factory Session.fromTokenResponse(Map<String, dynamic> json, {String? fallbackPhone}) => Session(
        accessToken: json['access_token'] as String,
        refreshToken: json['refresh_token'] as String,
        userId: json['user_id'] as String,
        phone: (json['phone'] as String?)?.isNotEmpty == true ? json['phone'] as String : (fallbackPhone ?? ''),
      );
}

/// Single place that reads and writes auth secrets. Everything lives in
/// encrypted storage (Android Keystore / iOS Keychain), never in plain prefs.
class SessionStore {
  static final SessionStore instance = SessionStore._();
  SessionStore._();

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true, resetOnError: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock_this_device),
  );

  static const _kAccess = 'auth.access_token';
  static const _kRefresh = 'auth.refresh_token';
  static const _kUser = 'auth.user_id';
  static const _kPhone = 'auth.phone';
  static const _kDevice = 'auth.device_id';

  Session? _cached;
  String? _deviceId;

  Session? get current => _cached;

  Future<Session?> load() async {
    final values = await Future.wait([
      _storage.read(key: _kAccess),
      _storage.read(key: _kRefresh),
      _storage.read(key: _kUser),
      _storage.read(key: _kPhone),
    ]);
    if (values[0] == null || values[1] == null || values[2] == null) {
      _cached = null;
      return null;
    }
    _cached = Session(
      accessToken: values[0]!,
      refreshToken: values[1]!,
      userId: values[2]!,
      phone: values[3] ?? '',
    );
    return _cached;
  }

  Future<void> save(Session session) async {
    _cached = session;
    await Future.wait([
      _storage.write(key: _kAccess, value: session.accessToken),
      _storage.write(key: _kRefresh, value: session.refreshToken),
      _storage.write(key: _kUser, value: session.userId),
      _storage.write(key: _kPhone, value: session.phone),
    ]);
  }

  Future<void> clear() async {
    _cached = null;
    await Future.wait([
      _storage.delete(key: _kAccess),
      _storage.delete(key: _kRefresh),
      _storage.delete(key: _kUser),
      _storage.delete(key: _kPhone),
    ]);
  }

  /// Stable per-install identifier sent with sign-in so the server can bind
  /// tokens to this device. Generated once and kept across sign-outs.
  Future<String> deviceId() async {
    if (_deviceId != null) return _deviceId!;
    var id = await _storage.read(key: _kDevice);
    if (id == null) {
      final rnd = Random.secure();
      id = List.generate(16, (_) => rnd.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
      await _storage.write(key: _kDevice, value: id);
    }
    return _deviceId = id;
  }

  // Generic access for the PIN service, which keeps its own keys here.
  Future<String?> read(String key) => _storage.read(key: key);
  Future<void> write(String key, String value) => _storage.write(key: key, value: value);
  Future<void> delete(String key) => _storage.delete(key: key);
}
