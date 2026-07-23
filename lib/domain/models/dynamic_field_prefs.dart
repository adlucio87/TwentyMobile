import 'dart:convert';

class DynamicFieldPrefs {
  final List<String> hiddenFields;
  final List<String> orderedFields;

  DynamicFieldPrefs({
    this.hiddenFields = const [],
    this.orderedFields = const [],
  });

  Map<String, dynamic> toJson() => {
    'hiddenFields': hiddenFields,
    'orderedFields': orderedFields,
  };

  factory DynamicFieldPrefs.fromJson(Map<String, dynamic> json) => DynamicFieldPrefs(
    hiddenFields: List<String>.from(json['hiddenFields'] ?? []),
    orderedFields: List<String>.from(json['orderedFields'] ?? []),
  );
  
  String toJsonString() => jsonEncode(toJson());
  
  factory DynamicFieldPrefs.fromJsonString(String str) => DynamicFieldPrefs.fromJson(jsonDecode(str));
}
