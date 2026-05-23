import 'package:flutter/material.dart';
import 'package:pocketcrm/domain/models/workflow.dart';

/// Dynamic form that renders input fields based on a workflow's [inputSchema].
///
/// Field types are mapped to appropriate Flutter widgets. Unsupported
/// types show a warning, and if any required field is unsupported the
/// form blocks execution with a prominent banner.
class WorkflowInputForm extends StatefulWidget {
  /// Schema fields to render.
  final List<WorkflowInputField> fields;

  /// Called whenever any form value changes.
  final ValueChanged<Map<String, dynamic>> onChanged;

  /// Called whenever the form's overall validation state changes.
  final ValueChanged<bool> onValidationChanged;

  const WorkflowInputForm({
    super.key,
    required this.fields,
    required this.onChanged,
    required this.onValidationChanged,
  });

  @override
  State<WorkflowInputForm> createState() => _WorkflowInputFormState();
}

class _WorkflowInputFormState extends State<WorkflowInputForm> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, dynamic> _values = {};
  final Map<String, TextEditingController> _controllers = {};
  final Set<String> _interacted = {};

  /// True if any required field is of an unsupported type.
  late bool _hasUnsupportedRequired;

  @override
  void initState() {
    super.initState();

    _hasUnsupportedRequired = widget.fields.any(
      (f) => f.isRequired && !SupportedFieldTypes.isSupported(f.fieldType),
    );

    for (final field in widget.fields) {
      if (!SupportedFieldTypes.isSupported(field.fieldType)) continue;

      final type = field.fieldType.toUpperCase();
      if (type == SupportedFieldTypes.boolean_) {
        _values[field.fieldName] = false;
      } else {
        final controller = TextEditingController();
        _controllers[field.fieldName] = controller;
        controller.addListener(() {
          _values[field.fieldName] = controller.text;
          _notifyChanges();
        });
      }
    }

    // Notify initial validation state
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _notifyValidation();
    });
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _notifyChanges() {
    widget.onChanged(Map<String, dynamic>.from(_values));
    _notifyValidation();
  }

  void _notifyValidation() {
    if (_hasUnsupportedRequired) {
      widget.onValidationChanged(false);
      return;
    }

    final isValid = widget.fields.every((field) {
      if (!field.isRequired) return true;
      if (!SupportedFieldTypes.isSupported(field.fieldType)) return false;

      final value = _values[field.fieldName];
      if (value == null) return false;
      if (value is String && value.trim().isEmpty) return false;
      return true;
    });

    widget.onValidationChanged(isValid);
  }

  String _formatLabel(WorkflowInputField field) {
    final raw = field.label ?? field.fieldName;
    if (raw.isEmpty) return raw;
    return raw[0].toUpperCase() + raw.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Unsupported required fields banner
          if (_hasUnsupportedRequired) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Colors.amber.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.amber,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'This workflow requires complex data. '
                      'Please run it from the web platform.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Build fields
          for (int i = 0; i < widget.fields.length; i++) ...[
            _buildField(widget.fields[i]),
            if (i < widget.fields.length - 1) const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }

  Widget _buildField(WorkflowInputField field) {
    final type = field.fieldType.toUpperCase();
    final label = _formatLabel(field);
    final isRequired = field.isRequired;
    final hasInteracted = _interacted.contains(field.fieldName);

    if (!SupportedFieldTypes.isSupported(type)) {
      return _buildUnsupportedField(label, isRequired);
    }

    switch (type) {
      case SupportedFieldTypes.text:
        return _buildTextField(field, label, isRequired, hasInteracted,
            maxLines: 3);
      case SupportedFieldTypes.shortText:
        return _buildTextField(field, label, isRequired, hasInteracted,
            maxLines: 1);
      case SupportedFieldTypes.number:
        return _buildNumberField(field, label, isRequired, hasInteracted);
      case SupportedFieldTypes.select:
        return _buildSelectField(field, label, isRequired);
      case SupportedFieldTypes.boolean_:
        return _buildBooleanField(field, label);
      default:
        return _buildUnsupportedField(label, isRequired);
    }
  }

  Widget _buildTextField(
    WorkflowInputField field,
    String label,
    bool isRequired,
    bool hasInteracted, {
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: _controllers[field.fieldName],
      maxLines: maxLines,
      minLines: 1,
      decoration: InputDecoration(
        labelText: isRequired ? '$label *' : label,
      ),
      validator: isRequired && hasInteracted
          ? (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Required field';
              }
              return null;
            }
          : null,
      onChanged: (_) {
        if (!_interacted.contains(field.fieldName)) {
          _interacted.add(field.fieldName);
        }
      },
    );
  }

  Widget _buildNumberField(
    WorkflowInputField field,
    String label,
    bool isRequired,
    bool hasInteracted,
  ) {
    return TextFormField(
      controller: _controllers[field.fieldName],
      keyboardType:
          const TextInputType.numberWithOptions(decimal: true, signed: true),
      decoration: InputDecoration(
        labelText: isRequired ? '$label *' : label,
      ),
      validator: (value) {
        if (isRequired &&
            hasInteracted &&
            (value == null || value.trim().isEmpty)) {
          return 'Required field';
        }
        if (value != null && value.isNotEmpty && double.tryParse(value) == null) {
          return 'Enter a numeric value';
        }
        return null;
      },
      onChanged: (value) {
        if (!_interacted.contains(field.fieldName)) {
          _interacted.add(field.fieldName);
        }
        // Store as number
        final parsed = double.tryParse(value);
        _values[field.fieldName] = parsed ?? value;
        _notifyChanges();
      },
    );
  }

  Widget _buildSelectField(
    WorkflowInputField field,
    String label,
    bool isRequired,
  ) {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: isRequired ? '$label *' : label,
      ),
      value: _values[field.fieldName] as String?,
      items: field.options.map((option) {
        return DropdownMenuItem<String>(
          value: option,
          child: Text(option),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _values[field.fieldName] = value;
          _interacted.add(field.fieldName);
        });
        _notifyChanges();
      },
      validator: isRequired
          ? (value) {
              if (value == null || value.isEmpty) {
                return 'Select a value';
              }
              return null;
            }
          : null,
    );
  }

  Widget _buildBooleanField(WorkflowInputField field, String label) {
    return SwitchListTile.adaptive(
      title: Text(label),
      value: _values[field.fieldName] as bool? ?? false,
      contentPadding: EdgeInsets.zero,
      onChanged: (value) {
        setState(() {
          _values[field.fieldName] = value;
          _interacted.add(field.fieldName);
        });
        _notifyChanges();
      },
    );
  }

  Widget _buildUnsupportedField(String label, bool isRequired) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.amber.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$label — This field requires the web app${isRequired ? ' (required)' : ''}',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
