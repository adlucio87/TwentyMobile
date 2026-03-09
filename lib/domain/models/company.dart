import 'package:freezed_annotation/freezed_annotation.dart';

part 'company.freezed.dart';
part 'company.g.dart';

@freezed
class Company with _$Company {
  factory Company({
    required String id,
    required String name,
    String? industry,
    String? website,
    String? logoUrl,
    int? employeesCount,
    DateTime? createdAt,
  }) = _Company;

  factory Company.fromJson(Map<String, dynamic> json) =>
      _$CompanyFromJson(json);

  factory Company.fromTwenty(Map<String, dynamic> json) => Company(
    id: json['id'],
    name: json['name'] is Map ? json['name']['text'] ?? '' : json['name'] ?? '',
    createdAt: json['createdAt'] != null
        ? DateTime.parse(json['createdAt'])
        : null,
  );
}
