// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'field_metadata.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

FieldMetadata _$FieldMetadataFromJson(Map<String, dynamic> json) {
  return _FieldMetadata.fromJson(json);
}

/// @nodoc
mixin _$FieldMetadata {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get type => throw _privateConstructorUsedError;
  String? get label => throw _privateConstructorUsedError;
  bool get isActive => throw _privateConstructorUsedError;
  bool get isCustom => throw _privateConstructorUsedError;

  /// Serializes this FieldMetadata to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of FieldMetadata
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $FieldMetadataCopyWith<FieldMetadata> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FieldMetadataCopyWith<$Res> {
  factory $FieldMetadataCopyWith(
    FieldMetadata value,
    $Res Function(FieldMetadata) then,
  ) = _$FieldMetadataCopyWithImpl<$Res, FieldMetadata>;
  @useResult
  $Res call({
    String id,
    String name,
    String type,
    String? label,
    bool isActive,
    bool isCustom,
  });
}

/// @nodoc
class _$FieldMetadataCopyWithImpl<$Res, $Val extends FieldMetadata>
    implements $FieldMetadataCopyWith<$Res> {
  _$FieldMetadataCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of FieldMetadata
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? type = null,
    Object? label = freezed,
    Object? isActive = null,
    Object? isCustom = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            type: null == type
                ? _value.type
                : type // ignore: cast_nullable_to_non_nullable
                      as String,
            label: freezed == label
                ? _value.label
                : label // ignore: cast_nullable_to_non_nullable
                      as String?,
            isActive: null == isActive
                ? _value.isActive
                : isActive // ignore: cast_nullable_to_non_nullable
                      as bool,
            isCustom: null == isCustom
                ? _value.isCustom
                : isCustom // ignore: cast_nullable_to_non_nullable
                      as bool,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$FieldMetadataImplCopyWith<$Res>
    implements $FieldMetadataCopyWith<$Res> {
  factory _$$FieldMetadataImplCopyWith(
    _$FieldMetadataImpl value,
    $Res Function(_$FieldMetadataImpl) then,
  ) = __$$FieldMetadataImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String name,
    String type,
    String? label,
    bool isActive,
    bool isCustom,
  });
}

/// @nodoc
class __$$FieldMetadataImplCopyWithImpl<$Res>
    extends _$FieldMetadataCopyWithImpl<$Res, _$FieldMetadataImpl>
    implements _$$FieldMetadataImplCopyWith<$Res> {
  __$$FieldMetadataImplCopyWithImpl(
    _$FieldMetadataImpl _value,
    $Res Function(_$FieldMetadataImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of FieldMetadata
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? type = null,
    Object? label = freezed,
    Object? isActive = null,
    Object? isCustom = null,
  }) {
    return _then(
      _$FieldMetadataImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        type: null == type
            ? _value.type
            : type // ignore: cast_nullable_to_non_nullable
                  as String,
        label: freezed == label
            ? _value.label
            : label // ignore: cast_nullable_to_non_nullable
                  as String?,
        isActive: null == isActive
            ? _value.isActive
            : isActive // ignore: cast_nullable_to_non_nullable
                  as bool,
        isCustom: null == isCustom
            ? _value.isCustom
            : isCustom // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$FieldMetadataImpl implements _FieldMetadata {
  _$FieldMetadataImpl({
    required this.id,
    required this.name,
    required this.type,
    this.label,
    this.isActive = true,
    this.isCustom = false,
  });

  factory _$FieldMetadataImpl.fromJson(Map<String, dynamic> json) =>
      _$$FieldMetadataImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final String type;
  @override
  final String? label;
  @override
  @JsonKey()
  final bool isActive;
  @override
  @JsonKey()
  final bool isCustom;

  @override
  String toString() {
    return 'FieldMetadata(id: $id, name: $name, type: $type, label: $label, isActive: $isActive, isCustom: $isCustom)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FieldMetadataImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.label, label) || other.label == label) &&
            (identical(other.isActive, isActive) ||
                other.isActive == isActive) &&
            (identical(other.isCustom, isCustom) ||
                other.isCustom == isCustom));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, id, name, type, label, isActive, isCustom);

  /// Create a copy of FieldMetadata
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$FieldMetadataImplCopyWith<_$FieldMetadataImpl> get copyWith =>
      __$$FieldMetadataImplCopyWithImpl<_$FieldMetadataImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$FieldMetadataImplToJson(this);
  }
}

abstract class _FieldMetadata implements FieldMetadata {
  factory _FieldMetadata({
    required final String id,
    required final String name,
    required final String type,
    final String? label,
    final bool isActive,
    final bool isCustom,
  }) = _$FieldMetadataImpl;

  factory _FieldMetadata.fromJson(Map<String, dynamic> json) =
      _$FieldMetadataImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  String get type;
  @override
  String? get label;
  @override
  bool get isActive;
  @override
  bool get isCustom;

  /// Create a copy of FieldMetadata
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$FieldMetadataImplCopyWith<_$FieldMetadataImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
