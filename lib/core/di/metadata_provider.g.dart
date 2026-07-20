// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'metadata_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$metadataConnectorHash() => r'3632d6f68387e348a171b3323fdb382fe83bc44d';

/// See also [metadataConnector].
@ProviderFor(metadataConnector)
final metadataConnectorProvider = FutureProvider<MetadataConnector>.internal(
  metadataConnector,
  name: r'metadataConnectorProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$metadataConnectorHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef MetadataConnectorRef = FutureProviderRef<MetadataConnector>;
String _$workspaceMetadataHash() => r'b165178fc0c71abe4c222713b1728cf9b716765a';

/// See also [WorkspaceMetadata].
@ProviderFor(WorkspaceMetadata)
final workspaceMetadataProvider =
    AsyncNotifierProvider<WorkspaceMetadata, List<ObjectMetadata>>.internal(
      WorkspaceMetadata.new,
      name: r'workspaceMetadataProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$workspaceMetadataHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$WorkspaceMetadata = AsyncNotifier<List<ObjectMetadata>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
