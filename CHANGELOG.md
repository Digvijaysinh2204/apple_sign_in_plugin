## 1.1.3
* Final release with automated publishing configuration

## 1.1.2
* Fixed CI Analysis Error: Removed unused `dart:developer` import
* Code cleanup

## 1.1.1
* Fixed CI error: `Undefined name 'main'` in tests
* Replaced invalid test file with valid placeholder

## 1.1.0
* **MAJOR BREAKING CHANGE**: `signInWithApple()` now returns `AppleSignInResult` object instead of `AuthorizationCredentialAppleID`
* **Backend Ready**: The result object now contains `idToken` (JWT), `accessToken`, `refreshToken`, and user details essential for backend verification.
* **CI/CD**: Fixed version solving errors by switching to Flutter SDK in GitHub Workflows.
* **Code Quality**: Applied dart formatting and improved documentation.

## 1.0.10
* Licence Update
* Changed `clientId` to `bundleId` in Apple Sign-In initialization
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
* Licence Update 

## 1.0.8
* Fixed issue tracker URL
* Improved documentation
* Added proper homepage URL
* Added Flutter SDK constraint
* Code optimization and cleanup

## 1.0.7
* Initial release
* Implemented Apple Sign-In functionality
* Added secure authentication
* Added user data management features

## 1.0.6
* readme file change
* minor bug fixes
* initial release of Sign in with Apple plugin