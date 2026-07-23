import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocketcrm/core/di/dynamic_object_provider.dart';
import 'package:pocketcrm/core/di/metadata_provider.dart';
import 'package:pocketcrm/core/utils/color_utils.dart';
import 'package:pocketcrm/domain/models/dynamic_record.dart';
import 'package:pocketcrm/domain/models/metadata/object_metadata.dart';
import 'package:pocketcrm/presentation/shared/error_state_widget.dart';
import 'package:pocketcrm/presentation/shared/skeleton_loading.dart';
import 'package:go_router/go_router.dart';
import 'package:pocketcrm/shared/widgets/constrained_content.dart';
import 'package:pocketcrm/domain/models/dynamic_field_prefs.dart';
import 'package:pocketcrm/core/di/dynamic_preferences_provider.dart';
import 'package:pocketcrm/presentation/dynamic_objects/dynamic_form_screen.dart';

/// Generic detail screen for any dynamic object record
class DynamicDetailScreen extends ConsumerWidget {
  final String objectType;
  final String id;

  const DynamicDetailScreen({
    super.key,
    required this.objectType,
    required this.id,
  });

  IconData _getIconForFieldType(String type) {
    switch (type.toUpperCase()) {
      case 'TEXT':
      case 'FULL_NAME':
        return Icons.text_fields;
      case 'NUMBER':
        return Icons.numbers;
      case 'BOOLEAN':
        return Icons.check_box;
      case 'DATE':
      case 'DATE_TIME':
        return Icons.calendar_today;
      case 'CURRENCY':
        return Icons.attach_money;
      case 'SELECT':
      case 'MULTI_SELECT':
        return Icons.list;
      case 'EMAIL':
      case 'EMAILS':
        return Icons.email;
      case 'PHONE':
      case 'PHONES':
        return Icons.phone;
      case 'URL':
      case 'LINKS':
        return Icons.link;
      case 'RELATION':
        return Icons.link_rounded;
      case 'RATING':
        return Icons.star;
      case 'ADDRESS':
        return Icons.location_on;
      case 'UUID':
        return Icons.fingerprint;
      default:
        return Icons.tune;
    }
  }

  /// Format a field value for display
  String _formatValue(dynamic value, String type) {
    if (value == null) return '—';

    switch (type.toUpperCase()) {
      case 'BOOLEAN':
        return value == true ? 'Yes' : 'No';
      case 'DATE':
      case 'DATE_TIME':
        final dt = DateTime.tryParse(value.toString());
        if (dt != null) {
          return type.toUpperCase() == 'DATE'
              ? '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}'
              : '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
        }
        return value.toString();
      case 'CURRENCY':
        if (value is Map) {
          final amount = value['amountMicros'];
          final currency = value['currencyCode'] ?? '';
          if (amount != null) {
            final formatted = (amount / 1000000).toStringAsFixed(2);
            return '$currency $formatted'.trim();
          }
        }
        return value.toString();
      case 'FULL_NAME':
        if (value is Map) {
          final first = value['firstName'] ?? '';
          final last = value['lastName'] ?? '';
          return '$first $last'.trim();
        }
        return value.toString();
      case 'LINKS':
        if (value is Map) {
          return value['primaryLinkUrl'] ?? value['primaryLinkLabel'] ?? value.toString();
        }
        return value.toString();
      case 'EMAILS':
        if (value is Map) {
          return value['primaryEmail'] ?? value.toString();
        }
        return value.toString();
      case 'PHONES':
        if (value is Map) {
          final code = value['primaryPhoneCallingCode'] ?? '';
          final number = value['primaryPhoneNumber'] ?? '';
          return '$code$number'.trim();
        }
        return value.toString();
      case 'ADDRESS':
        if (value is Map) {
          final parts = <String>[
            value['addressStreet1'],
            value['addressCity'],
            value['addressState'],
            value['addressPostcode'],
            value['addressCountry'],
          ].whereType<String>().where((s) => s.isNotEmpty).toList();
          return parts.isNotEmpty ? parts.join(', ') : '—';
        }
        return value.toString();
      case 'RATING':
        return value.toString();
      case 'RELATION':
      case 'ACTOR':
        if (value is Map) {
          final nameObj = value['name'];
          if (nameObj is Map) {
            final first = nameObj['firstName'] ?? '';
            final last = nameObj['lastName'] ?? '';
            return '$first $last'.trim();
          } else if (nameObj != null) {
            return nameObj.toString();
          }
        }
        return value.toString();
      case 'RICH_TEXT_V2':
        if (value is Map) {
          return value['blocknote']?.toString() ?? value.toString();
        }
        return value.toString();
      default:
        if (value is Map) return value.values.where((v) => v != null).join(', ');
        return value.toString();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordAsync = ref.watch(
      dynamicRecordDetailProvider((objectType: objectType, id: id)),
    );
    final metadataAsync = ref.watch(workspaceMetadataProvider);
    final prefs = ref.watch(dynamicFieldPrefsProvider(objectType));

    final objectMetadata = metadataAsync.valueOrNull
        ?.where((m) => m.nameSingular == objectType)
        .firstOrNull;
    final singularLabel = objectMetadata?.labelSingular ?? objectType;

    return Scaffold(
      appBar: AppBar(
        title: Text(singularLabel),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () {
              if (objectMetadata != null && recordAsync.valueOrNull != null) {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => DynamicFormScreen(
                    metadata: objectMetadata,
                    existingRecord: recordAsync.value,
                  ),
                ));
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.tune),
            onPressed: () {
              if (objectMetadata != null) {
                _showEditFieldsSheet(context, ref, objectMetadata);
              }
            },
          ),
        ],
      ),
      body: ConstrainedContent(
        child: recordAsync.when(
          data: (record) => _buildDetail(context, record, objectMetadata, prefs),
          loading: () => const ListSkeleton(),
          error: (err, _) => ErrorStateWidget(
            title: 'Loading error',
            message: err.toString(),
            onRetry: () => ref.invalidate(
              dynamicRecordDetailProvider((objectType: objectType, id: id)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetail(
    BuildContext context,
    DynamicRecord record,
    ObjectMetadata? metadata,
    DynamicFieldPrefs prefs,
  ) {
    final bgColor = ColorUtils.avatarColor(record.displayName);

    // Get fields to display, excluding internal ones
    const hiddenInternalFields = {'id', 'name', 'createdAt', 'updatedAt', 'deletedAt', '__typename'};
    var displayFields = metadata?.fields
            .where((f) =>
                f.isActive &&
                !hiddenInternalFields.contains(f.name) &&
                !f.name.toLowerCase().contains('search') &&
                !f.name.toLowerCase().contains('position') &&
                !prefs.hiddenFields.contains(f.name))
            .toList() ??
        [];

    // Sorting logic
    displayFields.sort((a, b) {
      final indexA = prefs.orderedFields.indexOf(a.name);
      final indexB = prefs.orderedFields.indexOf(b.name);
      
      if (indexA != -1 && indexB != -1) return indexA.compareTo(indexB);
      if (indexA != -1) return -1;
      if (indexB != -1) return 1;
      
      // Neither is in orderedFields. Sort by populated status.
      final valA = record.data[a.name];
      final valB = record.data[b.name];
      
      bool isEmpty(dynamic v) {
        if (v == null) return true;
        if (v is String) return v.trim().isEmpty;
        if (v is List) return v.isEmpty;
        if (v is Map) return v.isEmpty || v.values.every((val) => val == null);
        return false;
      }
      
      final aEmpty = isEmpty(valA);
      final bEmpty = isEmpty(valB);
      
      if (aEmpty && !bEmpty) return 1;
      if (!aEmpty && bEmpty) return -1;
      
      return (a.label ?? a.name).compareTo(b.label ?? b.name);
    });

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // ── Header ──
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: bgColor.withValues(alpha: 0.2),
                    child: Text(
                      record.displayName.isNotEmpty
                          ? record.displayName[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        color: bgColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          record.displayName,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        if (record.createdAt != null)
                          Text(
                            'Created on ${record.createdAt!.day}/${record.createdAt!.month}/${record.createdAt!.year}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Fields ──
          if (displayFields.isNotEmpty)
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text(
                      'Details',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  ...displayFields.map((field) {
                    final value = record.data[field.name];
                    final formattedValue = _formatValue(value, field.type);
                    final label = field.label ?? field.name;
                    final icon = _getIconForFieldType(field.type);

                    return _FieldTile(
                      icon: icon,
                      label: label,
                      value: formattedValue,
                      fieldType: field.type,
                      fieldName: field.name,
                      rawValue: value,
                    );
                  }),
                  const SizedBox(height: 8),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _FieldTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String fieldType;
  final String fieldName;
  final dynamic rawValue;

  const _FieldTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.fieldType,
    required this.fieldName,
    this.rawValue,
  });

  @override
  Widget build(BuildContext context) {
    final isRating = fieldType.toUpperCase() == 'RATING';
    final isBoolean = fieldType.toUpperCase() == 'BOOLEAN';
    final isRelation = fieldType.toUpperCase() == 'RELATION' || fieldType.toUpperCase() == 'ACTOR';

    String? relationId;
    String? routePrefix;
    if (isRelation && rawValue is Map) {
      if (fieldType.toUpperCase() == 'ACTOR') {
        relationId = rawValue['workspaceMemberId'];
        routePrefix = '/contacts';
      } else {
        relationId = rawValue['id'];
        final nameLower = fieldName.toLowerCase();
        if (nameLower.contains('company')) {
          routePrefix = '/companies';
        } else if (nameLower.contains('person') || nameLower.contains('contact') || nameLower.contains('user') || nameLower.contains('owner') || nameLower.contains('by') || nameLower == 'assignee') {
          routePrefix = '/contacts';
        }
      }
    }

    final isClickableRelation = isRelation && relationId != null && routePrefix != null;

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: Theme.of(context).colorScheme.tertiary,
          size: 20,
        ),
      ),
      title: isRating
          ? _buildRating(context, value)
          : isBoolean
              ? _buildBoolean(context, value)
              : Text(
                  value,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
      subtitle: Text(label),
      trailing: isClickableRelation ? const Icon(Icons.chevron_right, size: 20) : null,
      onTap: isClickableRelation ? () {
        context.push('$routePrefix/$relationId');
      } : null,
      onLongPress: () {
        if (value.isNotEmpty && value != '—') {
          Clipboard.setData(ClipboardData(text: value));
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$label copied to clipboard'),
              duration: const Duration(seconds: 1),
            ),
          );
        }
      },
    );
  }

  Widget _buildRating(BuildContext context, String value) {
    final rating = int.tryParse(value) ?? 0;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        return Icon(
          i < rating ? Icons.star : Icons.star_border,
          color: Colors.amber,
          size: 20,
        );
      }),
    );
  }

  Widget _buildBoolean(BuildContext context, String value) {
    final isTrue = value == 'Yes';
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isTrue ? Icons.check_circle : Icons.cancel,
          color: isTrue ? Colors.green : Colors.grey,
          size: 20,
        ),
        const SizedBox(width: 8),
        Text(value),
      ],
    );
  }
}

void _showEditFieldsSheet(BuildContext context, WidgetRef ref, ObjectMetadata metadata) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (context) {
      return _EditFieldsSheet(
        objectType: metadata.nameSingular,
        metadata: metadata,
      );
    },
  );
}

class _EditFieldsSheet extends ConsumerStatefulWidget {
  final String objectType;
  final ObjectMetadata metadata;

  const _EditFieldsSheet({required this.objectType, required this.metadata});

  @override
  ConsumerState<_EditFieldsSheet> createState() => _EditFieldsSheetState();
}

class _EditFieldsSheetState extends ConsumerState<_EditFieldsSheet> {
  late List<String> _currentOrder;

  @override
  void initState() {
    super.initState();
    final prefs = ref.read(dynamicFieldPrefsProvider(widget.objectType));
    
    // Build initial order: ordered fields first, then unordered fields alphabetically
    const hiddenInternalFields = {'id', 'name', 'createdAt', 'updatedAt', 'deletedAt', '__typename'};
    final allFields = widget.metadata.fields
        .where((f) => f.isActive && !hiddenInternalFields.contains(f.name) && !f.name.toLowerCase().contains('search') && !f.name.toLowerCase().contains('position'))
        .map((f) => f.name)
        .toList();
        
    final ordered = prefs.orderedFields.where((f) => allFields.contains(f)).toList();
    final unordered = allFields.where((f) => !ordered.contains(f)).toList()..sort();
    
    _currentOrder = [...ordered, ...unordered];
  }

  @override
  Widget build(BuildContext context) {
    final prefs = ref.watch(dynamicFieldPrefsProvider(widget.objectType));

    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Text('Edit Fields', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ReorderableListView.builder(
                scrollController: scrollController,
                itemCount: _currentOrder.length,
                onReorder: (oldIndex, newIndex) {
                  setState(() {
                    if (oldIndex < newIndex) newIndex -= 1;
                    final item = _currentOrder.removeAt(oldIndex);
                    _currentOrder.insert(newIndex, item);
                  });
                  ref.read(dynamicFieldPrefsProvider(widget.objectType).notifier).updateOrder(_currentOrder);
                },
                itemBuilder: (context, index) {
                  final fieldName = _currentOrder[index];
                  final field = widget.metadata.fields.firstWhere((f) => f.name == fieldName);
                  final isHidden = prefs.hiddenFields.contains(fieldName);
                  
                  return ListTile(
                    key: ValueKey(fieldName),
                    leading: const Icon(Icons.drag_handle, color: Colors.grey),
                    title: Text(field.label ?? field.name, style: TextStyle(color: isHidden ? Colors.grey : null)),
                    trailing: IconButton(
                      icon: Icon(
                        isHidden ? Icons.visibility_off : Icons.visibility,
                        color: isHidden ? Colors.grey : Theme.of(context).colorScheme.primary,
                      ),
                      onPressed: () {
                        ref.read(dynamicFieldPrefsProvider(widget.objectType).notifier).toggleVisibility(fieldName);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
