// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workflow.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$WorkflowInputFieldImpl _$$WorkflowInputFieldImplFromJson(
  Map<String, dynamic> json,
) => _$WorkflowInputFieldImpl(
  fieldName: json['fieldName'] as String,
  fieldType: json['fieldType'] as String,
  isRequired: json['isRequired'] as bool,
  options:
      (json['options'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  label: json['label'] as String?,
);

Map<String, dynamic> _$$WorkflowInputFieldImplToJson(
  _$WorkflowInputFieldImpl instance,
) => <String, dynamic>{
  'fieldName': instance.fieldName,
  'fieldType': instance.fieldType,
  'isRequired': instance.isRequired,
  'options': instance.options,
  'label': instance.label,
};

_$WorkflowImpl _$$WorkflowImplFromJson(Map<String, dynamic> json) =>
    _$WorkflowImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      versionId: json['versionId'] as String?,
      inputSchema:
          (json['inputSchema'] as List<dynamic>?)
              ?.map(
                (e) => WorkflowInputField.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          const [],
      hasFormStep: json['hasFormStep'] as bool? ?? false,
    );

Map<String, dynamic> _$$WorkflowImplToJson(_$WorkflowImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'versionId': instance.versionId,
      'inputSchema': instance.inputSchema,
      'hasFormStep': instance.hasFormStep,
    };
