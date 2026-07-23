import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocketcrm/core/di/providers.dart';
import 'package:pocketcrm/domain/models/dynamic_field_prefs.dart';

class DynamicFieldPrefsNotifier extends StateNotifier<DynamicFieldPrefs> {
  final Ref ref;
  final String objectType;
  
  DynamicFieldPrefsNotifier(this.ref, this.objectType) : super(DynamicFieldPrefs()) {
    _load();
  }

  String get _key => 'custom_fields_prefs_$objectType';

  Future<void> _load() async {
    final storage = ref.read(storageServiceProvider);
    final data = await storage.read(key: _key);
    if (data != null && data.isNotEmpty) {
      try {
        state = DynamicFieldPrefs.fromJsonString(data);
      } catch (_) {}
    }
  }

  Future<void> toggleVisibility(String fieldName) async {
    final hidden = List<String>.from(state.hiddenFields);
    if (hidden.contains(fieldName)) {
      hidden.remove(fieldName);
    } else {
      hidden.add(fieldName);
    }
    state = DynamicFieldPrefs(hiddenFields: hidden, orderedFields: state.orderedFields);
    await _save();
  }

  Future<void> updateOrder(List<String> newOrder) async {
    state = DynamicFieldPrefs(hiddenFields: state.hiddenFields, orderedFields: newOrder);
    await _save();
  }

  Future<void> _save() async {
    final storage = ref.read(storageServiceProvider);
    await storage.write(key: _key, value: state.toJsonString());
  }
}

final dynamicFieldPrefsProvider = StateNotifierProvider.family<DynamicFieldPrefsNotifier, DynamicFieldPrefs, String>(
  (ref, objectType) => DynamicFieldPrefsNotifier(ref, objectType),
);
