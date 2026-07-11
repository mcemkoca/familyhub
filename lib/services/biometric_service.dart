import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import '../features/security/domain/pin_hasher.dart';

class BiometricService {
  static final LocalAuthentication _localAuth = LocalAuthentication();
  static const _secureStorage = FlutterSecureStorage();
  static const _pinHashKey = 'biometric_fallback_pin_hash';

  static Future<bool> isAvailable() async {
    try {
      final available = await _localAuth.canCheckBiometrics;
      final enrolled = await _localAuth.isDeviceSupported();
      return available && enrolled;
    } on PlatformException catch (_) {
      return false;
    }
  }

  static Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } on PlatformException catch (_) {
      return [];
    }
  }

  static Future<bool> authenticate({String reason = 'FamilyHub\'a giriş için biyometrik doğrulama'}) async {
    try {
      return await _localAuth.authenticate(
        localizedReason: reason,
        biometricOnly: false,
        sensitiveTransaction: true,
        persistAcrossBackgrounding: true,
      );
    } on PlatformException catch (_) {
      return false;
    }
  }

  static Future<bool> authenticateWithFallback(String fallbackPin) async {
    final bioSuccess = await authenticate();
    if (bioSuccess) return true;
    return await _validatePin(fallbackPin);
  }

  /// Fallback PIN'i salt'lı + iterasyonlu olarak güvenli depoya yazar.
  static Future<void> registerPin(String pin) async {
    await _secureStorage.write(key: _pinHashKey, value: PinHasher.hash(pin));
  }

  /// Kayıtlı bir fallback PIN var mı?
  static Future<bool> hasPin() async {
    final stored = await _secureStorage.read(key: _pinHashKey);
    return stored != null && stored.isNotEmpty;
  }

  /// Kayıtlı PIN'i siler.
  static Future<void> clearPin() async {
    await _secureStorage.delete(key: _pinHashKey);
  }

  static Future<bool> _validatePin(String pin) async {
    final storedHash = await _secureStorage.read(key: _pinHashKey);
    if (storedHash == null || storedHash.isEmpty) return false;
    final ok = PinHasher.verify(pin, storedHash);
    // Eski saltsız kayıt doğru PIN ile açıldıysa yeni formata yükselt.
    if (ok && PinHasher.isLegacyFormat(storedHash)) {
      await _secureStorage.write(key: _pinHashKey, value: PinHasher.hash(pin));
    }
    return ok;
  }
}
