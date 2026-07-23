import 'package:pocketcrm/domain/models/metadata/field_metadata.dart';
import 'package:pocketcrm/domain/models/metadata/object_metadata.dart';

class DynamicQueryBuilder {
  static const _scalarTypes = {
    'TEXT', 'NUMBER', 'BOOLEAN', 'DATE', 'DATE_TIME', 'UUID',
    'SELECT', 'RATING', 'URL', 'EMAIL', 'PHONE', 'MULTI_SELECT',
    'RICH_TEXT', 'RAW_JSON', 'JSON'
  };

  static const _skipFieldNames = {'searchVector', 'position'};

  /// Convert a FieldMetadata to its GraphQL selection string, or null if unsupported
  static String? _fieldToGraphql(FieldMetadata field) {
    if (!field.isActive) return null;
    final nameLower = field.name.toLowerCase();
    if (_skipFieldNames.any((s) => nameLower.contains(s))) return null;
    
    final type = field.type.toUpperCase();
    if (_scalarTypes.contains(type)) return field.name;
    if (type == 'CURRENCY') return '${field.name} { amountMicros currencyCode }';
    if (type == 'FULL_NAME') return '${field.name} { firstName lastName }';
    if (type == 'LINKS') return '${field.name} { primaryLinkUrl primaryLinkLabel }';
    if (type == 'EMAILS') return '${field.name} { primaryEmail }';
    if (type == 'PHONES') return '${field.name} { primaryPhoneNumber primaryPhoneCallingCode }';
    if (type == 'ADDRESS') return '${field.name} { addressStreet1 addressCity addressState addressCountry addressPostcode }';
    if (type == 'RELATION') {
      final nameLower = field.name.toLowerCase();
      
      // Many-to-Many or One-to-Many relations in Twenty return Connection types
      // which cannot be queried with a simple `{ id name }`. We skip them for now.
      const skipConnections = {
        'timelineactivities', 'favorites', 'tasktargets', 'notetargets', 'notes', 'tasks',
        'attachments', 'messages', 'events', 'comments', 'workflowruns',
        'workflows', 'opportunities', 'people', 'companies', 'tags'
      };
      
      if (skipConnections.contains(nameLower) || nameLower.endsWith('connection')) {
        return null;
      }
      
      if (nameLower.contains('company')) {
        return '${field.name} { id name }';
      } else if (nameLower.contains('person') || nameLower.contains('contact') || nameLower.contains('user') || nameLower.contains('owner') || nameLower.contains('by') || nameLower == 'assignee') {
        return '${field.name} { id name { firstName lastName } }';
      } else {
        return '${field.name} { id name }';
      }
    }
    
    if (type == 'ACTOR') {
      return '${field.name} { workspaceMemberId name source }';
    }

    if (type == 'RICH_TEXT_V2') {
      // In Twenty CRM, RICH_TEXT_V2 is an object containing blocknote
      return '${field.name} { blocknote }';
    }

    // Skip other unsupported complex types
    return null;
  }

  /// Build the field selection string for a given object metadata
  static String buildFieldSelection(ObjectMetadata metadata) {
    final fields = metadata.fields
        .map(_fieldToGraphql)
        .where((f) => f != null)
        .cast<String>()
        .toList();
    // Always ensure id and createdAt are present
    if (!fields.contains('id')) fields.insert(0, 'id');
    if (!fields.contains('createdAt')) fields.add('createdAt');
    if (!fields.contains('updatedAt')) fields.add('updatedAt');
    return fields.join('\n              ');
  }

  /// Build a list query with pagination and optional filter
  static String buildListQuery(ObjectMetadata metadata) {
    final pluralName = metadata.namePlural;
    final singularCapitalized = metadata.nameSingular[0].toUpperCase() + metadata.nameSingular.substring(1);
    final fieldSelection = buildFieldSelection(metadata);
    
    return '''
      query FindMany$singularCapitalized(\$filter: ${singularCapitalized}FilterInput, \$first: Int, \$after: String) {
        $pluralName(filter: \$filter, first: \$first, after: \$after, orderBy: { createdAt: DescNullsLast }) {
          edges {
            node {
              $fieldSelection
            }
          }
          pageInfo { hasNextPage endCursor }
        }
      }
    ''';
  }

  /// Build a detail query (find by ID)
  static String buildDetailQuery(ObjectMetadata metadata) {
    final pluralName = metadata.namePlural;
    final singularCapitalized = metadata.nameSingular[0].toUpperCase() + metadata.nameSingular.substring(1);
    final fieldSelection = buildFieldSelection(metadata);
    
    return '''
      query FindOne$singularCapitalized(\$id: UUID!) {
        $pluralName(filter: { id: { eq: \$id } }) {
          edges {
            node {
              $fieldSelection
            }
          }
        }
      }
    ''';
  }

  /// Build a create mutation
  static String buildCreateMutation(ObjectMetadata metadata) {
    final singularCapitalized = metadata.nameSingular[0].toUpperCase() + metadata.nameSingular.substring(1);
    
    return '''
      mutation Create$singularCapitalized(\$input: ${singularCapitalized}CreateInput!) {
        create$singularCapitalized(data: \$input) {
          id
        }
      }
    ''';
  }

  /// Build an update mutation
  static String buildUpdateMutation(ObjectMetadata metadata) {
    final singularCapitalized = metadata.nameSingular[0].toUpperCase() + metadata.nameSingular.substring(1);
    
    return '''
      mutation Update$singularCapitalized(\$id: UUID!, \$input: ${singularCapitalized}UpdateInput!) {
        update$singularCapitalized(id: \$id, data: \$input) {
          id
        }
      }
    ''';
  }
}
