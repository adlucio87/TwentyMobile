// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'country_codes.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$CountryCode {
  String get flag => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get dialCode => throw _privateConstructorUsedError;
  String get isoCode => throw _privateConstructorUsedError;

  /// Create a copy of CountryCode
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CountryCodeCopyWith<CountryCode> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CountryCodeCopyWith<$Res> {
  factory $CountryCodeCopyWith(
    CountryCode value,
    $Res Function(CountryCode) then,
  ) = _$CountryCodeCopyWithImpl<$Res, CountryCode>;
  @useResult
  $Res call({String flag, String name, String dialCode, String isoCode});
}

/// @nodoc
class _$CountryCodeCopyWithImpl<$Res, $Val extends CountryCode>
    implements $CountryCodeCopyWith<$Res> {
  _$CountryCodeCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CountryCode
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? flag = null,
    Object? name = null,
    Object? dialCode = null,
    Object? isoCode = null,
  }) {
    return _then(
      _value.copyWith(
            flag: null == flag
                ? _value.flag
                : flag // ignore: cast_nullable_to_non_nullable
                      as String,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            dialCode: null == dialCode
                ? _value.dialCode
                : dialCode // ignore: cast_nullable_to_non_nullable
                      as String,
            isoCode: null == isoCode
                ? _value.isoCode
                : isoCode // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$CountryCodeImplCopyWith<$Res>
    implements $CountryCodeCopyWith<$Res> {
  factory _$$CountryCodeImplCopyWith(
    _$CountryCodeImpl value,
    $Res Function(_$CountryCodeImpl) then,
  ) = __$$CountryCodeImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String flag, String name, String dialCode, String isoCode});
}

/// @nodoc
class __$$CountryCodeImplCopyWithImpl<$Res>
    extends _$CountryCodeCopyWithImpl<$Res, _$CountryCodeImpl>
    implements _$$CountryCodeImplCopyWith<$Res> {
  __$$CountryCodeImplCopyWithImpl(
    _$CountryCodeImpl _value,
    $Res Function(_$CountryCodeImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of CountryCode
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? flag = null,
    Object? name = null,
    Object? dialCode = null,
    Object? isoCode = null,
  }) {
    return _then(
      _$CountryCodeImpl(
        flag: null == flag
            ? _value.flag
            : flag // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        dialCode: null == dialCode
            ? _value.dialCode
            : dialCode // ignore: cast_nullable_to_non_nullable
                  as String,
        isoCode: null == isoCode
            ? _value.isoCode
            : isoCode // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc

class _$CountryCodeImpl implements _CountryCode {
  const _$CountryCodeImpl({
    required this.flag,
    required this.name,
    required this.dialCode,
    required this.isoCode,
  });

  @override
  final String flag;
  @override
  final String name;
  @override
  final String dialCode;
  @override
  final String isoCode;

  @override
  String toString() {
    return 'CountryCode(flag: $flag, name: $name, dialCode: $dialCode, isoCode: $isoCode)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CountryCodeImpl &&
            (identical(other.flag, flag) || other.flag == flag) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.dialCode, dialCode) ||
                other.dialCode == dialCode) &&
            (identical(other.isoCode, isoCode) || other.isoCode == isoCode));
  }

  @override
  int get hashCode => Object.hash(runtimeType, flag, name, dialCode, isoCode);

  /// Create a copy of CountryCode
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CountryCodeImplCopyWith<_$CountryCodeImpl> get copyWith =>
      __$$CountryCodeImplCopyWithImpl<_$CountryCodeImpl>(this, _$identity);
}

abstract class _CountryCode implements CountryCode {
  const factory _CountryCode({
    required final String flag,
    required final String name,
    required final String dialCode,
    required final String isoCode,
  }) = _$CountryCodeImpl;

  @override
  String get flag;
  @override
  String get name;
  @override
  String get dialCode;
  @override
  String get isoCode;

  /// Create a copy of CountryCode
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CountryCodeImplCopyWith<_$CountryCodeImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
