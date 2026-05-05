import 'package:freezed_annotation/freezed_annotation.dart';

part 'workspace_member.freezed.dart';
part 'workspace_member.g.dart';

@freezed
class WorkspaceMember with _$WorkspaceMember {
  factory WorkspaceMember({
    required String id,
    required String firstName,
    required String lastName,
  }) = _WorkspaceMember;

  factory WorkspaceMember.fromJson(Map<String, dynamic> json) => _$WorkspaceMemberFromJson(json);

  factory WorkspaceMember.fromTwenty(Map<String, dynamic> json) {
    String firstName = '';
    String lastName = '';

    final nameObj = json['name'];
    if (nameObj is Map) {
      firstName = nameObj['firstName'] as String? ?? '';
      lastName = nameObj['lastName'] as String? ?? '';
    }

    return WorkspaceMember(
      id: json['id'] as String? ?? '',
      firstName: firstName,
      lastName: lastName,
    );
  }
}
