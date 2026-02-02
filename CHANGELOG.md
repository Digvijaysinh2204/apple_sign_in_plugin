## 1.1.5
- **Fix**: Resolved `IconAlignment` export conflict with Flutter Material library.
- **CI/CD**: Implemented automated OIDC authentication for secure publishing.

## 1.1.0
- **Feature**: `signInWithApple()` now returns `AppleSignInResult` containing `idToken`, `accessToken`, and `refreshToken`.
- **Backend Ready**: Suitable for server-side verification.
- **Improvement**: Enhanced code quality and documentation.

## 1.0.10

- Licence Update
- Changed `clientId` to `bundleId` in Apple Sign-In initialization
  - **Migration Example:**

    ```dart
    // Previous code
    await AppleSignInPlugin.initialize(
        pemKeyPath: 'path/to/your/apple_private_key.pem',
        keyId: 'your-key-id',
        teamId: 'your-team-id',
        clientId: 'your-client-id',
    );

    // Updated code
    await AppleSignInPlugin.initialize(
        pemKeyPath: 'path/to/your/apple_private_key.pem',
        keyId: 'your-key-id',
        teamId: 'your-team-id',
        bundleId: 'your-bundle-id',
    );
    ```

## 1.0.9

- Licence Update

## 1.0.8

- Fixed issue tracker URL
- Improved documentation
- Added proper homepage URL
- Added Flutter SDK constraint
- Code optimization and cleanup

## 1.0.7

- Initial release
- Implemented Apple Sign-In functionality
- Added secure authentication
- Added user data management features

## 1.0.6

- readme file change
- minor bug fixes
- initial release of Sign in with Apple plugin
