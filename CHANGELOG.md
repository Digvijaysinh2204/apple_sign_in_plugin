## 1.2.1
- **Documentation**: Achieved 100% documentation coverage. Every method and parameter now has educational DartDocs.
- **Example App**: Improved UI to clearly display Backend Tokens (ID, Access, Refresh) for easier debugging.
- **User Friendly**: Major README overhaul with "Why do I need it?" explanations and clear integration steps.

## 1.2.0
- **Feature**: Full export of `sign_in_with_apple` package (including widgets like `SignInWithAppleButton`).
- **Feature**: `signInWithApple()` returns `AppleSignInResult` with tokens for backend verification.
- **CI/CD**: Fully automated publishing via GitHub Actions with OIDC authentication.

## 1.1.0
- **Breaking Change**: `signInWithApple()` now returns `AppleSignInResult` object instead of `AuthorizationCredentialAppleID`
- **Backend Ready**: Result object contains `idToken` (JWT), `accessToken`, `refreshToken`, and user details.
- **CI/CD**: Fixed version solving errors in workflows.
