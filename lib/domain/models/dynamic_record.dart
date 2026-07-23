class DynamicRecord {
  final String id;
  final String objectType; // nameSingular of the object
  final Map<String, dynamic> data; // all field values as key-value
  final DateTime? createdAt;
  final DateTime? updatedAt;

  DynamicRecord({required this.id, required this.objectType, required this.data, this.createdAt, this.updatedAt});

  /// Returns a display name by finding the first TEXT-like field value, or the 'name' field
  String get displayName {
    // Try 'name' first (could be a map like { text: ... } or a plain string)
    final nameVal = data['name'];
    if (nameVal is Map) return nameVal['text']?.toString() ?? nameVal.values.firstOrNull?.toString() ?? id;
    if (nameVal is String && nameVal.isNotEmpty) return nameVal;
    // Fallback: first non-null string value
    for (final v in data.values) {
      if (v is String && v.isNotEmpty) return v;
    }
    return id;
  }

  /// Factory to parse from Twenty CRM GraphQL node JSON
  factory DynamicRecord.fromTwenty(String objectType, Map<String, dynamic> json) {
    return DynamicRecord(
      id: json['id'] as String,
      objectType: objectType,
      data: Map<String, dynamic>.from(json)..remove('__typename'),
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt']) : null,
    );
  }
}
