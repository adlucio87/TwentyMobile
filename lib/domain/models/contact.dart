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
    final avatarUrl = rawAvatar is String ? rawAvatar : null;

    return Contact(
      id: json['id'],
      firstName: json['name']?['firstName'] ?? '',
      lastName: json['name']?['lastName'] ?? '',
      email: json['emails']?['primaryEmail'],
      phone: json['phones']?['primaryPhoneNumber'],
      avatarUrl: avatarUrl,
      companyName: companyName,
      companyId: companyData?['id'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
    );
  }
}
