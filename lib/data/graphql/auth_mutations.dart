// Twenty CRM uses a two-step auth flow:
// 1. `getLoginTokenFromCredentials` → returns a temporary loginToken
// 2. `getAuthTokensFromLoginToken` → exchanges loginToken for access + refresh tokens
//
// Both mutations live on the /metadata endpoint, NOT /graphql.

const String getLoginTokenFromCredentialsMutation = r'''
mutation GetLoginTokenFromCredentials(
  $email: String!,
  $password: String!,
  $origin: String!
) {
  getLoginTokenFromCredentials(
    email: $email,
    password: $password,
    origin: $origin
  ) {
    loginToken {
      token
      expiresAt
    }
  }
}
''';

const String getAuthTokensFromLoginTokenMutation = r'''
mutation GetAuthTokensFromLoginToken(
  $loginToken: String!,
  $origin: String!
) {
  getAuthTokensFromLoginToken(
    loginToken: $loginToken,
    origin: $origin
  ) {
    tokens {
      accessOrWorkspaceAgnosticToken {
        token
        expiresAt
      }
      refreshToken {
        token
        expiresAt
      }
    }
  }
}
''';

const String renewTokenMutation = r'''
mutation RenewToken($appToken: String!) {
  renewToken(appToken: $appToken) {
    tokens {
      accessOrWorkspaceAgnosticToken {
        token
        expiresAt
      }
      refreshToken {
        token
        expiresAt
      }
    }
  }
}
''';
