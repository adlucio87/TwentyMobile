import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocketcrm/core/di/dynamic_preferences_provider.dart';
import 'package:pocketcrm/domain/models/dynamic_field_prefs.dart';
import 'package:pocketcrm/domain/models/metadata/field_metadata.dart';
import 'package:pocketcrm/domain/models/metadata/object_metadata.dart';

/// Opens the "Edit Fields" sheet: reorder fields and toggle their visibility.
///
/// [objectType] is the key the choice is stored under (see [dynamicFieldPrefsProvider]).
/// [candidateFieldNames], if given, limits the sheet to those fields — the person and company
/// screens pass the custom fields they actually render.
void showEditFieldsSheet(
  BuildContext context, {
  required String objectType,
  required ObjectMetadata metadata,
  List<String>? candidateFieldNames,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (context) {
      return EditFieldsSheet(
        objectType: objectType,
        metadata: metadata,
        candidateFieldNames: candidateFieldNames,
      );
    },
  );
}

/// Applies the stored choice to [fields]: hidden ones removed, ordered ones first (in the stored
/// order), the rest after them in their original order.
List<FieldMetadata> applyFieldPrefs(List<FieldMetadata> fields, DynamicFieldPrefs prefs) {
  final visible = fields.where((f) => !prefs.hiddenFields.contains(f.name)).toList();
  final ordered = <FieldMetadata>[
    for (final name in prefs.orderedFields) ...visible.where((f) => f.name == name),
  ];
  return [...ordered, ...visible.where((f) => !ordered.contains(f))];
}

class EditFieldsSheet extends ConsumerStatefulWidget {
  final String objectType;
  final ObjectMetadata metadata;
  final List<String>? candidateFieldNames;

  const EditFieldsSheet({
    super.key,
    required this.objectType,
    required this.metadata,
    this.candidateFieldNames,
  });

  @override
  ConsumerState<EditFieldsSheet> createState() => _EditFieldsSheetState();
}

class _EditFieldsSheetState extends ConsumerState<EditFieldsSheet> {
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
        .where((name) => widget.candidateFieldNames == null || widget.candidateFieldNames!.contains(name))
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
