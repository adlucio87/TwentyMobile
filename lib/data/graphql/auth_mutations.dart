const String signInWithPasswordMutation = r'''
mutation SignIn($email: String!, $password: String!) {
  signInWithPassword(
    email: $email
    password: $password
  ) {
    tokens {
      accessToken {
        token
        expiresAt
      }
      refreshToken {
        token
        expiresAt
      }
    }
    user {
      id
      firstName
      lastName
      email
      defaultWorkspace {
        id
        displayName
      }
    }
  }
}
''';

const String refreshTokenMutation = r'''
mutation RefreshToken($refreshToken: String!) {
  renewToken(appToken: $refreshToken) {
    tokens {
      accessToken {
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
