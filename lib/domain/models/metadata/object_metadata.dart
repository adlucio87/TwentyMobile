import 'package:freezed_annotation/freezed_annotation.dart';
import 'field_metadata.dart';

part 'object_metadata.freezed.dart';
part 'object_metadata.g.dart';

@freezed
class ObjectMetadata with _$ObjectMetadata {
  factory ObjectMetadata({
    required String id,
    required String nameSingular,
    required String namePlural,
    String? labelSingular,
    String? labelPlural,
    String? icon,
    @Default(false) bool isCustom,
    @Default([]) List<FieldMetadata> fields,
  }) = _ObjectMetadata;

  factory ObjectMetadata.fromJson(Map<String, dynamic> json) =>
      _$ObjectMetadataFromJson(json);
}
