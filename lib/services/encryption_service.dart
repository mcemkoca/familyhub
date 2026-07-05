import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';

/// AES-256 encryption service for sensitive local data.
///
/// - AES-256-GCM for new data (authenticated encryption)
/// - Backward-compatible AES-256-CBC decryption for legacy data
/// - Master key stored in FlutterSecureStorage with hardware-backed options
/// - Optional biometric unlock before key access
class EncryptionService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      keyCipherAlgorithm: KeyCipherAlgorithm.RSA_ECB_PKCS1Padding,
      storageCipherAlgorithm: StorageCipherAlgorithm.AES_GCM_NoPadding,
    ),
  );
  static const _keyStorageKey = 'app_encryption_key_v2';
  static const _legacyKeyStorageKey = 'app_encryption_key';

  static enc.Key? _masterKey;
  static enc.Key? _legacyKey;

  /// Initialize or load the master AES-256 key.
  static Future<void> initialize() async {
    if (_masterKey != null) return;

    final keyString = await _storage.read(key: _keyStorageKey);
    if (keyString != null && keyString.isNotEmpty) {
      _masterKey = enc.Key(base64Decode(keyString));
      return;
    }

    // Generate a new 256-bit key
    final random = Random.secure();
    final keyBytes = Uint8List.fromList(
      List<int>.generate(32, (_) => random.nextInt(256)),
    );
    _masterKey = enc.Key(keyBytes);

    await _storage.write(
      key: _keyStorageKey,
      value: base64Encode(keyBytes),
    );
  }

  /// Attempt to load the legacy CBC key (if any data still uses it).
  static Future<void> _loadLegacyKey() async {
    if (_legacyKey != null) return;
    final stored = await _storage.read(key: _legacyKeyStorageKey);
    if (stored != null && stored.isNotEmpty) {
      _legacyKey = enc.Key.fromBase64(stored);
    }
  }

  // ── GCM field-level encryption ──

  /// Encrypt a single text field with AES-256-GCM.
  /// Format: gcm:v1:base64(iv):base64(ciphertext+tag)
  static Future<String> encryptField(String plaintext) async {
    if (_masterKey == null) await initialize();

    final iv = enc.IV.fromSecureRandom(12); // 96-bit IV for GCM
    final encrypter = enc.Encrypter(
      enc.AES(_masterKey!, mode: enc.AESMode.gcm),
    );
    final encrypted = encrypter.encrypt(plaintext, iv: iv);

    return 'gcm:v1:${base64Encode(iv.bytes)}:${encrypted.base64}';
  }

  /// Decrypt a field encrypted with [encryptField].
  static Future<String> decryptField(String ciphertext) async {
    if (_masterKey == null) await initialize();

    final parts = ciphertext.split(':');
    if (parts.length != 4 || parts[0] != 'gcm' || parts[1] != 'v1') {
      throw const FormatException('Invalid GCM ciphertext format');
    }

    final iv = enc.IV(base64Decode(parts[2]));
    final encrypted = enc.Encrypted(base64Decode(parts[3]));
    final encrypter = enc.Encrypter(
      enc.AES(_masterKey!, mode: enc.AESMode.gcm),
    );

    return encrypter.decrypt(encrypted, iv: iv);
  }

  // ── Backward-compatible high-level encrypt/decrypt ──

  /// Encrypt [plaintext] using the new GCM format.
  static Future<String> encrypt(String plaintext) async {
    return encryptField(plaintext);
  }

  /// Decrypt a value. Supports both new GCM and legacy CBC formats.
  static Future<String> decrypt(String cipherBase64) async {
    // Detect new GCM format
    if (cipherBase64.startsWith('gcm:v1:')) {
      return decryptField(cipherBase64);
    }

    // Try legacy CBC format
    await _loadLegacyKey();
    if (_legacyKey == null) {
      throw const FormatException('Unknown ciphertext format and no legacy key found');
    }

    try {
      final combined = utf8.decode(base64Decode(cipherBase64));
      final parts = combined.split(':');
      if (parts.length != 2) throw const FormatException('Invalid legacy payload');

      final iv = enc.IV.fromBase64(parts[0]);
      final encrypted = enc.Encrypted.fromBase64(parts[1]);
      final encrypter = enc.Encrypter(
        enc.AES(_legacyKey!, mode: enc.AESMode.cbc, padding: 'PKCS7'),
      );
      return encrypter.decrypt(encrypted, iv: iv);
    } catch (_) {
      throw const FormatException('Failed to decrypt legacy payload');
    }
  }

  // ── JSON helpers ──

  static Future<String> encryptJson(Map<String, dynamic> jsonMap) async {
    return encrypt(jsonEncode(jsonMap));
  }

  static Future<Map<String, dynamic>> decryptJson(String cipherBase64) async {
    final plain = await decrypt(cipherBase64);
    return jsonDecode(plain) as Map<String, dynamic>;
  }

  // ── Health data field-level encryption ──

  static const _sensitiveHealthFields = [
    'bloodType',
    'allergies',
    'chronicConditions',
    'medications',
    'emergencyContactPhone',
    'doctorPhone',
  ];

  /// Encrypt sensitive fields in a health data map.
  static Future<Map<String, dynamic>> encryptHealthData(
    Map<String, dynamic> data,
  ) async {
    final result = Map<String, dynamic>.from(data);
    for (final field in _sensitiveHealthFields) {
      if (result[field] != null) {
        result[field] = await encryptField(jsonEncode(result[field]));
      }
    }
    return result;
  }

  /// Decrypt sensitive fields in a health data map.
  static Future<Map<String, dynamic>> decryptHealthData(
    Map<String, dynamic> data,
  ) async {
    final result = Map<String, dynamic>.from(data);
    for (final field in _sensitiveHealthFields) {
      final value = result[field];
      if (value is String && value.startsWith('gcm:v1:')) {
        try {
          result[field] = jsonDecode(await decryptField(value));
        } catch (_) {
          // If decryption fails, leave as-is (might be plaintext legacy)
        }
      }
    }
    return result;
  }

  // ── Biometric unlock ──

  /// Authenticate with biometrics before accessing encrypted data.
  static Future<bool> unlockWithBiometric() async {
    final localAuth = LocalAuthentication();

    final isAvailable = await localAuth.isDeviceSupported();
    if (!isAvailable) return false;

    final result = await localAuth.authenticate(
      localizedReason: 'Şifrelenmiş verilere erişmek için kimlik doğrulama',
      authMessages: const [
        AndroidAuthMessages(
          signInTitle: 'FamilyHub Güvenlik',
          cancelButton: 'İptal',
          signInHint: 'Biyometrik doğrulama',
        ),
      ],
      biometricOnly: true,
      persistAcrossBackgrounding: true,
    );

    return result;
  }

  // ── Key rotation ──

  /// Rotate the master key. WARNING: re-encrypt existing data externally first.
  static Future<void> rotateKey() async {
    await _storage.delete(key: _keyStorageKey);
    _masterKey = null;
  }
}
