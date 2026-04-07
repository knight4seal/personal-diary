import 'dart:math';
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class EncryptionService {
  static const _keyName = 'diary_db_encryption_key';
  final FlutterSecureStorage _storage;

  EncryptionService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  Future<String> getOrCreateKey() async {
    final existing = await _storage.read(key: _keyName);
    if (existing != null) return existing;

    final key = _generateKey();
    await _storage.write(key: _keyName, value: key);
    return key;
  }

  String _generateKey() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    return base64Url.encode(bytes);
  }

  Future<bool> hasKey() async {
    final key = await _storage.read(key: _keyName);
    return key != null;
  }

  Future<void> deleteKey() async {
    await _storage.delete(key: _keyName);
  }
}
