# Apple Sign In Plugin

A comprehensive, backend-ready Flutter package for integrating Apple Sign-In. 
It provides secure authentication, automatic token management, and returns a complete result object (including JWT, refresh token, access token) essential for backend verification.

[![pub package](https://img.shields.io/pub/v/apple_sign_in_plugin.svg)](https://pub.dev/packages/apple_sign_in_plugin)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://pub.dev/packages/apple_sign_in_plugin/license)

## Features

- 🔐 **Secure Authentication**: Handles the complete Apple Sign-In flow.
- 📦 **Backend Ready**: Returns `idToken`, `accessToken`, and `refreshToken` for server-side validation.
- 🔄 **Token Management**: Automatic handling of refresh tokens and revocations.
- 👤 **User Data**: Retrieves name, email, and stable user ID.
- 📱 **Cross-Platform**: Supports iOS, MacOS, Android, and Web (via `sign_in_with_apple`).

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  apple_sign_in_plugin: ^1.2.1
```

## Setup & Prerequisites

Before using this plugin, ensure you have the following from your [Apple Developer Account](https://developer.apple.com/):

1.  **Service ID / Bundle ID**: The identifier for your app.
2.  **Team ID**: Your Apple Team ID.
3.  **Key ID**: The ID of the private key.
4.  **Private Key File (.p8)**: Download this from Apple and rename it to `apple_private_key.pem`.

### Asset Configuration
Add your private key file to your Flutter assets in `pubspec.yaml`:

```yaml
flutter:
  assets:
    - assets/keys/apple_private_key.pem
```

## Usage

### 1. Initialization
Initialize the plugin with your credentials. This is usually done in `main.dart` or before the first sign-in attempt.

```dart
await AppleSignInPlugin.initialize(
    pemKeyPath: 'assets/keys/apple_private_key.pem',
    keyId: 'YOUR_KEY_ID',
    teamId: 'YOUR_TEAM_ID',
    bundleId: 'YOUR_BUNDLE_ID', // e.g., com.example.app
);
```

### 2. Sign In
Call `signInWithApple()` to start the flow. It returns an `AppleSignInResult` object containing everything you need.

```dart
try {
  final AppleSignInResult? result = await AppleSignInPlugin.signInWithApple();

  if (result != null) {
      print("Sign In Successful!");
      
      // Use these for backend verification:
      print("ID Token (JWT): ${result.idToken}"); 
      print("Access Token: ${result.accessToken}");
      print("Refresh Token: ${result.refreshToken}");
      
      // User Profile:
      print("Email: ${result.email}");
      print("User ID: ${result.userIdentifier}");
      print("Name: ${result.givenName} ${result.familyName}");
  } else {
      print("Sign In Cancelled");
  }
} catch (e) {
  print("Sign In Failed: $e");
}
```

### 3. Sign Out
Securely sign out and revoke tokens.

```dart
await AppleSignInPlugin.signOut();
```

## 📦 What do you get back? (`AppleSignInResult`)
The plugin returns an `AppleSignInResult` object with everything you need. Here is what each field means:

| Field | Description | Why do I need it? |
| :--- | :--- | :--- |
| **`idToken`** | A **JSON Web Token (JWT)** that proves the user's identity. | **Crucial for Backend**: Send this to your server to verify the user is real. |
| **`accessToken`** | A short-lived token for Apple API calls. | Used if your server needs to talk to Apple APIs. |
| **`refreshToken`** | A long-lived token. | Used to get a new `accessToken` when the old one expires. |
| **`authorizationCode`** | A one-time code. | The plugin uses this to get the tokens above. You rarely need this manually. |
| **`userIdentifier`** | A unique User ID (e.g., `000xxx...`). | **Database Key**: Use this to find/create the user in your database. |
| **`email`** | User's email address. | To contact the user. |
| **`givenName`** | First Name. | **First Login Only**: Save this immediately! Apple only sends it once. |
| **`familyName`** | Last Name. | **First Login Only**: Save this immediately! |

## Important Notes
*   **Simulator Issues**: Apple Sign-In may not work correctly on iOS Simulators. Test on a real device.
*   **Android/Web**: This plugin wraps `sign_in_with_apple` logic for broad compatibility, but ensure your Apple Service ID is configured for web callbacks if using on non-Apple platforms.

## License
MIT License. See [LICENSE](LICENSE) for details.



