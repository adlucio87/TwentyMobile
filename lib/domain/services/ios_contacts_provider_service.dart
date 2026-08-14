import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:pocketcrm/domain/models/contact.dart';
import 'package:shared_preferences/shared_preferences.dart';

const iosContactsProviderEnabledPrefKey = 'ios_contacts_provider_enabled';

Map<String, String> contactToIosSnapshot(Contact contact) {
  final map = <String, String>{
    'id': contact.id,
    'givenName': contact.firstName,
    'familyName': contact.lastName,
  };
  final email = contact.email?.trim();
  if (email != null && email.isNotEmpty) {
    map['email'] = email;
  }
  final phone = contact.phone?.trim();
  if (phone != null && phone.isNotEmpty) {
    map['phone'] = phone;
  }
  final organization = contact.companyName?.trim();
  if (organization != null && organization.isNotEmpty) {
    map['organization'] = organization;
  }
  return map;
}

class IosContactsProviderService {
  IosContactsProviderService({MethodChannel? channel})
      : _channel = channel ??
            const MethodChannel('com.luciosoft.pocketcrm/ios_contacts_provider');

  static final IosContactsProviderService instance =
      IosContactsProviderService();

  final MethodChannel _channel;

  static bool get _isIos =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  Future<bool> isSupported() async {
    if (!_isIos) return false;
    try {
      final supported = await _channel.invokeMethod<bool>('isSupported');
      return supported ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> isEnabled() async {
    if (!_isIos) return false;
    try {
      final enabled = await _channel.invokeMethod<bool>('isEnabled');
      return enabled ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> setEnabled(bool enabled) async {
    if (!_isIos) return false;
    final result = await _channel.invokeMethod<bool>(
      'setEnabled',
      {'enabled': enabled},
    );
    return result ?? false;
  }

  Future<void> writeSnapshot(List<Contact> contacts) async {
    if (!_isIos) return;
    await _channel.invokeMethod<void>('writeSnapshot', {
      'contacts': contacts.map(contactToIosSnapshot).toList(),
    });
  }

  Future<void> syncIfEnabled(List<Contact> contacts) async {
    if (!_isIos) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(iosContactsProviderEnabledPrefKey) != true) {
        return;
      }
      await writeSnapshot(contacts);
    } catch (_) {}
  }

  Future<void> disableAndClear() async {
    if (!_isIos) return;
    try {
      await setEnabled(false);
    } catch (_) {}
    try {
      await writeSnapshot(const []);
    } catch (_) {}
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(iosContactsProviderEnabledPrefKey, false);
    } catch (_) {}
  }
}
