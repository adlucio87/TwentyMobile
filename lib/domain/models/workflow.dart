import 'package:freezed_annotation/freezed_annotation.dart';

part 'workflow.freezed.dart';
part 'workflow.g.dart';

@freezed
class WorkflowInputField with _$WorkflowInputField {
  const factory WorkflowInputField({
    required String fieldName,
    required String fieldType, // TEXT, NUMBER, SELECT, BOOLEAN, etc.
    required bool isRequired,
    @Default([]) List<String> options, // for SELECT type
    String? label,
  }) = _WorkflowInputField;

  factory WorkflowInputField.fromJson(Map<String, dynamic> json) =>
      _$WorkflowInputFieldFromJson(json);
}

@freezed
class Workflow with _$Workflow {
  const factory Workflow({
    required String id,
    required String name,
    String? description,
    String? versionId,
    @Default([]) List<WorkflowInputField> inputSchema,
    @Default(false) bool hasFormStep,
  }) = _Workflow;

  factory Workflow.fromJson(Map<String, dynamic> json) =>
      _$WorkflowFromJson(json);

  /// Parses a workflow node from Twenty CRM's GraphQL response.
  ///
  /// Twenty stores workflow definitions in versions. Each version has a
  /// `trigger` JSON object and `steps` array. We extract input fields
  /// from the trigger's settings when triggerType is MANUAL.
  factory Workflow.fromTwenty(Map<String, dynamic> json) {
    final id = json['id'] as String;
    final name = json['name'] as String? ?? 'Unnamed Workflow';

    // Extract the active version (first one from filtered edges)
    String? versionId;
    List<WorkflowInputField> inputSchema = [];
    bool hasFormStep = false;

    // Extract the active version — handle both connection and raw formats
    final versionsRaw = json['versions'];
    List? versions;
    if (versionsRaw is Map<String, dynamic>) {
      final edgesRaw = versionsRaw['edges'];
      if (edgesRaw is List) {
        versions = edgesRaw;
      }
    } else if (versionsRaw is List) {
      versions = versionsRaw;
    }

    if (versions != null && versions.isNotEmpty) {
      final firstVersion = versions.first;
      Map<String, dynamic>? versionNode;
      if (firstVersion is Map<String, dynamic> && firstVersion.containsKey('node')) {
        versionNode = firstVersion['node'] as Map<String, dynamic>?;
      } else if (firstVersion is Map<String, dynamic>) {
        versionNode = firstVersion;
      }

      if (versionNode != null) {
        versionId = versionNode['id'] as String?;

        // Parse input schema from trigger outputSchema or from FORM steps
        final trigger = versionNode['trigger'];
        if (trigger is Map<String, dynamic>) {
          final settings = trigger['settings'] as Map<String, dynamic>?;
          // outputSchema can be a List or an empty Map {}
          if (settings != null) {
            final outputSchemaRaw = settings['outputSchema'];
            if (outputSchemaRaw is List && outputSchemaRaw.isNotEmpty) {
              inputSchema = _parseFieldList(outputSchemaRaw);
            }
          }
        }

        // If no fields from outputSchema, look in steps for FORM type
        if (inputSchema.isEmpty) {
          final stepsRaw = versionNode['steps'];
          if (stepsRaw is List) {
            for (final step in stepsRaw) {
              if (step is Map<String, dynamic>) {
                final stepType = (step['type'] as String? ?? '').toUpperCase();
                if (stepType == 'FORM') {
                  hasFormStep = true;
                  final stepSettings = step['settings'] as Map<String, dynamic>?;
                  if (stepSettings != null) {
                    final inputRaw = stepSettings['input'];
                    if (inputRaw is List && inputRaw.isNotEmpty) {
                      inputSchema = _parseFieldList(inputRaw);
                      break;
                    }
                  }
                }
              }
            }
          }
        }
      }
    }

    return Workflow(
      id: id,
      name: name,
      versionId: versionId,
      inputSchema: inputSchema,
      hasFormStep: hasFormStep,
    );
  }

  /// Parses a list of field definition maps into [WorkflowInputField] objects.
  static List<WorkflowInputField> _parseFieldList(List<dynamic> fields) {
    final result = <WorkflowInputField>[];
    for (final field in fields) {
      if (field is Map<String, dynamic>) {
        result.add(WorkflowInputField(
          fieldName: field['name'] as String? ?? '',
          fieldType: (field['type'] as String? ?? 'TEXT').toUpperCase(),
          isRequired: field['isRequired'] as bool? ?? false,
          label: field['label'] as String?,
          options: (field['options'] is List)
              ? (field['options'] as List<dynamic>)
                  .map((o) => o.toString())
                  .toList()
              : [],
        ));
      }
    }
    return result;
  }
}

/// Supported input field types that the mobile app can render.
class SupportedFieldTypes {
  static const text = 'TEXT';
  static const shortText = 'SHORT_TEXT';
  static const number = 'NUMBER';
  static const select = 'SELECT';
  static const boolean_ = 'BOOLEAN';

  static const Set<String> all = {text, shortText, number, select, boolean_};

  /// Returns true if the field type can be rendered by the mobile app.
  static bool isSupported(String fieldType) =>
      all.contains(fieldType.toUpperCase());
}
