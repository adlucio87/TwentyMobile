import 'package:freezed_annotation/freezed_annotation.dart';

part 'contact.freezed.dart';
part 'contact.g.dart';

@freezed
class Contact with _$Contact {
  factory Contact({
    required String id,
    required String firstName,
    required String lastName,
    String? email,
    String? phone,
    String? avatarUrl,
    String? companyId,
    String? companyName,
    DateTime? createdAt,
    DateTime? updatedAt,
    @Default({}) Map<String, dynamic> customFields,
  }) = _Contact;

  factory Contact.fromJson(Map<String, dynamic> json) =>
      _$ContactFromJson(json);

  factory Contact.fromTwenty(Map<String, dynamic> json) {
    final companyData = json['company'];
    String? companyName;
    if (companyData != null) {
      final nameVal = companyData['name'];
      companyName = nameVal is Map ? nameVal['text'] : nameVal;
    }

    final rawAvatar = json['avatarUrl'];
    final avatarUrl = (rawAvatar is String && rawAvatar.startsWith('http'))
        ? rawAvatar
        : null;
    final phones = json['phones'];
    String? parsedPhone;
    if (phones != null) {
      final callingCode = phones['primaryPhoneCallingCode'] ?? '';
      final number = phones['primaryPhoneNumber'] ?? '';
      if (callingCode.isNotEmpty || number.isNotEmpty) {
        parsedPhone = '$callingCode$number';
      }
    }

    final knownKeys = {
      'id', 'name', 'emails', 'phones', 'avatarUrl', 'company', 'createdAt', 'updatedAt', '__typename',
      'searchVector', 'position', 'SearchVector', 'Position'
    };

    final customFields = <String, dynamic>{};
    json.forEach((key, value) {
      final safeKey = key.trim().toLowerCase();
      final isKnown = knownKeys.any((k) => k.toLowerCase() == safeKey);
      if (!isKnown) {
        customFields[key] = value;
      }
    });

    return Contact(
      id: json['id'],
      firstName: json['name']?['firstName'] ?? '',
      lastName: json['name']?['lastName'] ?? '',
      email: json['emails']?['primaryEmail'],
      phone: parsedPhone,
      avatarUrl: avatarUrl,
      companyName: companyName,
      companyId: companyData?['id'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      customFields: customFields,
    );
  }
}
