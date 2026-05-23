import 'package:flutter_test/flutter_test.dart';
import 'package:pocketcrm/domain/models/workflow.dart';

void main() {
  group('Workflow.fromTwenty & SupportedFieldTypes', () {
    test('should parse a basic manual workflow with no inputs', () {
      final json = {
        'id': 'wf-1',
        'name': 'Simple Workflow',
        'versions': {
          'edges': [
            {
              'node': {
                'id': 'version-1',
                'trigger': {
                  'type': 'MANUAL',
                  'settings': {'outputSchema': []}
                },
                'steps': []
              }
            }
          ]
        }
      };

      final workflow = Workflow.fromTwenty(json);

      expect(workflow.id, 'wf-1');
      expect(workflow.name, 'Simple Workflow');
      expect(workflow.versionId, 'version-1');
      expect(workflow.inputSchema, isEmpty);
      expect(workflow.hasFormStep, isFalse);
    });

    test('should parse a manual workflow with supported inputs from outputSchema', () {
      final json = {
        'id': 'wf-2',
        'name': 'Workflow with inputs',
        'versions': {
          'edges': [
            {
              'node': {
                'id': 'version-2',
                'trigger': {
                  'type': 'MANUAL',
                  'settings': {
                    'outputSchema': [
                      {
                        'name': 'user_comment',
                        'type': 'TEXT',
                        'isRequired': true,
                        'label': 'Your comment'
                      },
                      {
                        'name': 'send_email',
                        'type': 'BOOLEAN',
                        'isRequired': false,
                        'label': 'Send Email?'
                      }
                    ]
                  }
                },
                'steps': []
              }
            }
          ]
        }
      };

      final workflow = Workflow.fromTwenty(json);

      expect(workflow.inputSchema, hasLength(2));
      expect(workflow.inputSchema[0].fieldName, 'user_comment');
      expect(workflow.inputSchema[0].fieldType, 'TEXT');
      expect(workflow.inputSchema[0].isRequired, isTrue);
      expect(workflow.inputSchema[0].label, 'Your comment');

      expect(workflow.inputSchema[1].fieldName, 'send_email');
      expect(workflow.inputSchema[1].fieldType, 'BOOLEAN');
      expect(workflow.inputSchema[1].isRequired, isFalse);
      expect(workflow.inputSchema[1].label, 'Send Email?');
    });

    test('SupportedFieldTypes.isSupported should return correct values', () {
      expect(SupportedFieldTypes.isSupported('TEXT'), isTrue);
      expect(SupportedFieldTypes.isSupported('SHORT_TEXT'), isTrue);
      expect(SupportedFieldTypes.isSupported('NUMBER'), isTrue);
      expect(SupportedFieldTypes.isSupported('SELECT'), isTrue);
      expect(SupportedFieldTypes.isSupported('BOOLEAN'), isTrue);

      expect(SupportedFieldTypes.isSupported('text'), isTrue);
      expect(SupportedFieldTypes.isSupported('boolean'), isTrue);

      expect(SupportedFieldTypes.isSupported('RELATION'), isFalse);
      expect(SupportedFieldTypes.isSupported('FILE'), isFalse);
      expect(SupportedFieldTypes.isSupported('NESTED_OBJECT'), isFalse);
    });

    test('should identify if a workflow has unsupported required or optional inputs', () {
      final inputSchema = [
        const WorkflowInputField(
          fieldName: 'valid_text',
          fieldType: 'TEXT',
          isRequired: true,
        ),
        const WorkflowInputField(
          fieldName: 'invalid_relation',
          fieldType: 'RELATION',
          isRequired: true,
        ),
        const WorkflowInputField(
          fieldName: 'invalid_optional',
          fieldType: 'FILE',
          isRequired: false,
        ),
      ];

      final workflow = Workflow(
        id: 'wf-3',
        name: 'Workflow with Mixed Inputs',
        inputSchema: inputSchema,
      );

      final hasUnsupportedRequired = workflow.inputSchema.any(
        (field) => field.isRequired && !SupportedFieldTypes.isSupported(field.fieldType),
      );

      final hasUnsupportedOptionalOnly = workflow.inputSchema.any(
        (field) => !field.isRequired && !SupportedFieldTypes.isSupported(field.fieldType),
      );

      expect(hasUnsupportedRequired, isTrue);
      expect(hasUnsupportedOptionalOnly, isTrue);
    });
  });
}
