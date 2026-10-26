import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'session_store.dart';

enum PinCheck { ok, wrong, lockedOut, wiped }

/// Local app-unlock PIN. Only a salted PBKDF2-HMAC-SHA256 digest is stored, so
/// unlocking works offline and the PIN never leaves the device.
class PinService {
  static final PinService instance = PinService._();
  PinService._();

  static const pinLength = 4;
  static const _iterations = 60000;
  static const _maxAttemptsBeforeWipe = 10;

  static const _kHash = 'pin.hash';
  static const _kSalt = 'pin.salt';
  static const _kAttempts = 'pin.failed_attempts';
  static const _kLockedUntil = 'pin.locked_until';
  static const _kBiometrics = 'pin.biometrics_enabled';

  final SessionStore _store = SessionStore.instance;
  final LocalAuthentication _localAuth = LocalAuthentication();

  Future<bool> hasPin() async => (await _store.read(_kHash)) != null;

  Future<void> setPin(String pin, {required bool biometrics}) async {
    final salt = _randomHex(16);
    final hash = await compute(_derive, _DeriveArgs(pin, salt, _iterations));
    await _store.write(_kSalt, salt);
    await _store.write(_kHash, hash);
    await _store.write(_kBiometrics, biometrics.toString());
    await _resetAttempts();
  }

  /// Time left before another attempt is allowed, or null if not locked.
  Future<Duration?> lockRemaining() async {
    final raw = await _store.read(_kLockedUntil);
    if (raw == null) return null;
    final until = DateTime.tryParse(raw);
    if (until == null) return null;
    final left = until.difference(DateTime.now());
    return left.isNegative ? null : left;
  }

  Future<int> failedAttempts() async => int.tryParse(await _store.read(_kAttempts) ?? '') ?? 0;

  Future<PinCheck> verify(String pin) async {
    if (await lockRemaining() != null) return PinCheck.lockedOut;
    final salt = await _store.read(_kSalt);
    final stored = await _store.read(_kHash);
    if (salt == null || stored == null) return PinCheck.wrong;

    final hash = await compute(_derive, _DeriveArgs(pin, salt, _iterations));
    if (_constantTimeEquals(hash, stored)) {
      await _resetAttempts();
      return PinCheck.ok;
    }

    final attempts = await failedAttempts() + 1;
    await _store.write(_kAttempts, '$attempts');
    if (attempts >= _maxAttemptsBeforeWipe) {
      await clear();
      return PinCheck.wiped;
    }
    // From the 5th wrong try, wait 30s, then 1, 2, 4… minutes.
    if (attempts >= 5) {
      final seconds = 30 * pow(2, attempts - 5).toInt();
      await _store.write(_kLockedUntil, DateTime.now().add(Duration(seconds: seconds)).toIso8601String());
      return PinCheck.lockedOut;
    }
    return PinCheck.wrong;
  }

  Future<bool> biometricsEnabled() async => (await _store.read(_kBiometrics)) == 'true';

  Future<bool> biometricsAvailable() async {
    if (kIsWeb) return false;
    try {
      return await _localAuth.isDeviceSupported() && await _localAuth.canCheckBiometrics;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  Future<bool> authenticateWithBiometrics() async {
    if (!await biometricsAvailable()) return false;
    try {
      final ok = await _localAuth.authenticate(
        localizedReason: 'Подтвердите вход в Aurora Finance',
        options: const AuthenticationOptions(stickyAuth: true, biometricOnly: true),
      );
      if (ok) await _resetAttempts();
      return ok;
    } on PlatformException {
      return false;
    }
  }

  Future<void> clear() async {
    await Future.wait([
      _store.delete(_kHash),
      _store.delete(_kSalt),
      _store.delete(_kBiometrics),
      _resetAttempts(),
    ]);
  }

  Future<void> _resetAttempts() async {
    await _store.delete(_kAttempts);
    await _store.delete(_kLockedUntil);
  }

  static String _randomHex(int bytes) {
    final rnd = Random.secure();
    return List.generate(bytes, (_) => rnd.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
  }

  static bool _constantTimeEquals(String a, String b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return diff == 0;
  }
}

class _DeriveArgs {
  final String pin;
  final String salt;
  final int iterations;
  const _DeriveArgs(this.pin, this.salt, this.iterations);
}

/// PBKDF2-HMAC-SHA256, single 32-byte block. Runs in an isolate via [compute].
String _derive(_DeriveArgs a) {
  final hmac = Hmac(sha256, utf8.encode(a.pin));
  final block = Uint8List.fromList([...utf8.encode(a.salt), 0, 0, 0, 1]);
  var u = hmac.convert(block).bytes;
  final result = Uint8List.fromList(u);
  for (var i = 1; i < a.iterations; i++) {
    u = hmac.convert(u).bytes;
    for (var j = 0; j < result.length; j++) {
      result[j] ^= u[j];
    }
  }
  return result.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
}
