import 'package:freezed_annotation/freezed_annotation.dart';

part 'company.freezed.dart';
part 'company.g.dart';

@freezed
class Company with _$Company {
  factory Company({
    required String id,
    required String name,
    String? domainName,
    String? industry,
    String? website,
    String? logoUrl,
    int? employeesCount,
    DateTime? createdAt,
    @Default({}) Map<String, dynamic> customFields,
  }) = _Company;

  factory Company.fromJson(Map<String, dynamic> json) =>
      _$CompanyFromJson(json);

  factory Company.fromTwenty(Map<String, dynamic> json) {
    // domainName è un oggetto Links in Twenty CRM
    String? domainName;
    final dn = json['domainName'];
    if (dn is Map) {
      domainName = dn['primaryLinkUrl'] as String?;
    } else if (dn is String && dn.isNotEmpty) {
      domainName = dn;
    }
    // Rimuovi protocollo (https://) per display
    if (domainName != null && domainName.contains('://')) {
      domainName = Uri.tryParse(domainName)?.host ?? domainName;
    }

    final knownKeys = {
      'id', 'name', 'domainName', 'logoUrl', 'avatarUrl', 'employees', 'industry', 'createdAt', '__typename',
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

    final cleanDomainName = domainName?.isNotEmpty == true ? domainName : null;
    final derivedLogoUrl = cleanDomainName != null ? 'https://twenty-icons.com/$cleanDomainName/128' : null;

    return Company(
      id: json['id'],
      name: json['name'] is Map ? json['name']['text'] ?? '' : json['name'] ?? '',
      domainName: cleanDomainName,
      logoUrl: (json['logoUrl'] ?? json['avatarUrl']) as String? ?? derivedLogoUrl,
      employeesCount: json['employees'] as int?,
      industry: json['industry'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      customFields: customFields,
    );
  }
}
