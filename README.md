# Apple Sign-In Plugin

The `apple_sign_in_plugin` package is designed to seamlessly integrate Apple Sign-In functionality into your Flutter applications. It ensures that user information such as email and name remains accessible by managing access tokens effectively.

## Features

### User Information Retrieval
- Retrieves user email and name during the Apple Sign-In process, ensuring this data is consistently available for your application.

### Token Management
- Automatically handles the revocation and regeneration of access tokens. This process is crucial to maintain access to user data across sessions. If the access token is not revoked after the initial login, user information like email and name may become null in subsequent logins. The package automates this process to prevent such issues.

### Dynamic Client Secret Generation
- Securely generates client secrets using private keys. This ensures that your application's interactions with Apple's authentication services are secure and compliant with Apple's guidelines. The plugin automatically generates the client secret, so you don't need to do this manually.

## Implementation Details

### Initial Token Retrieval
Use the post request to `https://appleid.apple.com/auth/token` with parameters like `client_id`, `client_secret`, `code`, `grant_type`, and `redirect_uri` to obtain the initial access token during login.

### Token Revocation
Use the post request to `https://appleid.apple.com/auth/revoke` with parameters including `client_id`, `client_secret`, and `token` to revoke the access token when necessary. This step is critical after the initial login to prevent null user data issues in subsequent sessions.

### Client Secret Generation
For generating the client secret using a private key, refer to Apple's documentation on creating a client secret. However, this plugin automatically generates the client secret, so you don't need to handle this manually.

## Important Identifiers
  - **TeamID (also called AppID prefix):** This will be in your App ID identifiers.
  - **KeyID:** This will be in the keys section when you download your private key.
  - **ClientID:** In Apple land, this is the Services ID.
  - **Audience:** This will always be `https://appleid.apple.com`.

When you download your key file (which you can only do once), it will download with `.p8` extension. It is recommended to rename this file to `apple_private_key.pem`.

## Usage

### Initialization

```` dart
    await AppleSignInPlugin.initialize(
        pemKeyPath: 'path/to/your/apple_private_key.pem',
        keyId: 'your-key-id',
        teamId: 'your-team-id',
        clientId: 'your-client-id',
        )
````

### Sign-In

```` dart
    final credential = await AppleSignInPlugin.signInWithApple();
````

### Sign-Out
``` dart
await AppleSignInPlugin.signOut();
```


### Platform-Specific Configuration
This plugin may not work on the simulator. For detailed platform-specific configuration (Android, iOS, macOS, web), please refer to the documentation of the sign_in_with_apple package, as this plugin is based on it: sign_in_with_apple.

### Conclusion
The apple_sign_in_plugin package provides robust support for integrating Apple Sign-In in Flutter applications while ensuring seamless management of access tokens and consistent availability of user data. By automating token revocation and regeneration, it helps maintain a smooth user experience without compromising on security or data integrity. The plugin automatically generates the client secret, so you don't need to handle this manually.



