import 'dart:convert';
import 'package:hive/hive.dart';
import '../../core/logging/app_logger.dart';

/// Encrypted key-value storage for sensitive data.
///
/// Uses Hive's built-in AES-256 encryption for at-rest security.
/// In production, the encryption key should be stored in the
/// platform keychain (iOS Keychain / Android Keystore).
abstract class SecureStorageService {
  Future<void> write(String key, String value);
  Future<String?> read(String key);
  Future<void> delete(String key);
  Future<void> deleteAll();
  Future<bool> containsKey(String key);
}

class HiveSecureStorage implements SecureStorageService {
  static const String _boxName = 'secure_storage';
  Box<String>? _box;

  // In production, generate and store this key in platform keychain
  final List<int> _encryptionKey;

  HiveSecureStorage({List<int>? encryptionKey})
      : _encryptionKey = encryptionKey ??
            List.generate(32, (i) => i * 7 % 256); // Default dev key

  Future<Box<String>> get _secureBox async {
    if (_box != null && _box!.isOpen) return _box!;
    _box = await Hive.openBox<String>(
      _boxName,
      encryptionCipher: HiveAesCipher(_encryptionKey),
    );
    return _box!;
  }

  @override
  Future<void> write(String key, String value) async {
    final box = await _secureBox;
    // Base64 encode for extra obfuscation layer
    await box.put(key, base64Encode(utf8.encode(value)));
    logger.debug('Secure write: $key', tag: 'Security');
  }

  @override
  Future<String?> read(String key) async {
    final box = await _secureBox;
    final encoded = box.get(key);
    if (encoded == null) return null;
    return utf8.decode(base64Decode(encoded));
  }

  @override
  Future<void> delete(String key) async {
    final box = await _secureBox;
    await box.delete(key);
  }

  @override
  Future<void> deleteAll() async {
    final box = await _secureBox;
    await box.clear();
  }

  @override
  Future<bool> containsKey(String key) async {
    final box = await _secureBox;
    return box.containsKey(key);
  }
}
