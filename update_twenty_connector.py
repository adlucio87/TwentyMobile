import re

with open('lib/data/connectors/twenty_connector.dart', 'r') as f:
    content = f.read()

# Add a field for object metadata in TwentyConnector
init_replace = """class TwentyConnector implements CRMRepository {
  final GraphQLClient client;
  final AuthService? authService;
  final VoidCallback? onTokenRefreshed;
  final Map<String, List<String>> customFields;
  String? _currentMemberId;

  /// Mutex for token refresh — prevents concurrent refresh attempts
  Future<bool>? _refreshFuture;

  TwentyConnector({required this.client, this.authService, this.onTokenRefreshed, this.customFields = const {}});"""

content = re.sub(
    r'class TwentyConnector implements CRMRepository \{[\s\S]*?Future<bool>\? _refreshFuture;\n\n  TwentyConnector\(\{required this\.client, this\.authService, this\.onTokenRefreshed\}\);',
    init_replace,
    content
)

# Replace person queries
person_fields = r"""
              company { id name }
              createdAt
              updatedAt
"""
person_fields_replacement = r"""
              company { id name }
              createdAt
              updatedAt
              ${customFields['person']?.join('\n              ') ?? ''}
"""
content = content.replace("company { id name }\n              createdAt\n              updatedAt", person_fields_replacement)

# Replace company queries
company_fields = r"""
              employees
              createdAt
"""
company_fields_replacement = r"""
              employees
              createdAt
              ${customFields['company']?.join('\n              ') ?? ''}
"""
content = content.replace("employees\n              createdAt", company_fields_replacement)

with open('lib/data/connectors/twenty_connector.dart', 'w') as f:
    f.write(content)
