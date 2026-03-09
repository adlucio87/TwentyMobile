import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  final FlutterSecureStorage _secureStorage;
  final SharedPreferences _fallback;

  StorageService(this._secureStorage, this._fallback);

  Future<void> write({required String key, required String? value}) async {
    if (kDebugMode) print('StorageService: Writing $key -> $value');

    // Always write to SharedPreferences fallback
    if (value != null) {
      await _fallback.setString(key, value);
    } else {
      await _fallback.remove(key);
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

    if (secureValue != null) return secureValue;

    final fallbackValue = _fallback.getString(key);
    if (kDebugMode && fallbackValue != null) {
      print('StorageService: $key read from SharedPreferences fallback');
    }
    return fallbackValue;
  }

  Future<void> delete({required String key}) async {
    try {
      await _secureStorage.delete(key: key);
    } catch (e) {}
    await _fallback.remove(key);
  }

  Future<void> deleteAll() async {
    try {
      await _secureStorage.deleteAll();
    } catch (e) {}
    await _fallback.clear();
  }
}
