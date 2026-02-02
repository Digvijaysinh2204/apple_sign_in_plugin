## 1.2.0
- **Feature**: Full export of `sign_in_with_apple` package (including widgets like `SignInWithAppleButton`).
- **Feature**: `signInWithApple()` returns `AppleSignInResult` with tokens for backend verification.
- **CI/CD**: Fully automated publishing via GitHub Actions with OIDC authentication.

## 1.1.0
- **Breaking Change**: `signInWithApple()` now returns `AppleSignInResult` object instead of `AuthorizationCredentialAppleID`
- **Backend Ready**: Result object contains `idToken` (JWT), `accessToken`, `refreshToken`, and user details.
- **CI/CD**: Fixed version solving errors in workflows.
