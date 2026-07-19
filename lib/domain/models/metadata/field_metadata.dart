import 'package:freezed_annotation/freezed_annotation.dart';

part 'field_metadata.freezed.dart';
part 'field_metadata.g.dart';

@freezed
class FieldMetadata with _$FieldMetadata {
  factory FieldMetadata({
    required String id,
    required String name,
    required String type,
    String? label,
    @Default(true) bool isActive,
  }) = _FieldMetadata;

  factory FieldMetadata.fromJson(Map<String, dynamic> json) =>
      _$FieldMetadataFromJson(json);
}
