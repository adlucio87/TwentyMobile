// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'company.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$CompanyImpl _$$CompanyImplFromJson(Map<String, dynamic> json) =>
    _$CompanyImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      domainName: json['domainName'] as String?,
      industry: json['industry'] as String?,
      website: json['website'] as String?,
      logoUrl: json['logoUrl'] as String?,
      employeesCount: (json['employeesCount'] as num?)?.toInt(),
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$$CompanyImplToJson(_$CompanyImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'domainName': instance.domainName,
      'industry': instance.industry,
      'website': instance.website,
      'logoUrl': instance.logoUrl,
      'employeesCount': instance.employeesCount,
      'createdAt': instance.createdAt?.toIso8601String(),
    };
