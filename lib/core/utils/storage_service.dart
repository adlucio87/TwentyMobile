import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';

class StorageService {
  final FlutterSecureStorage _secureStorage;
  final Box<String> _box;
  final Map<String, String> _cache = {};

  static const _sensitiveKeys = {'api_token', 'instance_url'};

  StorageService(this._secureStorage, this._box);

  Future<void> write({required String key, required String? value}) async {
    if (value != null) {
      _cache[key] = value;
    } else {
      _cache.remove(key);
    }

    if (kDebugMode) print('StorageService: Writing $key -> $value');

    final bool isMacOSDebug =
        kDebugMode && defaultTargetPlatform == TargetPlatform.macOS;
    final bool blockPlaintext = _sensitiveKeys.contains(key) && !isMacOSDebug;

    // Scrivi su Hive come fallback (a meno che la chiave non sia sensibile)
    if (!blockPlaintext) {
      if (value != null) {
        await _box.put(key, value);
        if (kDebugMode) print('StorageService: $key written to Hive');
      } else {
        await _box.delete(key);
        if (kDebugMode) print('StorageService: $key removed from Hive');
      }
    } else {
      // Se è una chiave sensibile, assicuriamoci che sia rimossa da Hive (migrazione/pulizia)
      await _box.delete(key);
    }

    try {
      await _secureStorage.write(key: key, value: value);
      if (kDebugMode) print('StorageService: $key written to secure storage');
    } catch (e) {
      if (kDebugMode) {
        if (e.toString().contains('-34018')) {
          print(
            'StorageService: Keychain locked (-34018). Secure storage skipped for "$key".',
          );
        } else {
          print('StorageService: Error writing "$key" to secure storage ($e).');
        }
      }
    }
  }

  Future<String?> read({required String key}) async {
    if (_cache.containsKey(key)) {
      if (kDebugMode) {
        print('StorageService: $key read from in-memory cache');
      }
      return _cache[key];
    }

    String? secureValue;
    try {
      secureValue = await _secureStorage.read(key: key);
      if (kDebugMode && secureValue != null) {
        print('StorageService: $key read from secure storage');
      }
    } catch (e) {
      if (kDebugMode && !e.toString().contains('-34018')) {
        print('StorageService: Error reading "$key" from secure storage ($e).');
      }
    }

    if (secureValue != null) {
      _cache[key] = secureValue;
      return secureValue;
    }

    final bool isMacOSDebug =
        kDebugMode && defaultTargetPlatform == TargetPlatform.macOS;
    final bool blockPlaintext = _sensitiveKeys.contains(key) && !isMacOSDebug;

    // Leggi da Hive come fallback
    final hiveValue = _box.get(key);

    if (blockPlaintext) {
      if (hiveValue != null) {
        // Migrazione: se troviamo un dato sensibile in Hive, lo spostiamo in SecureStorage
        if (kDebugMode) {
          print('StorageService: Migrating sensitive $key from Hive to Secure');
        }
        try {
          await _secureStorage.write(key: key, value: hiveValue);
          await _box.delete(key);
        } catch (e) {
          if (kDebugMode) print('StorageService: Migration error: $e');
        }
        _cache[key] = hiveValue;
        return hiveValue;
      }
      return null;
    }

    if (kDebugMode && hiveValue != null) {
      print('StorageService: $key read from Hive fallback');
    }

    if (hiveValue != null) {
      _cache[key] = hiveValue;
    }

    return hiveValue;
  }

  Future<void> delete({required String key}) async {
    _cache.remove(key);
    try {
      await _secureStorage.delete(key: key);
    } catch (e) {}
    await _box.delete(key);
  }

  Future<void> deleteAll() async {
    _cache.clear();
    try {
      await _secureStorage.deleteAll();
    } catch (e) {}
    await _box.clear();
  }
}
