# Apple Sign In Plugin

A comprehensive Flutter package for integrating Apple Sign-In with features for secure authentication and user data management.

[![pub package](https://img.shields.io/pub/v/apple_sign_in_plugin.svg)](https://pub.dev/packages/apple_sign_in_plugin)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://pub.dev/packages/apple_sign_in_plugin/license)
[![GitHub issues](https://img.shields.io/github/issues/Digvijaysinh2204/apple_sign_in_plugin)](https://github.com/Digvijaysinh2204/apple_sign_in_plugin/issues)
[![GitHub pull requests](https://img.shields.io/github/issues-pr/Digvijaysinh2204/apple_sign_in_plugin)](https://github.com/Digvijaysinh2204/apple_sign_in_plugin/pulls)

## Features

- Easy Apple Sign-In integration
- Secure authentication handling
- Automatic token management
- Cross-platform support
- Persistent authentication state
- User information retrieval
- Dynamic client secret generation

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  apple_sign_in_plugin: ^latest_version
```

## Platform Setup

> **Note**: This plugin may not work on simulators.

For detailed platform-specific configuration (Android, iOS, macOS, web), please refer to the [sign_in_with_apple](https://pub.dev/packages/sign_in_with_apple) package documentation, as this plugin is based on it.

## Prerequisites

Before using this plugin, you'll need the following identifiers from your Apple Developer account:

- **TeamID (AppID prefix)**: Found in your App ID identifiers
- **KeyID**: Available in the keys section when downloading your private key
- **BundleID**: Your App Bundle ID in Apple's ecosystem
- **Private Key**: Download the `.p8` file (can only be downloaded once)
  - Recommended: Rename the file to `apple_private_key.pem`
  - Also add this file in asset folder and assign path in pubspec.yaml
  - ex: `assets/keys/apple_private_key.pem`

## Usage

### Initialization

```dart
await AppleSignInPlugin.initialize(
    pemKeyPath: 'path/to/your/apple_private_key.pem',
    keyId: 'your-key-id',
    teamId: 'your-team-id',
    bundleId: 'your-bundle-id',
);
```

### Sign In

```dart
final credential = await AppleSignInPlugin.signInWithApple();
```

### Sign Out

```dart
await AppleSignInPlugin.signOut();
```

## How It Works

### User Information Retrieval
The plugin automatically retrieves and manages user email and name during the Apple Sign-In process, ensuring consistent data availability for your application.

### Token Management
The plugin handles:
- Automatic access token revocation and regeneration
- Prevention of null user data in subsequent logins
- Secure token lifecycle management

### Client Secret Generation
- Automatically generates client secrets using private keys
- Ensures secure communication with Apple's authentication services
- No manual client secret handling required

## Implementation Details

### Authentication Flow
1. Initial token retrieval via `https://appleid.apple.com/auth/token`
2. Automatic token revocation using `https://appleid.apple.com/auth/revoke`
3. Dynamic client secret generation for secure authentication

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

If you encounter any issues or have questions, please file them on the [GitHub repository](https://github.com/Digvijaysinh2204/apple_sign_in_plugin/issues).



