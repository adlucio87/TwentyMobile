// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'workspace_member.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

WorkspaceMember _$WorkspaceMemberFromJson(Map<String, dynamic> json) {
  return _WorkspaceMember.fromJson(json);
}

/// @nodoc
mixin _$WorkspaceMember {
  String get id => throw _privateConstructorUsedError;
  String get firstName => throw _privateConstructorUsedError;
  String get lastName => throw _privateConstructorUsedError;

  /// Serializes this WorkspaceMember to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of WorkspaceMember
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $WorkspaceMemberCopyWith<WorkspaceMember> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $WorkspaceMemberCopyWith<$Res> {
  factory $WorkspaceMemberCopyWith(
    WorkspaceMember value,
    $Res Function(WorkspaceMember) then,
  ) = _$WorkspaceMemberCopyWithImpl<$Res, WorkspaceMember>;
  @useResult
  $Res call({String id, String firstName, String lastName});
}

/// @nodoc
class _$WorkspaceMemberCopyWithImpl<$Res, $Val extends WorkspaceMember>
    implements $WorkspaceMemberCopyWith<$Res> {
  _$WorkspaceMemberCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of WorkspaceMember
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? firstName = null,
    Object? lastName = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            firstName: null == firstName
                ? _value.firstName
                : firstName // ignore: cast_nullable_to_non_nullable
                      as String,
            lastName: null == lastName
                ? _value.lastName
                : lastName // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$WorkspaceMemberImplCopyWith<$Res>
    implements $WorkspaceMemberCopyWith<$Res> {
  factory _$$WorkspaceMemberImplCopyWith(
    _$WorkspaceMemberImpl value,
    $Res Function(_$WorkspaceMemberImpl) then,
  ) = __$$WorkspaceMemberImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String id, String firstName, String lastName});
}

/// @nodoc
class __$$WorkspaceMemberImplCopyWithImpl<$Res>
    extends _$WorkspaceMemberCopyWithImpl<$Res, _$WorkspaceMemberImpl>
    implements _$$WorkspaceMemberImplCopyWith<$Res> {
  __$$WorkspaceMemberImplCopyWithImpl(
    _$WorkspaceMemberImpl _value,
    $Res Function(_$WorkspaceMemberImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of WorkspaceMember
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? firstName = null,
    Object? lastName = null,
  }) {
    return _then(
      _$WorkspaceMemberImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        firstName: null == firstName
            ? _value.firstName
            : firstName // ignore: cast_nullable_to_non_nullable
                  as String,
        lastName: null == lastName
            ? _value.lastName
            : lastName // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$WorkspaceMemberImpl implements _WorkspaceMember {
  _$WorkspaceMemberImpl({
    required this.id,
    required this.firstName,
    required this.lastName,
  });

  factory _$WorkspaceMemberImpl.fromJson(Map<String, dynamic> json) =>
      _$$WorkspaceMemberImplFromJson(json);

  @override
  final String id;
  @override
  final String firstName;
  @override
  final String lastName;

  @override
  String toString() {
    return 'WorkspaceMember(id: $id, firstName: $firstName, lastName: $lastName)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$WorkspaceMemberImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.firstName, firstName) ||
                other.firstName == firstName) &&
            (identical(other.lastName, lastName) ||
                other.lastName == lastName));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, firstName, lastName);

  /// Create a copy of WorkspaceMember
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$WorkspaceMemberImplCopyWith<_$WorkspaceMemberImpl> get copyWith =>
      __$$WorkspaceMemberImplCopyWithImpl<_$WorkspaceMemberImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$WorkspaceMemberImplToJson(this);
  }
}

abstract class _WorkspaceMember implements WorkspaceMember {
  factory _WorkspaceMember({
    required final String id,
    required final String firstName,
    required final String lastName,
  }) = _$WorkspaceMemberImpl;

  factory _WorkspaceMember.fromJson(Map<String, dynamic> json) =
      _$WorkspaceMemberImpl.fromJson;

  @override
  String get id;
  @override
  String get firstName;
  @override
  String get lastName;

  /// Create a copy of WorkspaceMember
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$WorkspaceMemberImplCopyWith<_$WorkspaceMemberImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
