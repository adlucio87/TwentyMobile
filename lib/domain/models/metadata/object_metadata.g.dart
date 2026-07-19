// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'object_metadata.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ObjectMetadataImpl _$$ObjectMetadataImplFromJson(Map<String, dynamic> json) =>
    _$ObjectMetadataImpl(
      id: json['id'] as String,
      nameSingular: json['nameSingular'] as String,
      namePlural: json['namePlural'] as String,
      labelSingular: json['labelSingular'] as String?,
      labelPlural: json['labelPlural'] as String?,
      icon: json['icon'] as String?,
      fields:
          (json['fields'] as List<dynamic>?)
              ?.map((e) => FieldMetadata.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$$ObjectMetadataImplToJson(
  _$ObjectMetadataImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'nameSingular': instance.nameSingular,
  'namePlural': instance.namePlural,
  'labelSingular': instance.labelSingular,
  'labelPlural': instance.labelPlural,
  'icon': instance.icon,
  'fields': instance.fields,
};
