import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pocketcrm/domain/models/dynamic_record.dart';
import 'package:pocketcrm/domain/models/metadata/object_metadata.dart';
import 'package:pocketcrm/core/di/dynamic_object_provider.dart';
import 'package:pocketcrm/presentation/shared/snackbar_helper.dart';
import 'package:pocketcrm/presentation/shared/company_picker_bottom_sheet.dart';
import 'package:pocketcrm/presentation/shared/contact_picker_bottom_sheet.dart';
import 'package:pocketcrm/domain/models/company.dart';
import 'package:pocketcrm/domain/models/contact.dart';

class DynamicFormScreen extends ConsumerStatefulWidget {
  final ObjectMetadata metadata;
  final DynamicRecord? existingRecord; // null if creating a new one

  const DynamicFormScreen({
    Key? key,
    required this.metadata,
    this.existingRecord,
  }) : super(key: key);

  @override
  ConsumerState<DynamicFormScreen> createState() => _DynamicFormScreenState();
}

class _DynamicFormScreenState extends ConsumerState<DynamicFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  
  // Keep track of all field values
  final Map<String, dynamic> _formData = {};
  
  // Controllers for text fields
  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    // Initialize form data based on existing record
    if (widget.existingRecord != null) {
      _formData.addAll(widget.existingRecord!.data);
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() => _isLoading = true);
    
    try {
      final connector = await ref.read(dynamicObjectConnectorProvider.future);
      
      // Clean up empty strings or nulls from form data that shouldn't be sent,
      // but for updates we might need to send nulls to clear fields.
      // We will send _formData as is.
      final payload = Map<String, dynamic>.from(_formData);
      
      // Remove internal fields that cannot be updated/created
      payload.remove('id');
      payload.remove('createdAt');
      payload.remove('updatedAt');
      payload.remove('deletedAt');
      payload.remove('__typename');
      
      // Also remove any actors since we disable editing for them
      final actorFields = widget.metadata.fields
          .where((f) => f.type == 'ACTOR')
          .map((f) => f.name);
      for (final f in actorFields) {
        payload.remove(f);
      }
      
      // We also need to map the relation fields from `{id, name}` back to just sending `{id}` to Twenty,
      // but wait, the Twenty API actually accepts `companyId: "uuid"` for relationships.
      // So if a relation field is 'company', Twenty expects 'companyId' in the mutation.
      // We should check what the relation fields are. 
      // Actually, when fetching, it returns the relation object. 
      // During create/update, if we update a relation 'company', the API usually expects 'companyId'.
      // For now, let's just pass `companyId: val` and remove `company`.
      
      final relationFields = widget.metadata.fields
          .where((f) => f.type == 'RELATION')
          .toList();
      for (final f in relationFields) {
        final val = payload[f.name];
        if (val is Map && val.containsKey('id')) {
          payload['${f.name}Id'] = val['id'];
        }
        // Remove the original relation object from payload to prevent API errors
        payload.remove(f.name);
      }

      if (widget.existingRecord == null) {
        // Create
        await connector.createRecord(widget.metadata, payload);
        if (mounted) {
          SnackbarHelper.showSuccess(context, '${widget.metadata.labelSingular ?? 'Record'} created successfully.');
        }
      } else {
        // Update
        await connector.updateRecord(widget.metadata, widget.existingRecord!.id, payload);
        if (mounted) {
          SnackbarHelper.showSuccess(context, '${widget.metadata.labelSingular ?? 'Record'} updated successfully.');
        }
      }
      
      // Invalidate the list and detail providers
      ref.invalidate(dynamicObjectListProvider);
      if (widget.existingRecord != null) {
        ref.invalidate(dynamicRecordDetailProvider((objectType: widget.metadata.nameSingular, id: widget.existingRecord!.id)));
      }
      
      if (mounted) context.pop(true);
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(context, 'Error saving record: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.existingRecord == null 
        ? 'New ${widget.metadata.labelSingular ?? widget.metadata.nameSingular}'
        : 'Edit ${widget.metadata.labelSingular ?? widget.metadata.nameSingular}';

    // Filter fields to edit
    const hiddenInternalFields = {'id', 'createdAt', 'updatedAt', 'deletedAt', '__typename'};
    final editableFields = widget.metadata.fields
            .where((f) => f.isActive && !hiddenInternalFields.contains(f.name) && !f.name.toLowerCase().contains('search') && !f.name.toLowerCase().contains('position'))
            .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            TextButton(
              onPressed: _save,
              child: const Text('Save', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: editableFields.length,
          separatorBuilder: (context, index) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            final field = editableFields[index];
            final type = field.type.toUpperCase();
            final label = field.label ?? field.name;
            
            final isRelation = type == 'RELATION' || type == 'ACTOR';
            final isBoolean = type == 'BOOLEAN';
            
            if (isRelation) {
              final val = _formData[field.name];
              String displayVal = '—';
              if (val is Map) {
                if (type == 'ACTOR') {
                  displayVal = val['name']?.toString() ?? '—';
                } else {
                  final nameObj = val['name'];
                  if (nameObj is Map) {
                    displayVal = '${nameObj['firstName'] ?? ''} ${nameObj['lastName'] ?? ''}'.trim();
                  } else if (nameObj != null) {
                    displayVal = nameObj.toString();
                  }
                }
              }

              if (type == 'ACTOR' || (!field.name.toLowerCase().contains('company') && !field.name.toLowerCase().contains('person') && !field.name.toLowerCase().contains('contact'))) {
                // Read-only for actors and unknown relations
                return TextFormField(
                  initialValue: displayVal,
                  decoration: InputDecoration(
                    labelText: label,
                    filled: true,
                    border: const OutlineInputBorder(),
                    helperText: 'Editing this relation is currently disabled.',
                  ),
                  enabled: false,
                );
              }

              // Editable relation for Company or Person/Contact
              final isCompany = field.name.toLowerCase().contains('company');
              return InkWell(
                onTap: _isLoading
                    ? null
                    : () async {
                        if (isCompany) {
                          final result = await showModalBottomSheet<Company>(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (context) => const CompanyPickerBottomSheet(),
                          );
                          if (result != null) {
                            setState(() {
                              _formData[field.name] = {
                                'id': result.id,
                                'name': result.name,
                              };
                            });
                          }
                        } else {
                          final result = await showModalBottomSheet<Contact>(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (context) => const ContactPickerBottomSheet(),
                          );
                          if (result != null) {
                            setState(() {
                              _formData[field.name] = {
                                'id': result.id,
                                'name': {
                                  'firstName': result.firstName,
                                  'lastName': result.lastName,
                                },
                              };
                            });
                          }
                        }
                      },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              label,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              displayVal,
                              style: TextStyle(
                                color: displayVal != '—'
                                    ? Theme.of(context).colorScheme.onSurface
                                    : Theme.of(context).colorScheme.onSurfaceVariant,
                                fontSize: 16,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_drop_down),
                    ],
                  ),
                ),
              );
            }
            
            if (isBoolean) {
              final val = _formData[field.name] == true || _formData[field.name] == 'Yes';
              return SwitchListTile(
                title: Text(label),
                value: val,
                onChanged: (newValue) {
                  setState(() {
                    _formData[field.name] = newValue;
                  });
                },
                contentPadding: EdgeInsets.zero,
              );
            }
            
            // --- CURRENCY: two fields (amount + currency code) ---
            if (type == 'CURRENCY') {
              final currencyMap = _formData[field.name];
              final amountMicros = currencyMap is Map ? currencyMap['amountMicros'] : null;
              final currencyCode = currencyMap is Map ? (currencyMap['currencyCode'] ?? '') : '';
              final displayAmount = amountMicros != null ? (amountMicros / 1000000).toStringAsFixed(2) : '';

              final amountCtrl = _controllers.putIfAbsent('${field.name}__amount', () => TextEditingController(text: displayAmount.toString()));
              final codeCtrl = _controllers.putIfAbsent('${field.name}__code', () => TextEditingController(text: currencyCode.toString()));

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: amountCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: label,
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.attach_money),
                      ),
                      onSaved: (val) {
                        final parsed = double.tryParse(val ?? '');
                        final micros = parsed != null ? (parsed * 1000000).round() : 0;
                        final code = codeCtrl.text.trim().isNotEmpty ? codeCtrl.text.trim() : 'USD';
                        _formData[field.name] = {
                          'amountMicros': micros,
                          'currencyCode': code,
                        };
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 1,
                    child: TextFormField(
                      controller: codeCtrl,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(
                        labelText: 'Currency',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              );
            }

            // --- FULL_NAME: firstName + lastName ---
            if (type == 'FULL_NAME') {
              final nameMap = _formData[field.name];
              final firstName = nameMap is Map ? (nameMap['firstName'] ?? '') : '';
              final lastName = nameMap is Map ? (nameMap['lastName'] ?? '') : '';

              final firstCtrl = _controllers.putIfAbsent('${field.name}__first', () => TextEditingController(text: firstName.toString()));
              final lastCtrl = _controllers.putIfAbsent('${field.name}__last', () => TextEditingController(text: lastName.toString()));

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: firstCtrl,
                      decoration: const InputDecoration(
                        labelText: 'First name',
                        border: OutlineInputBorder(),
                      ),
                      onSaved: (_) {
                        _formData[field.name] = {
                          'firstName': firstCtrl.text,
                          'lastName': lastCtrl.text,
                        };
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: lastCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Last name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              );
            }

            // --- EMAILS: primaryEmail ---
            if (type == 'EMAILS') {
              final emailMap = _formData[field.name];
              final primaryEmail = emailMap is Map ? (emailMap['primaryEmail'] ?? '') : '';
              final ctrl = _controllers.putIfAbsent(field.name, () => TextEditingController(text: primaryEmail.toString()));

              return TextFormField(
                controller: ctrl,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: label,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.email),
                ),
                onSaved: (val) {
                  _formData[field.name] = { 'primaryEmail': val ?? '' };
                },
              );
            }

            // --- PHONES: callingCode + number ---
            if (type == 'PHONES') {
              final phoneMap = _formData[field.name];
              final callingCode = phoneMap is Map ? (phoneMap['primaryPhoneCallingCode'] ?? '') : '';
              final number = phoneMap is Map ? (phoneMap['primaryPhoneNumber'] ?? '') : '';

              final codeCtrl = _controllers.putIfAbsent('${field.name}__code', () => TextEditingController(text: callingCode.toString()));
              final numCtrl = _controllers.putIfAbsent('${field.name}__num', () => TextEditingController(text: number.toString()));

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 80,
                    child: TextFormField(
                      controller: codeCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Code',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: numCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: label,
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.phone),
                      ),
                      onSaved: (val) {
                        _formData[field.name] = {
                          'primaryPhoneCallingCode': codeCtrl.text,
                          'primaryPhoneNumber': val ?? '',
                        };
                      },
                    ),
                  ),
                ],
              );
            }

            // --- LINKS: primaryLinkUrl ---
            if (type == 'LINKS') {
              final linksMap = _formData[field.name];
              final url = linksMap is Map ? (linksMap['primaryLinkUrl'] ?? '') : '';
              final ctrl = _controllers.putIfAbsent(field.name, () => TextEditingController(text: url.toString()));

              return TextFormField(
                controller: ctrl,
                keyboardType: TextInputType.url,
                decoration: InputDecoration(
                  labelText: label,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.link),
                ),
                onSaved: (val) {
                  _formData[field.name] = {
                    'primaryLinkUrl': val ?? '',
                    'primaryLinkLabel': '',
                  };
                },
              );
            }

            // --- ADDRESS: street, city, state, postcode, country ---
            if (type == 'ADDRESS') {
              final addrMap = _formData[field.name];
              final street = addrMap is Map ? (addrMap['addressStreet1'] ?? '') : '';
              final city = addrMap is Map ? (addrMap['addressCity'] ?? '') : '';
              final state = addrMap is Map ? (addrMap['addressState'] ?? '') : '';
              final postcode = addrMap is Map ? (addrMap['addressPostcode'] ?? '') : '';
              final country = addrMap is Map ? (addrMap['addressCountry'] ?? '') : '';

              final streetCtrl = _controllers.putIfAbsent('${field.name}__street', () => TextEditingController(text: street.toString()));
              final cityCtrl = _controllers.putIfAbsent('${field.name}__city', () => TextEditingController(text: city.toString()));
              final stateCtrl = _controllers.putIfAbsent('${field.name}__state', () => TextEditingController(text: state.toString()));
              final postcodeCtrl = _controllers.putIfAbsent('${field.name}__postcode', () => TextEditingController(text: postcode.toString()));
              final countryCtrl = _controllers.putIfAbsent('${field.name}__country', () => TextEditingController(text: country.toString()));

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: streetCtrl,
                    decoration: const InputDecoration(labelText: 'Street', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(child: TextFormField(controller: cityCtrl, decoration: const InputDecoration(labelText: 'City', border: OutlineInputBorder()))),
                    const SizedBox(width: 8),
                    Expanded(child: TextFormField(controller: stateCtrl, decoration: const InputDecoration(labelText: 'State', border: OutlineInputBorder()))),
                  ]),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(child: TextFormField(controller: postcodeCtrl, decoration: const InputDecoration(labelText: 'Postcode', border: OutlineInputBorder()))),
                    const SizedBox(width: 8),
                    Expanded(child: TextFormField(
                      controller: countryCtrl,
                      decoration: const InputDecoration(labelText: 'Country', border: OutlineInputBorder()),
                      onSaved: (_) {
                        _formData[field.name] = {
                          'addressStreet1': streetCtrl.text,
                          'addressCity': cityCtrl.text,
                          'addressState': stateCtrl.text,
                          'addressPostcode': postcodeCtrl.text,
                          'addressCountry': countryCtrl.text,
                        };
                      },
                    )),
                  ]),
                ],
              );
            }

            // --- Simple scalar: TEXT, NUMBER, DATE, SELECT, etc. ---
            final rawVal = _formData[field.name];
            final initialValue = rawVal is Map ? rawVal.values.where((v) => v != null).join(', ') : (rawVal?.toString() ?? '');
            final controller = _controllers.putIfAbsent(field.name, () => TextEditingController(text: initialValue));
            
            final isNumber = type == 'NUMBER';
            
            return TextFormField(
              controller: controller,
              keyboardType: isNumber ? TextInputType.number : TextInputType.text,
              maxLines: type.contains('RICH_TEXT') ? 3 : 1,
              decoration: InputDecoration(
                labelText: label,
                border: const OutlineInputBorder(),
              ),
              onSaved: (val) {
                if (val != null) {
                  if (isNumber) {
                    final numVal = double.tryParse(val);
                    if (numVal != null) {
                      _formData[field.name] = numVal;
                    }
                  } else {
                    _formData[field.name] = val;
                  }
                }
              },
            );
          },
        ),
      ),
    );
  }
}
