import 'package:flutter/foundation.dart';
import '../network/api_client.dart';
import '../network/api_exception.dart';
import 'pin_service.dart';
import 'session_store.dart';

enum AuthStatus {
  /// Reading stored session on launch.
  loading,

  /// No session: phone + SMS code sign-in required.
  signedOut,

  /// Signed in on the server but no local PIN yet.
  needsPin,

  /// Session exists; app is locked behind the PIN / biometrics.
  locked,

  /// Ready to use.
  unlocked,
}

class OtpRequestResult {
  final int expiresInSeconds;

  /// Returned only by the sandbox SMS provider; null in production.
  final String? demoCode;
  const OtpRequestResult(this.expiresInSeconds, this.demoCode);
}

/// Drives the launch flow: sign-in → PIN setup → unlock, and back to sign-in
/// when the session ends. Screens call these methods; [AuthGate] reacts to [status].
class AuthController extends ChangeNotifier {
  static final AuthController instance = AuthController._();

  AuthController._() {
    _api.onSessionExpired = _handleSessionExpired;
  }

  final SessionStore _store = SessionStore.instance;
  final PinService _pin = PinService.instance;
  final ApiClient _api = ApiClient.instance;

  AuthStatus _status = AuthStatus.loading;
  AuthStatus get status => _status;

  /// Shown once on the sign-in screen after a forced sign-out.
  String? signOutReason;

  String? get phone => _store.current?.phone;

  void _set(AuthStatus s) {
    if (_status == s) return;
    _status = s;
    notifyListeners();
  }

  Future<void> bootstrap() async {
    final session = await _store.load();
    if (session == null) {
      _set(AuthStatus.signedOut);
    } else if (!await _pin.hasPin()) {
      _set(AuthStatus.needsPin);
    } else {
      _set(AuthStatus.locked);
    }
  }

  Future<OtpRequestResult> requestOtp(String phone) async {
    try {
      final res = await _api.dio.post('/auth/otp/request', data: {'phone': phone});
      final data = Map<String, dynamic>.from(res.data);
      return OtpRequestResult(
        (data['expires_in_seconds'] as num?)?.toInt() ?? 60,
        data['demo_code'] as String?,
      );
    } catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<void> verifyOtp(String phone, String code) async {
    try {
      final res = await _api.dio.post('/auth/otp/verify', data: {
        'phone': phone,
        'code': code,
        'device_id': await _store.deviceId(),
        'device_name': _deviceName(),
      });
      await _store.save(Session.fromTokenResponse(Map<String, dynamic>.from(res.data), fallbackPhone: phone));
    } catch (e) {
      throw ApiException.from(e);
    }
    // A new account on this device always gets a fresh PIN.
    await _pin.clear();
    signOutReason = null;
    _set(AuthStatus.needsPin);
  }

  Future<void> setPin(String pin, {required bool biometrics}) async {
    await _pin.setPin(pin, biometrics: biometrics);
    _set(AuthStatus.unlocked);
  }

  Future<PinCheck> unlockWithPin(String pin) async {
    final result = await _pin.verify(pin);
    if (result == PinCheck.ok) _set(AuthStatus.unlocked);
    if (result == PinCheck.wiped) {
      await _endSession(reason: 'Слишком много неверных попыток. Войдите заново по номеру телефона.');
    }
    return result;
  }

  Future<bool> unlockWithBiometrics() async {
    final ok = await _pin.authenticateWithBiometrics();
    if (ok) _set(AuthStatus.unlocked);
    return ok;
  }

  /// Called when the app returns from background after the idle timeout.
  void lock() {
    if (_status == AuthStatus.unlocked) _set(AuthStatus.locked);
  }

  Future<void> signOut() async {
    final deviceId = await _store.deviceId();
    // Best effort: revoke on the server, but never block local sign-out on it.
    _api.dio.post('/auth/logout', queryParameters: {'device_id': deviceId}).ignore();
    await _endSession();
  }

  Future<void> forgotPin() => _endSession(reason: 'Войдите по номеру телефона, чтобы задать новый PIN.');

  Future<void> _endSession({String? reason}) async {
    await _store.clear();
    await _pin.clear();
    signOutReason = reason;
    _set(AuthStatus.signedOut);
  }

  void _handleSessionExpired() {
    _endSession(reason: 'Сессия истекла. Войдите снова.');
  }

  String _deviceName() {
    if (kIsWeb) return 'Web';
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => 'Android',
      TargetPlatform.iOS => 'iPhone',
      _ => 'Mobile Client',
    };
  }
}
