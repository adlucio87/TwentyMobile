import re

with open('lib/presentation/companies/company_detail_screen.dart', 'r') as f:
    content = f.read()

if "import 'package:pocketcrm/shared/widgets/custom_fields_section.dart';" not in content:
    content = "import 'package:pocketcrm/shared/widgets/custom_fields_section.dart';\n" + content

# Find where notes are displayed and insert custom fields before that
notes_section = """          const SizedBox(height: 24),
          const Text(
            'Related Notes',"""
custom_fields_section = """          const SizedBox(height: 24),
          CustomFieldsSection(customFields: company.customFields),
          const SizedBox(height: 24),
          const Text(
            'Related Notes',"""

content = content.replace(notes_section, custom_fields_section)

with open('lib/presentation/companies/company_detail_screen.dart', 'w') as f:
    f.write(content)
