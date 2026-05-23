// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'workflow.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

WorkflowInputField _$WorkflowInputFieldFromJson(Map<String, dynamic> json) {
  return _WorkflowInputField.fromJson(json);
}

/// @nodoc
mixin _$WorkflowInputField {
  String get fieldName => throw _privateConstructorUsedError;
  String get fieldType =>
      throw _privateConstructorUsedError; // TEXT, NUMBER, SELECT, BOOLEAN, etc.
  bool get isRequired => throw _privateConstructorUsedError;
  List<String> get options =>
      throw _privateConstructorUsedError; // for SELECT type
  String? get label => throw _privateConstructorUsedError;

  /// Serializes this WorkflowInputField to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of WorkflowInputField
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $WorkflowInputFieldCopyWith<WorkflowInputField> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $WorkflowInputFieldCopyWith<$Res> {
  factory $WorkflowInputFieldCopyWith(
    WorkflowInputField value,
    $Res Function(WorkflowInputField) then,
  ) = _$WorkflowInputFieldCopyWithImpl<$Res, WorkflowInputField>;
  @useResult
  $Res call({
    String fieldName,
    String fieldType,
    bool isRequired,
    List<String> options,
    String? label,
  });
}

/// @nodoc
class _$WorkflowInputFieldCopyWithImpl<$Res, $Val extends WorkflowInputField>
    implements $WorkflowInputFieldCopyWith<$Res> {
  _$WorkflowInputFieldCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of WorkflowInputField
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? fieldName = null,
    Object? fieldType = null,
    Object? isRequired = null,
    Object? options = null,
    Object? label = freezed,
  }) {
    return _then(
      _value.copyWith(
            fieldName: null == fieldName
                ? _value.fieldName
                : fieldName // ignore: cast_nullable_to_non_nullable
                      as String,
            fieldType: null == fieldType
                ? _value.fieldType
                : fieldType // ignore: cast_nullable_to_non_nullable
                      as String,
            isRequired: null == isRequired
                ? _value.isRequired
                : isRequired // ignore: cast_nullable_to_non_nullable
                      as bool,
            options: null == options
                ? _value.options
                : options // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            label: freezed == label
                ? _value.label
                : label // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$WorkflowInputFieldImplCopyWith<$Res>
    implements $WorkflowInputFieldCopyWith<$Res> {
  factory _$$WorkflowInputFieldImplCopyWith(
    _$WorkflowInputFieldImpl value,
    $Res Function(_$WorkflowInputFieldImpl) then,
  ) = __$$WorkflowInputFieldImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String fieldName,
    String fieldType,
    bool isRequired,
    List<String> options,
    String? label,
  });
}

/// @nodoc
class __$$WorkflowInputFieldImplCopyWithImpl<$Res>
    extends _$WorkflowInputFieldCopyWithImpl<$Res, _$WorkflowInputFieldImpl>
    implements _$$WorkflowInputFieldImplCopyWith<$Res> {
  __$$WorkflowInputFieldImplCopyWithImpl(
    _$WorkflowInputFieldImpl _value,
    $Res Function(_$WorkflowInputFieldImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of WorkflowInputField
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? fieldName = null,
    Object? fieldType = null,
    Object? isRequired = null,
    Object? options = null,
    Object? label = freezed,
  }) {
    return _then(
      _$WorkflowInputFieldImpl(
        fieldName: null == fieldName
            ? _value.fieldName
            : fieldName // ignore: cast_nullable_to_non_nullable
                  as String,
        fieldType: null == fieldType
            ? _value.fieldType
            : fieldType // ignore: cast_nullable_to_non_nullable
                  as String,
        isRequired: null == isRequired
            ? _value.isRequired
            : isRequired // ignore: cast_nullable_to_non_nullable
                  as bool,
        options: null == options
            ? _value._options
            : options // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        label: freezed == label
            ? _value.label
            : label // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$WorkflowInputFieldImpl implements _WorkflowInputField {
  const _$WorkflowInputFieldImpl({
    required this.fieldName,
    required this.fieldType,
    required this.isRequired,
    final List<String> options = const [],
    this.label,
  }) : _options = options;

  factory _$WorkflowInputFieldImpl.fromJson(Map<String, dynamic> json) =>
      _$$WorkflowInputFieldImplFromJson(json);

  @override
  final String fieldName;
  @override
  final String fieldType;
  // TEXT, NUMBER, SELECT, BOOLEAN, etc.
  @override
  final bool isRequired;
  final List<String> _options;
  @override
  @JsonKey()
  List<String> get options {
    if (_options is EqualUnmodifiableListView) return _options;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_options);
  }

  // for SELECT type
  @override
  final String? label;

  @override
  String toString() {
    return 'WorkflowInputField(fieldName: $fieldName, fieldType: $fieldType, isRequired: $isRequired, options: $options, label: $label)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$WorkflowInputFieldImpl &&
            (identical(other.fieldName, fieldName) ||
                other.fieldName == fieldName) &&
            (identical(other.fieldType, fieldType) ||
                other.fieldType == fieldType) &&
            (identical(other.isRequired, isRequired) ||
                other.isRequired == isRequired) &&
            const DeepCollectionEquality().equals(other._options, _options) &&
            (identical(other.label, label) || other.label == label));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    fieldName,
    fieldType,
    isRequired,
    const DeepCollectionEquality().hash(_options),
    label,
  );

  /// Create a copy of WorkflowInputField
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$WorkflowInputFieldImplCopyWith<_$WorkflowInputFieldImpl> get copyWith =>
      __$$WorkflowInputFieldImplCopyWithImpl<_$WorkflowInputFieldImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$WorkflowInputFieldImplToJson(this);
  }
}

abstract class _WorkflowInputField implements WorkflowInputField {
  const factory _WorkflowInputField({
    required final String fieldName,
    required final String fieldType,
    required final bool isRequired,
    final List<String> options,
    final String? label,
  }) = _$WorkflowInputFieldImpl;

  factory _WorkflowInputField.fromJson(Map<String, dynamic> json) =
      _$WorkflowInputFieldImpl.fromJson;

  @override
  String get fieldName;
  @override
  String get fieldType; // TEXT, NUMBER, SELECT, BOOLEAN, etc.
  @override
  bool get isRequired;
  @override
  List<String> get options; // for SELECT type
  @override
  String? get label;

  /// Create a copy of WorkflowInputField
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$WorkflowInputFieldImplCopyWith<_$WorkflowInputFieldImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

Workflow _$WorkflowFromJson(Map<String, dynamic> json) {
  return _Workflow.fromJson(json);
}

/// @nodoc
mixin _$Workflow {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;
  String? get versionId => throw _privateConstructorUsedError;
  List<WorkflowInputField> get inputSchema =>
      throw _privateConstructorUsedError;
  bool get hasFormStep => throw _privateConstructorUsedError;

  /// Serializes this Workflow to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Workflow
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $WorkflowCopyWith<Workflow> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $WorkflowCopyWith<$Res> {
  factory $WorkflowCopyWith(Workflow value, $Res Function(Workflow) then) =
      _$WorkflowCopyWithImpl<$Res, Workflow>;
  @useResult
  $Res call({
    String id,
    String name,
    String? description,
    String? versionId,
    List<WorkflowInputField> inputSchema,
    bool hasFormStep,
  });
}

/// @nodoc
class _$WorkflowCopyWithImpl<$Res, $Val extends Workflow>
    implements $WorkflowCopyWith<$Res> {
  _$WorkflowCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Workflow
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? description = freezed,
    Object? versionId = freezed,
    Object? inputSchema = null,
    Object? hasFormStep = null,
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
            description: freezed == description
                ? _value.description
                : description // ignore: cast_nullable_to_non_nullable
                      as String?,
            versionId: freezed == versionId
                ? _value.versionId
                : versionId // ignore: cast_nullable_to_non_nullable
                      as String?,
            inputSchema: null == inputSchema
                ? _value.inputSchema
                : inputSchema // ignore: cast_nullable_to_non_nullable
                      as List<WorkflowInputField>,
            hasFormStep: null == hasFormStep
                ? _value.hasFormStep
                : hasFormStep // ignore: cast_nullable_to_non_nullable
                      as bool,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$WorkflowImplCopyWith<$Res>
    implements $WorkflowCopyWith<$Res> {
  factory _$$WorkflowImplCopyWith(
    _$WorkflowImpl value,
    $Res Function(_$WorkflowImpl) then,
  ) = __$$WorkflowImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String name,
    String? description,
    String? versionId,
    List<WorkflowInputField> inputSchema,
    bool hasFormStep,
  });
}

/// @nodoc
class __$$WorkflowImplCopyWithImpl<$Res>
    extends _$WorkflowCopyWithImpl<$Res, _$WorkflowImpl>
    implements _$$WorkflowImplCopyWith<$Res> {
  __$$WorkflowImplCopyWithImpl(
    _$WorkflowImpl _value,
    $Res Function(_$WorkflowImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Workflow
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? description = freezed,
    Object? versionId = freezed,
    Object? inputSchema = null,
    Object? hasFormStep = null,
  }) {
    return _then(
      _$WorkflowImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        description: freezed == description
            ? _value.description
            : description // ignore: cast_nullable_to_non_nullable
                  as String?,
        versionId: freezed == versionId
            ? _value.versionId
            : versionId // ignore: cast_nullable_to_non_nullable
                  as String?,
        inputSchema: null == inputSchema
            ? _value._inputSchema
            : inputSchema // ignore: cast_nullable_to_non_nullable
                  as List<WorkflowInputField>,
        hasFormStep: null == hasFormStep
            ? _value.hasFormStep
            : hasFormStep // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$WorkflowImpl implements _Workflow {
  const _$WorkflowImpl({
    required this.id,
    required this.name,
    this.description,
    this.versionId,
    final List<WorkflowInputField> inputSchema = const [],
    this.hasFormStep = false,
  }) : _inputSchema = inputSchema;

  factory _$WorkflowImpl.fromJson(Map<String, dynamic> json) =>
      _$$WorkflowImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final String? description;
  @override
  final String? versionId;
  final List<WorkflowInputField> _inputSchema;
  @override
  @JsonKey()
  List<WorkflowInputField> get inputSchema {
    if (_inputSchema is EqualUnmodifiableListView) return _inputSchema;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_inputSchema);
  }

  @override
  @JsonKey()
  final bool hasFormStep;

  @override
  String toString() {
    return 'Workflow(id: $id, name: $name, description: $description, versionId: $versionId, inputSchema: $inputSchema, hasFormStep: $hasFormStep)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$WorkflowImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.versionId, versionId) ||
                other.versionId == versionId) &&
            const DeepCollectionEquality().equals(
              other._inputSchema,
              _inputSchema,
            ) &&
            (identical(other.hasFormStep, hasFormStep) ||
                other.hasFormStep == hasFormStep));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    name,
    description,
    versionId,
    const DeepCollectionEquality().hash(_inputSchema),
    hasFormStep,
  );

  /// Create a copy of Workflow
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$WorkflowImplCopyWith<_$WorkflowImpl> get copyWith =>
      __$$WorkflowImplCopyWithImpl<_$WorkflowImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$WorkflowImplToJson(this);
  }
}

abstract class _Workflow implements Workflow {
  const factory _Workflow({
    required final String id,
    required final String name,
    final String? description,
    final String? versionId,
    final List<WorkflowInputField> inputSchema,
    final bool hasFormStep,
  }) = _$WorkflowImpl;

  factory _Workflow.fromJson(Map<String, dynamic> json) =
      _$WorkflowImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  String? get description;
  @override
  String? get versionId;
  @override
  List<WorkflowInputField> get inputSchema;
  @override
  bool get hasFormStep;

  /// Create a copy of Workflow
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$WorkflowImplCopyWith<_$WorkflowImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
