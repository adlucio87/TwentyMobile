// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'object_metadata.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

ObjectMetadata _$ObjectMetadataFromJson(Map<String, dynamic> json) {
  return _ObjectMetadata.fromJson(json);
}

/// @nodoc
mixin _$ObjectMetadata {
  String get id => throw _privateConstructorUsedError;
  String get nameSingular => throw _privateConstructorUsedError;
  String get namePlural => throw _privateConstructorUsedError;
  String? get labelSingular => throw _privateConstructorUsedError;
  String? get labelPlural => throw _privateConstructorUsedError;
  String? get icon => throw _privateConstructorUsedError;
  List<FieldMetadata> get fields => throw _privateConstructorUsedError;

  /// Serializes this ObjectMetadata to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ObjectMetadata
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ObjectMetadataCopyWith<ObjectMetadata> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ObjectMetadataCopyWith<$Res> {
  factory $ObjectMetadataCopyWith(
    ObjectMetadata value,
    $Res Function(ObjectMetadata) then,
  ) = _$ObjectMetadataCopyWithImpl<$Res, ObjectMetadata>;
  @useResult
  $Res call({
    String id,
    String nameSingular,
    String namePlural,
    String? labelSingular,
    String? labelPlural,
    String? icon,
    List<FieldMetadata> fields,
  });
}

/// @nodoc
class _$ObjectMetadataCopyWithImpl<$Res, $Val extends ObjectMetadata>
    implements $ObjectMetadataCopyWith<$Res> {
  _$ObjectMetadataCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ObjectMetadata
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? nameSingular = null,
    Object? namePlural = null,
    Object? labelSingular = freezed,
    Object? labelPlural = freezed,
    Object? icon = freezed,
    Object? fields = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            nameSingular: null == nameSingular
                ? _value.nameSingular
                : nameSingular // ignore: cast_nullable_to_non_nullable
                      as String,
            namePlural: null == namePlural
                ? _value.namePlural
                : namePlural // ignore: cast_nullable_to_non_nullable
                      as String,
            labelSingular: freezed == labelSingular
                ? _value.labelSingular
                : labelSingular // ignore: cast_nullable_to_non_nullable
                      as String?,
            labelPlural: freezed == labelPlural
                ? _value.labelPlural
                : labelPlural // ignore: cast_nullable_to_non_nullable
                      as String?,
            icon: freezed == icon
                ? _value.icon
                : icon // ignore: cast_nullable_to_non_nullable
                      as String?,
            fields: null == fields
                ? _value.fields
                : fields // ignore: cast_nullable_to_non_nullable
                      as List<FieldMetadata>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ObjectMetadataImplCopyWith<$Res>
    implements $ObjectMetadataCopyWith<$Res> {
  factory _$$ObjectMetadataImplCopyWith(
    _$ObjectMetadataImpl value,
    $Res Function(_$ObjectMetadataImpl) then,
  ) = __$$ObjectMetadataImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String nameSingular,
    String namePlural,
    String? labelSingular,
    String? labelPlural,
    String? icon,
    List<FieldMetadata> fields,
  });
}

/// @nodoc
class __$$ObjectMetadataImplCopyWithImpl<$Res>
    extends _$ObjectMetadataCopyWithImpl<$Res, _$ObjectMetadataImpl>
    implements _$$ObjectMetadataImplCopyWith<$Res> {
  __$$ObjectMetadataImplCopyWithImpl(
    _$ObjectMetadataImpl _value,
    $Res Function(_$ObjectMetadataImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ObjectMetadata
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? nameSingular = null,
    Object? namePlural = null,
    Object? labelSingular = freezed,
    Object? labelPlural = freezed,
    Object? icon = freezed,
    Object? fields = null,
  }) {
    return _then(
      _$ObjectMetadataImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        nameSingular: null == nameSingular
            ? _value.nameSingular
            : nameSingular // ignore: cast_nullable_to_non_nullable
                  as String,
        namePlural: null == namePlural
            ? _value.namePlural
            : namePlural // ignore: cast_nullable_to_non_nullable
                  as String,
        labelSingular: freezed == labelSingular
            ? _value.labelSingular
            : labelSingular // ignore: cast_nullable_to_non_nullable
                  as String?,
        labelPlural: freezed == labelPlural
            ? _value.labelPlural
            : labelPlural // ignore: cast_nullable_to_non_nullable
                  as String?,
        icon: freezed == icon
            ? _value.icon
            : icon // ignore: cast_nullable_to_non_nullable
                  as String?,
        fields: null == fields
            ? _value._fields
            : fields // ignore: cast_nullable_to_non_nullable
                  as List<FieldMetadata>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ObjectMetadataImpl implements _ObjectMetadata {
  _$ObjectMetadataImpl({
    required this.id,
    required this.nameSingular,
    required this.namePlural,
    this.labelSingular,
    this.labelPlural,
    this.icon,
    final List<FieldMetadata> fields = const [],
  }) : _fields = fields;

  factory _$ObjectMetadataImpl.fromJson(Map<String, dynamic> json) =>
      _$$ObjectMetadataImplFromJson(json);

  @override
  final String id;
  @override
  final String nameSingular;
  @override
  final String namePlural;
  @override
  final String? labelSingular;
  @override
  final String? labelPlural;
  @override
  final String? icon;
  final List<FieldMetadata> _fields;
  @override
  @JsonKey()
  List<FieldMetadata> get fields {
    if (_fields is EqualUnmodifiableListView) return _fields;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_fields);
  }

  @override
  String toString() {
    return 'ObjectMetadata(id: $id, nameSingular: $nameSingular, namePlural: $namePlural, labelSingular: $labelSingular, labelPlural: $labelPlural, icon: $icon, fields: $fields)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ObjectMetadataImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.nameSingular, nameSingular) ||
                other.nameSingular == nameSingular) &&
            (identical(other.namePlural, namePlural) ||
                other.namePlural == namePlural) &&
            (identical(other.labelSingular, labelSingular) ||
                other.labelSingular == labelSingular) &&
            (identical(other.labelPlural, labelPlural) ||
                other.labelPlural == labelPlural) &&
            (identical(other.icon, icon) || other.icon == icon) &&
            const DeepCollectionEquality().equals(other._fields, _fields));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    nameSingular,
    namePlural,
    labelSingular,
    labelPlural,
    icon,
    const DeepCollectionEquality().hash(_fields),
  );

  /// Create a copy of ObjectMetadata
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ObjectMetadataImplCopyWith<_$ObjectMetadataImpl> get copyWith =>
      __$$ObjectMetadataImplCopyWithImpl<_$ObjectMetadataImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$ObjectMetadataImplToJson(this);
  }
}

abstract class _ObjectMetadata implements ObjectMetadata {
  factory _ObjectMetadata({
    required final String id,
    required final String nameSingular,
    required final String namePlural,
    final String? labelSingular,
    final String? labelPlural,
    final String? icon,
    final List<FieldMetadata> fields,
  }) = _$ObjectMetadataImpl;

  factory _ObjectMetadata.fromJson(Map<String, dynamic> json) =
      _$ObjectMetadataImpl.fromJson;

  @override
  String get id;
  @override
  String get nameSingular;
  @override
  String get namePlural;
  @override
  String? get labelSingular;
  @override
  String? get labelPlural;
  @override
  String? get icon;
  @override
  List<FieldMetadata> get fields;

  /// Create a copy of ObjectMetadata
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ObjectMetadataImplCopyWith<_$ObjectMetadataImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
