// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'voice_note_provider.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$VoiceNoteState {
  VoiceNoteStatus get status => throw _privateConstructorUsedError;
  String get transcribedText => throw _privateConstructorUsedError;
  int get recordingSeconds => throw _privateConstructorUsedError;
  String? get errorMessage => throw _privateConstructorUsedError;

  /// Create a copy of VoiceNoteState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $VoiceNoteStateCopyWith<VoiceNoteState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $VoiceNoteStateCopyWith<$Res> {
  factory $VoiceNoteStateCopyWith(
    VoiceNoteState value,
    $Res Function(VoiceNoteState) then,
  ) = _$VoiceNoteStateCopyWithImpl<$Res, VoiceNoteState>;
  @useResult
  $Res call({
    VoiceNoteStatus status,
    String transcribedText,
    int recordingSeconds,
    String? errorMessage,
  });
}

/// @nodoc
class _$VoiceNoteStateCopyWithImpl<$Res, $Val extends VoiceNoteState>
    implements $VoiceNoteStateCopyWith<$Res> {
  _$VoiceNoteStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of VoiceNoteState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? status = null,
    Object? transcribedText = null,
    Object? recordingSeconds = null,
    Object? errorMessage = freezed,
  }) {
    return _then(
      _value.copyWith(
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as VoiceNoteStatus,
            transcribedText: null == transcribedText
                ? _value.transcribedText
                : transcribedText // ignore: cast_nullable_to_non_nullable
                      as String,
            recordingSeconds: null == recordingSeconds
                ? _value.recordingSeconds
                : recordingSeconds // ignore: cast_nullable_to_non_nullable
                      as int,
            errorMessage: freezed == errorMessage
                ? _value.errorMessage
                : errorMessage // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$VoiceNoteStateImplCopyWith<$Res>
    implements $VoiceNoteStateCopyWith<$Res> {
  factory _$$VoiceNoteStateImplCopyWith(
    _$VoiceNoteStateImpl value,
    $Res Function(_$VoiceNoteStateImpl) then,
  ) = __$$VoiceNoteStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    VoiceNoteStatus status,
    String transcribedText,
    int recordingSeconds,
    String? errorMessage,
  });
}

/// @nodoc
class __$$VoiceNoteStateImplCopyWithImpl<$Res>
    extends _$VoiceNoteStateCopyWithImpl<$Res, _$VoiceNoteStateImpl>
    implements _$$VoiceNoteStateImplCopyWith<$Res> {
  __$$VoiceNoteStateImplCopyWithImpl(
    _$VoiceNoteStateImpl _value,
    $Res Function(_$VoiceNoteStateImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of VoiceNoteState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? status = null,
    Object? transcribedText = null,
    Object? recordingSeconds = null,
    Object? errorMessage = freezed,
  }) {
    return _then(
      _$VoiceNoteStateImpl(
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as VoiceNoteStatus,
        transcribedText: null == transcribedText
            ? _value.transcribedText
            : transcribedText // ignore: cast_nullable_to_non_nullable
                  as String,
        recordingSeconds: null == recordingSeconds
            ? _value.recordingSeconds
            : recordingSeconds // ignore: cast_nullable_to_non_nullable
                  as int,
        errorMessage: freezed == errorMessage
            ? _value.errorMessage
            : errorMessage // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc

class _$VoiceNoteStateImpl implements _VoiceNoteState {
  _$VoiceNoteStateImpl({
    this.status = VoiceNoteStatus.idle,
    this.transcribedText = '',
    this.recordingSeconds = 0,
    this.errorMessage,
  });

  @override
  @JsonKey()
  final VoiceNoteStatus status;
  @override
  @JsonKey()
  final String transcribedText;
  @override
  @JsonKey()
  final int recordingSeconds;
  @override
  final String? errorMessage;

  @override
  String toString() {
    return 'VoiceNoteState(status: $status, transcribedText: $transcribedText, recordingSeconds: $recordingSeconds, errorMessage: $errorMessage)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$VoiceNoteStateImpl &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.transcribedText, transcribedText) ||
                other.transcribedText == transcribedText) &&
            (identical(other.recordingSeconds, recordingSeconds) ||
                other.recordingSeconds == recordingSeconds) &&
            (identical(other.errorMessage, errorMessage) ||
                other.errorMessage == errorMessage));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    status,
    transcribedText,
    recordingSeconds,
    errorMessage,
  );

  /// Create a copy of VoiceNoteState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$VoiceNoteStateImplCopyWith<_$VoiceNoteStateImpl> get copyWith =>
      __$$VoiceNoteStateImplCopyWithImpl<_$VoiceNoteStateImpl>(
        this,
        _$identity,
      );
}

abstract class _VoiceNoteState implements VoiceNoteState {
  factory _VoiceNoteState({
    final VoiceNoteStatus status,
    final String transcribedText,
    final int recordingSeconds,
    final String? errorMessage,
  }) = _$VoiceNoteStateImpl;

  @override
  VoiceNoteStatus get status;
  @override
  String get transcribedText;
  @override
  int get recordingSeconds;
  @override
  String? get errorMessage;

  /// Create a copy of VoiceNoteState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$VoiceNoteStateImplCopyWith<_$VoiceNoteStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
