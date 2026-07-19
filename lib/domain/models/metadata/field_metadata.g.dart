// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'field_metadata.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$FieldMetadataImpl _$$FieldMetadataImplFromJson(Map<String, dynamic> json) =>
    _$FieldMetadataImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      label: json['label'] as String?,
      isActive: json['isActive'] as bool? ?? true,
    );

Map<String, dynamic> _$$FieldMetadataImplToJson(_$FieldMetadataImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'type': instance.type,
      'label': instance.label,
      'isActive': instance.isActive,
    };
