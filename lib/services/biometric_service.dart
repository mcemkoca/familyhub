import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

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

  /// Stores a hashed PIN for fallback authentication.
  static Future<void> registerPin(String pin) async {
    final hash = _hashPin(pin);
    await _secureStorage.write(key: _pinHashKey, value: hash);
  }

  static Future<bool> _validatePin(String pin) async {
    final storedHash = await _secureStorage.read(key: _pinHashKey);
    if (storedHash == null || storedHash.isEmpty) return false;
    final inputHash = _hashPin(pin);
    return storedHash == inputHash;
  }

  static String _hashPin(String pin) {
    final bytes = utf8.encode(pin);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}
