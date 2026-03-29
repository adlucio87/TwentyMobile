import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pocketcrm/core/data/country_codes.dart';

class PhoneInputField extends StatefulWidget {
  final String? initialValue;
  final ValueChanged<String?> onChanged;
  final FormFieldValidator<String>? validator;

  const PhoneInputField({
    super.key,
    this.initialValue,
    required this.onChanged,
    this.validator,
  });

  static (String, String) parseE164(String? phone) {
    if (phone == null || phone.isEmpty) return ('+39', '');
    if (!phone.startsWith('+')) return ('+39', phone);

    for (var i = 4; i >= 2; i--) {
      if (phone.length > i) {
        final prefix = phone.substring(0, i);
        if (countryCodes.any((c) => c.dialCode == prefix)) {
          return (prefix, phone.substring(i));
        }
      }
    }
    return ('+39', phone);
  }

  @override
  State<PhoneInputField> createState() => _PhoneInputFieldState();
}

class _PhoneInputFieldState extends State<PhoneInputField> {
  late CountryCode _selectedCountry;
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    final (dialCode, localNumber) = PhoneInputField.parseE164(widget.initialValue);

    _controller = TextEditingController(text: localNumber);

    if (widget.initialValue == null || widget.initialValue!.isEmpty) {
      _selectedCountry = _getDefaultCountry();
    } else {
      _selectedCountry = countryCodes.firstWhere(
        (c) => c.dialCode == dialCode,
        orElse: () => _getDefaultCountry(),
      );
    }

    _controller.addListener(_updateValue);
  }

  CountryCode _getDefaultCountry() {
    try {
      final localeParts = Platform.localeName.split('_');
      final countryCodeStr = localeParts.length > 1 ? localeParts[1] : null;

      if (countryCodeStr != null) {
        final match = countryCodes.where((c) => c.isoCode == countryCodeStr).toList();
        if (match.isNotEmpty) return match.first;
      }
    } catch (_) {}
    return countryCodes.firstWhere((c) => c.isoCode == 'IT');
  }

  @override
  void dispose() {
    _controller.removeListener(_updateValue);
    _controller.dispose();
    super.dispose();
  }

  void _updateValue() {
    final text = _controller.text;
    if (text.isEmpty) {
      widget.onChanged(null);
    } else {
      final cleanText = text.replaceAll(RegExp(r'[\s\-]'), '');
      widget.onChanged('${_selectedCountry.dialCode}$cleanText');
    }
  }

  void _showCountryPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _CountryPickerSheet(
        onSelected: (country) {
          setState(() => _selectedCountry = country);
          _updateValue();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: _showCountryPicker,
          child: Container(
            width: 110,
            height: 56, // Standard TextFormField height typically
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).colorScheme.outline),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                bottomLeft: Radius.circular(8),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    '${_selectedCountry.flag} ${_selectedCountry.dialCode}',
                    style: const TextStyle(fontSize: 16),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(Icons.arrow_drop_down, color: Theme.of(context).colorScheme.onSurfaceVariant),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TextFormField(
            controller: _controller,
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9\s\-]')),
            ],
            decoration: InputDecoration(
              hintText: '333 123 4567',
              border: const OutlineInputBorder(
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
                borderSide: BorderSide(color: Theme.of(context).colorScheme.outline),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return null;
              final cleanValue = value.replaceAll(RegExp(r'[\s\-]'), '');
              final fullNumber = '${_selectedCountry.dialCode}$cleanValue';

              if (!fullNumber.startsWith('+')) {
                 return 'Invalid number';
              }
              if (cleanValue.length < 8) {
                return 'Invalid number — enter at least 8 digits';
              }
              if (fullNumber.length > 15) {
                return 'Invalid number — enter at most 15 digits';
              }
              if (widget.validator != null) {
                 return widget.validator!(value);
              }
              return null;
            },
          ),
        ),
      ],
    );
  }
}

class _CountryPickerSheet extends StatefulWidget {
  final ValueChanged<CountryCode> onSelected;

  const _CountryPickerSheet({required this.onSelected});

  @override
  State<_CountryPickerSheet> createState() => _CountryPickerSheetState();
}

class _CountryPickerSheetState extends State<_CountryPickerSheet> {
  final TextEditingController _searchController = TextEditingController();
  List<CountryCode> _filteredCountries = countryCodes;

  @override
  void initState() {
    super.initState();
    // Sort all countries alphabetically
    final sorted = List<CountryCode>.from(countryCodes)
      ..sort((a, b) => a.name.compareTo(b.name));
    _filteredCountries = sorted;

    _searchController.addListener(() {
      final query = _searchController.text.toLowerCase();
      setState(() {
        _filteredCountries = sorted.where((c) {
          return c.name.toLowerCase().contains(query) ||
                 c.dialCode.contains(query);
        }).toList();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: FractionallySizedBox(
        heightFactor: 0.8,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Search country or prefix',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _filteredCountries.length,
                itemBuilder: (context, index) {
                  final c = _filteredCountries[index];
                  return ListTile(
                    leading: Text(c.flag, style: const TextStyle(fontSize: 24)),
                    title: Text(c.name),
                    trailing: Text(c.dialCode),
                    onTap: () {
                      widget.onSelected(c);
                      Navigator.of(context).pop();
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
