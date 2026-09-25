// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dynamic_object_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$availableCustomObjectsHash() =>
    r'3b3e1803aeecbd4bf55adbac2d32279810403ec7';

/// Provider for the list of custom objects available in the workspace
///
/// Copied from [availableCustomObjects].
@ProviderFor(availableCustomObjects)
final availableCustomObjectsProvider =
    AutoDisposeFutureProvider<List<ObjectMetadata>>.internal(
      availableCustomObjects,
      name: r'availableCustomObjectsProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$availableCustomObjectsHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AvailableCustomObjectsRef =
    AutoDisposeFutureProviderRef<List<ObjectMetadata>>;
String _$dynamicObjectConnectorHash() =>
    r'eef17eccbeda50e1559895435d66998af3b7224d';

/// Provider for the DynamicObjectConnector
///
/// Copied from [dynamicObjectConnector].
@ProviderFor(dynamicObjectConnector)
final dynamicObjectConnectorProvider =
    AutoDisposeFutureProvider<DynamicObjectConnector>.internal(
      dynamicObjectConnector,
      name: r'dynamicObjectConnectorProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$dynamicObjectConnectorHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef DynamicObjectConnectorRef =
    AutoDisposeFutureProviderRef<DynamicObjectConnector>;
String _$dynamicRecordDetailHash() =>
    r'fc05ec314a45e61fc64373e563152851c9cec56e';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// Provider for a single dynamic record detail
///
/// Copied from [dynamicRecordDetail].
@ProviderFor(dynamicRecordDetail)
const dynamicRecordDetailProvider = DynamicRecordDetailFamily();

/// Provider for a single dynamic record detail
///
/// Copied from [dynamicRecordDetail].
class DynamicRecordDetailFamily extends Family<AsyncValue<DynamicRecord>> {
  /// Provider for a single dynamic record detail
  ///
  /// Copied from [dynamicRecordDetail].
  const DynamicRecordDetailFamily();

  /// Provider for a single dynamic record detail
  ///
  /// Copied from [dynamicRecordDetail].
  DynamicRecordDetailProvider call({
    required String objectType,
    required String id,
  }) {
    return DynamicRecordDetailProvider(objectType: objectType, id: id);
  }

  @override
  DynamicRecordDetailProvider getProviderOverride(
    covariant DynamicRecordDetailProvider provider,
  ) {
    return call(objectType: provider.objectType, id: provider.id);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'dynamicRecordDetailProvider';
}

/// Provider for a single dynamic record detail
///
/// Copied from [dynamicRecordDetail].
class DynamicRecordDetailProvider
    extends AutoDisposeFutureProvider<DynamicRecord> {
  /// Provider for a single dynamic record detail
  ///
  /// Copied from [dynamicRecordDetail].
  DynamicRecordDetailProvider({required String objectType, required String id})
    : this._internal(
        (ref) => dynamicRecordDetail(
          ref as DynamicRecordDetailRef,
          objectType: objectType,
          id: id,
        ),
        from: dynamicRecordDetailProvider,
        name: r'dynamicRecordDetailProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$dynamicRecordDetailHash,
        dependencies: DynamicRecordDetailFamily._dependencies,
        allTransitiveDependencies:
            DynamicRecordDetailFamily._allTransitiveDependencies,
        objectType: objectType,
        id: id,
      );

  DynamicRecordDetailProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.objectType,
    required this.id,
  }) : super.internal();

  final String objectType;
  final String id;

  @override
  Override overrideWith(
    FutureOr<DynamicRecord> Function(DynamicRecordDetailRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: DynamicRecordDetailProvider._internal(
        (ref) => create(ref as DynamicRecordDetailRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        objectType: objectType,
        id: id,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<DynamicRecord> createElement() {
    return _DynamicRecordDetailProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is DynamicRecordDetailProvider &&
        other.objectType == objectType &&
        other.id == id;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, objectType.hashCode);
    hash = _SystemHash.combine(hash, id.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin DynamicRecordDetailRef on AutoDisposeFutureProviderRef<DynamicRecord> {
  /// The parameter `objectType` of this provider.
  String get objectType;

  /// The parameter `id` of this provider.
  String get id;
}

class _DynamicRecordDetailProviderElement
    extends AutoDisposeFutureProviderElement<DynamicRecord>
    with DynamicRecordDetailRef {
  _DynamicRecordDetailProviderElement(super.provider);

  @override
  String get objectType => (origin as DynamicRecordDetailProvider).objectType;
  @override
  String get id => (origin as DynamicRecordDetailProvider).id;
}

String _$customObjectsFilterHash() =>
    r'13c7217ea1355df5d76f816c3f41d5137778bab5';

/// Provider to control whether we show only custom/important objects or all of them
///
/// Copied from [CustomObjectsFilter].
@ProviderFor(CustomObjectsFilter)
final customObjectsFilterProvider =
    AutoDisposeNotifierProvider<CustomObjectsFilter, bool>.internal(
      CustomObjectsFilter.new,
      name: r'customObjectsFilterProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$customObjectsFilterHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$CustomObjectsFilter = AutoDisposeNotifier<bool>;
String _$dynamicObjectListHash() => r'442aec094d81b7638a27e0630e9548c04ec9954d';

abstract class _$DynamicObjectList
    extends BuildlessAutoDisposeAsyncNotifier<List<DynamicRecord>> {
  late final String objectType;

  FutureOr<List<DynamicRecord>> build(String objectType);
}

/// Notifier for a paginated list of DynamicRecords for a given object type
///
/// Copied from [DynamicObjectList].
@ProviderFor(DynamicObjectList)
const dynamicObjectListProvider = DynamicObjectListFamily();

/// Notifier for a paginated list of DynamicRecords for a given object type
///
/// Copied from [DynamicObjectList].
class DynamicObjectListFamily extends Family<AsyncValue<List<DynamicRecord>>> {
  /// Notifier for a paginated list of DynamicRecords for a given object type
  ///
  /// Copied from [DynamicObjectList].
  const DynamicObjectListFamily();

  /// Notifier for a paginated list of DynamicRecords for a given object type
  ///
  /// Copied from [DynamicObjectList].
  DynamicObjectListProvider call(String objectType) {
    return DynamicObjectListProvider(objectType);
  }

  @override
  DynamicObjectListProvider getProviderOverride(
    covariant DynamicObjectListProvider provider,
  ) {
    return call(provider.objectType);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'dynamicObjectListProvider';
}

/// Notifier for a paginated list of DynamicRecords for a given object type
///
/// Copied from [DynamicObjectList].
class DynamicObjectListProvider
    extends
        AutoDisposeAsyncNotifierProviderImpl<
          DynamicObjectList,
          List<DynamicRecord>
        > {
  /// Notifier for a paginated list of DynamicRecords for a given object type
  ///
  /// Copied from [DynamicObjectList].
  DynamicObjectListProvider(String objectType)
    : this._internal(
        () => DynamicObjectList()..objectType = objectType,
        from: dynamicObjectListProvider,
        name: r'dynamicObjectListProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$dynamicObjectListHash,
        dependencies: DynamicObjectListFamily._dependencies,
        allTransitiveDependencies:
            DynamicObjectListFamily._allTransitiveDependencies,
        objectType: objectType,
      );

  DynamicObjectListProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.objectType,
  }) : super.internal();

  final String objectType;

  @override
  FutureOr<List<DynamicRecord>> runNotifierBuild(
    covariant DynamicObjectList notifier,
  ) {
    return notifier.build(objectType);
  }

  @override
  Override overrideWith(DynamicObjectList Function() create) {
    return ProviderOverride(
      origin: this,
      override: DynamicObjectListProvider._internal(
        () => create()..objectType = objectType,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        objectType: objectType,
      ),
    );
  }

  @override
  AutoDisposeAsyncNotifierProviderElement<
    DynamicObjectList,
    List<DynamicRecord>
  >
  createElement() {
    return _DynamicObjectListProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is DynamicObjectListProvider && other.objectType == objectType;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, objectType.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin DynamicObjectListRef
    on AutoDisposeAsyncNotifierProviderRef<List<DynamicRecord>> {
  /// The parameter `objectType` of this provider.
  String get objectType;
}

class _DynamicObjectListProviderElement
    extends
        AutoDisposeAsyncNotifierProviderElement<
          DynamicObjectList,
          List<DynamicRecord>
        >
    with DynamicObjectListRef {
  _DynamicObjectListProviderElement(super.provider);

  @override
  String get objectType => (origin as DynamicObjectListProvider).objectType;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
