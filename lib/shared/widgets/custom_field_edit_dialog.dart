import 'package:flutter/material.dart';
import 'package:pocketcrm/domain/models/metadata/field_metadata.dart';
import 'package:intl/intl.dart';

class CustomFieldEditDialog extends StatefulWidget {
  final String entityId;
  final String entityType; // 'person' or 'company'
  final String fieldName;
  final dynamic initialValue;
  final FieldMetadata metadata;
  final Future<void> Function(Map<String, dynamic> customFields) onSave;

  const CustomFieldEditDialog({
    super.key,
    required this.entityId,
    required this.entityType,
    required this.fieldName,
    this.initialValue,
    required this.metadata,
    required this.onSave,
  });

  @override
  State<CustomFieldEditDialog> createState() => _CustomFieldEditDialogState();
}

class _CustomFieldEditDialogState extends State<CustomFieldEditDialog> {
  late dynamic _currentValue;
  bool _isLoading = false;
  String? _errorMessage;

  late TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _currentValue = widget.initialValue;
    _textController = TextEditingController(
      text: _currentValue?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      dynamic valueToSave;

      if (widget.metadata.type == 'BOOLEAN') {
        valueToSave = _currentValue as bool? ?? false;
      } else if (widget.metadata.type == 'NUMBER' || widget.metadata.type == 'CURRENCY') {
        if (_textController.text.trim().isEmpty) {
          valueToSave = null;
        } else {
          final numValue = num.tryParse(_textController.text.trim());
          if (numValue == null) {
            throw Exception('Invalid number format');
          }
          valueToSave = numValue;
        }
      } else if (widget.metadata.type == 'DATE' || widget.metadata.type == 'DATE_TIME') {
        valueToSave = _currentValue; // already a string ISO8601 or null
      } else {
        valueToSave = _textController.text.trim();
        if (valueToSave.isEmpty) valueToSave = null;
      }

      await widget.onSave({widget.fieldName: valueToSave});
      
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  Widget _buildInput() {
    final type = widget.metadata.type;

    if (type == 'BOOLEAN') {
      return SwitchListTile(
        title: Text(widget.metadata.label ?? widget.metadata.name),
        value: _currentValue as bool? ?? false,
        onChanged: (val) {
          setState(() {
            _currentValue = val;
          });
        },
      );
    }

    if (type == 'DATE' || type == 'DATE_TIME') {
      DateTime? parsedDate;
      if (_currentValue != null && _currentValue is String && _currentValue.isNotEmpty) {
        parsedDate = DateTime.tryParse(_currentValue);
      }
      
      final dateText = parsedDate != null 
          ? DateFormat.yMMMd().format(parsedDate)
          : 'Select a date';

      return ListTile(
        title: Text(dateText),
        trailing: const Icon(Icons.calendar_today),
        onTap: () async {
          final selected = await showDatePicker(
            context: context,
            initialDate: parsedDate ?? DateTime.now(),
            firstDate: DateTime(1900),
            lastDate: DateTime(2100),
          );
          if (selected != null) {
            setState(() {
              _currentValue = selected.toIso8601String();
            });
          }
        },
      );
    }

    // Default to text input
    return TextField(
      controller: _textController,
      decoration: InputDecoration(
        labelText: widget.metadata.label ?? widget.metadata.name,
        border: const OutlineInputBorder(),
      ),
      keyboardType: (type == 'NUMBER' || type == 'CURRENCY') 
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      autofocus: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Edit ${widget.metadata.label ?? widget.metadata.name}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildInput(),
          if (_errorMessage != null) ...[
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 13),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isLoading ? null : _handleSave,
          child: _isLoading
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Save'),
        ),
      ],
    );
  }
}
