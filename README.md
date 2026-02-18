# Apple Sign In Plugin

[![pub package](https://img.shields.io/pub/v/apple_sign_in_plugin.svg)](https://pub.dev/packages/apple_sign_in_plugin)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://pub.dev/packages/apple_sign_in_plugin/license)

A comprehensive Flutter package for integrating Apple Sign-In with features for secure authentication and user data management. It handles the complete flow, including token exchange and refresh, making it ready for backend integration.

## ✨ Features

- 🔐 **Secure Authentication**: Handles the complete Apple Sign-In flow securely.
- 📦 **Backend Ready**: Returns `idToken`, `accessToken`, and `refreshToken` essential for server-side verification.
- 🔄 **Token Management**: Automatically handles token refreshes and revocations.
- 👤 **User Data**: Retrieves name, email, and stable user ID.
- 📱 **Cross-Platform**: Supports iOS, macOS, Android, and Web.

## 📱 Platform Support

| Platform | Supported | Implementation Note |
| :--- | :---: | :--- |
| **iOS** | ✅ | Native Framework |
| **macOS** | ✅ | Native Framework |
| **Android** | ✅ | via Apple Web Auth |
| **Web** | ✅ | via Apple JS SDK |

## 🛠 Prerequisites

Before using this plugin, ensure you have the following configured in your [Apple Developer Account](https://developer.apple.com/):

1.  **App ID & Service ID**: Created and configured for Sign in with Apple.
2.  **Team ID**: Your 10-character Team ID.
3.  **Key ID**: The ID of your private key.
4.  **Private Key file (.p8)**: Downloaded from Apple. **Rename it to `apple_private_key.pem`**.

## 📦 Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  apple_sign_in_plugin: ^1.2.6
```

## ⚙️ Setup & Configuration

### 1. Asset Configuration (Required)
Add your `.pem` private key file to your Flutter assets in `pubspec.yaml`:

```yaml
flutter:
  assets:
    - assets/keys/apple_private_key.pem
```

### 2. iOS / macOS
- Open your project in Xcode.
- Go to **Signing & Capabilities**.
- Add the **Sign in with Apple** capability.

### 3. Android / Web
- Ensure you have created a **Service ID** in the Apple Developer Console.
- Configure your **Return URLs** and **Web Domain** for the Service ID.

## 🚀 Usage

### 1. Initialize
Initialize the plugin *once*, preferably in `main.dart` or before the first usage.

```dart
await AppleSignInPlugin.initialize(
  pemKeyPath: 'assets/keys/apple_private_key.pem',
  keyId: 'YOUR_KEY_ID',
  teamId: 'YOUR_TEAM_ID',
  bundleId: 'YOUR_BUNDLE_ID', // Must match your Service ID
);
```

### 2. Sign In
Call `signInWithApple()` to start the authentication flow.

```dart
try {
  final result = await AppleSignInPlugin.signInWithApple();

  if (result != null) {
      print("Sign In Successful!");
      print("ID Token: ${result.idToken}"); 
      print("Email: ${result.email}");
      print("User ID: ${result.userIdentifier}");
  } else {
      print("Sign In Cancelled");
  }
} catch (e) {
  print("Sign In Failed: $e");
}
```

### 3. Sign Out
Securely signs the user out and invalidates the tokens.

```dart
await AppleSignInPlugin.signOut();
```

### 4. Check State
Check if the user is currently considered logged in (locally).

```dart
bool isLoggedIn = AppleSignInPlugin.isSignedIn();
```

## 📦 The Result Object (`AppleSignInResult`)

The plugin returns an `AppleSignInResult` object containing all necessary data.

| Field | Description | Usage |
| :--- | :--- | :--- |
| **`idToken`** | JSON Web Token (JWT). | **Verify on Backend**. Proves user identity. |
| **`accessToken`** | Short-lived Apple API token. | Accessing Apple APIs. |
| **`refreshToken`** | Long-lived token. | Getting new access tokens. |
| **`userIdentifier`** | Unique User ID. | **Database Key**. Identify users in your DB. |
| **`email`** | User's email. | User contact/profile. |
| **`givenName`** | First Name. | User profile (First login only). |
| **`familyName`** | Last Name. | User profile (First login only). |
| **`authorizationCode`**| One-time code. | Used internally for token exchange. |

## ❓ Troubleshooting

| Error Code | Possible Cause | Solution |
| :--- | :--- | :--- |
| `invalid_client` | Incorrect credentials. | Check Team ID, Key ID, Bundle ID, and ensure the `.pem` file is correct and loaded. |
| `invalid_grant` | Expired/Used code. | Expected if reusing a code. Sign in again to get a fresh code. |
| `invalid_request` | Missing parameters. | Verify all `initialize()` parameters are non-empty strings. |
| `Simulation Fail` | iOS Simulator issue. | Test on a **Real Device**. Simulators often fail with Keychain errors. |

## 📄 License

MIT License. See [LICENSE](LICENSE) for details.
