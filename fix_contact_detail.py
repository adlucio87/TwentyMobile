import re

with open('lib/presentation/contact_detail/contact_detail_screen.dart', 'r') as f:
    content = f.read()

# Remove the unused custom_fields_section import if present at the top
content = content.replace("import 'package:pocketcrm/shared/widgets/custom_fields_section.dart';\nimport 'package:pocketcrm/shared/widgets/custom_fields_section.dart';\n", "import 'package:pocketcrm/shared/widgets/custom_fields_section.dart';\n")
if "import 'package:pocketcrm/shared/widgets/custom_fields_section.dart';" not in content:
    content = "import 'package:pocketcrm/shared/widgets/custom_fields_section.dart';\n" + content

# Find where notes are displayed and insert custom fields before that
notes_section = """          const SizedBox(height: 24),
          const Text(
            'Related Notes',"""
custom_fields_section = """          const SizedBox(height: 24),
          CustomFieldsSection(customFields: contact.customFields),
          const SizedBox(height: 24),
          const Text(
            'Related Notes',"""

content = content.replace(notes_section, custom_fields_section)

with open('lib/presentation/contact_detail/contact_detail_screen.dart', 'w') as f:
    f.write(content)
