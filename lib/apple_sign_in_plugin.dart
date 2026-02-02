import 'dart:convert';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:jose/jose.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
export 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'jwt_decoder.dart';

/// **Apple Sign-In Plugin**
///
/// A comprehensive plugin that acts as a wrapper around `sign_in_with_apple`.
/// It provides enhanced features specifically for backend integration:
/// * **Automatic Token Exchange**: Swaps the auth code for access/refresh tokens.
/// * **Token Management**: securely stores and revokes refresh tokens.
/// * **Comprehensive Result**: Returns an [AppleSignInResult] containing everything your backend needs.
class AppleSignInPlugin {
  /// **Private Key Path**
  ///
  /// The local path to your `.pem` file (e.g., `assets/keys/apple_private_key.pem`).
  /// This file is required to generate the Client Secret for Apple.
  static String? _pemKeyPath;

  /// **Key ID**
  ///
  /// The 10-character Key ID from your Apple Developer Account (Certificates, Identifiers & Profiles > Keys).
  static String? _keyId;

  /// **Team ID**
  ///
  /// The 10-character Team ID from your Apple Developer Account (top right corner).
  static String? _teamId;

  /// **Bundle ID (Client ID)**
  ///
  /// The Bundle ID of your app (e.g., `com.example.app`).
  /// This must match the Service ID configured for Sign in with Apple.
  static String? _clientId;

  static final _storage = GetStorage('AppleSignInPlugin');

  /// **Initialize the Plugin**
  ///
  /// Call this method **once** (usually in `main.dart`) before using any other features.
  /// It sets up the cryptographic keys required to communicate securely with Apple.
  ///
  /// **Parameters:**
  /// * [pemKeyPath]: **Required**. The path to your `.pem` file in assets (e.g., `'assets/keys/apple_private_key.pem'`).
  /// * [keyId]: **Required**. Your 10-character Key ID from Apple Developer Console.
  /// * [teamId]: **Required**. Your 10-character Team ID.
  /// * [bundleId]: **Required**. Your App ID (e.g., `com.example.app`). Must match your Service ID.
  static Future<void> initialize({
    required String pemKeyPath,
    required String keyId,
    required String teamId,
    required String bundleId,
  }) async {
    if (pemKeyPath.isEmpty ||
        keyId.isEmpty ||
        teamId.isEmpty ||
        bundleId.isEmpty) {
      throw ArgumentError('All parameters must be non-empty strings');
    }
    if (keyId.contains('YOUR_KEY_ID') ||
        teamId.contains('YOUR_TEAM_ID') ||
        bundleId.contains('YOUR_BUNDLE_ID')) {
      throw ArgumentError(
          '⚠️ PLACEHOLDER DETECTED: You must replace "YOUR_..." in main.dart with your actual Apple Developer credentials (Key ID, Team ID, Bundle ID).');
    }
    _pemKeyPath = pemKeyPath;
    _keyId = keyId;
    _teamId = teamId;
    _clientId = bundleId;
    await GetStorage.init('AppleSignInPlugin');
  }

  static const tokenUrl = 'https://appleid.apple.com/auth/token';
  static const revokeUrl = 'https://appleid.apple.com/auth/revoke';

  /// **Load Private Key**
  ///
  /// Reads the content of the `.pem` file from the assets bundle.
  /// Internal helper used by [_generateClientSecret].
  static Future<String> _loadPemKey() async {
    return await rootBundle.loadString(_pemKeyPath!);
  }

  /// **Generate Client Secret (JWT)**
  ///
  /// Creates a signed ES256 JSON Web Token (JWT) required by Apple's API.
  ///
  /// **Parameters:**
  /// * [validDuration]: How long the secret is valid (in seconds). Default usually 300s (5 mins).
  ///
  /// **Returns:**
  /// * A `String` containing the signed JWT.
  static Future<String> _generateClientSecret(int validDuration) async {
    final pemKeyContent = await _loadPemKey();
    final jwk = JsonWebKey.fromPem(pemKeyContent, keyId: _keyId!);

    final now = DateTime.now();
    final claims = JsonWebTokenClaims.fromJson({
      'iss': _teamId,
      'iat': now.secondsSinceEpoch,
      'exp': now.secondsSinceEpoch + validDuration,
      'aud': 'https://appleid.apple.com',
      'sub': _clientId,
    });

    final builder = JsonWebSignatureBuilder()
      ..jsonContent = claims.toJson()
      ..addRecipient(jwk, algorithm: 'ES256');

    return builder.build().toCompactSerialization();
  }

  /// **Exchange Authorization Code for Tokens**
  ///
  /// Calls Apple's `auth/token` endpoint to exchange the one-time [authorizationCode]
  /// for a persistent `refresh_token` and `access_token`.
  ///
  /// **Parameters:**
  /// * [authorizationCode]: The short-lived code returned from the native sign-in flow.
  static Future<Map<String, dynamic>> _getTokens(
      String authorizationCode) async {
    try {
      final clientSecret = await _generateClientSecret(300);
      final response = await http.post(
        Uri.parse(tokenUrl),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'client_id': _clientId,
          'client_secret': clientSecret,
          'code': authorizationCode,
          'grant_type': 'authorization_code',
        },
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        // Validate required fields
        if (!responseData.containsKey('access_token') ||
            !responseData.containsKey('refresh_token') ||
            !responseData.containsKey('id_token')) {
          throw Exception('Invalid token response: missing required fields');
        }
        return Map<String, dynamic>.from(responseData);
      } else {
        final errorBody = json.decode(response.body);
        _handleAppleError(errorBody, response.reasonPhrase);
      }
    } catch (e) {
      if (e is FormatException) {
        _log(content: 'Invalid JSON response from Apple', title: 'Error');
      }
      rethrow;
    }
  }

  /// **Handle Apple Error Response**
  ///
  /// Parses standard Apple error codes and throws a user-friendly exception.
  /// Returns [Never] to indicate this function always throws.
  static Never _handleAppleError(
      Map<String, dynamic> errorBody, String? reasonPhrase) {
    final errorCode = errorBody['error'] ?? 'unknown_error';
    final errorDescription = errorBody['error_description'] ?? reasonPhrase;

    String friendlyMessage = 'Failed to get tokens ($errorCode)';

    if (errorCode == 'invalid_client') {
      friendlyMessage =
          'Apple Sign-In Error: Client Authentication Failed (invalid_client).\n'
          'Possible Causes:\n'
          '1. "Key ID" does not match the private key.\n'
          '2. "Team ID" is incorrect.\n'
          '3. "Bundle ID" does not match the Service ID in Apple Developer Console.\n'
          '4. The ".pem" private key file is corrupted or incorrect.';
    } else if (errorCode == 'invalid_grant') {
      friendlyMessage =
          'Apple Sign-In Error: Authorization Code Invalid (invalid_grant).\n'
          'Cause: The authorization code has expired or has already been used.\n'
          'Action: Please sign in again to generate a fresh code.';
    } else if (errorCode == 'invalid_request') {
      friendlyMessage =
          'Apple Sign-In Error: Invalid Request (invalid_request).\n'
          'Cause: One or more parameters in the token request are missing or incorrect.';
    }

    _log(
        content: '$friendlyMessage \nRaw Description: $errorDescription',
        title: 'Error');
    throw Exception(friendlyMessage);
  }

  /// **Revoke Refresh Token**
  ///
  /// Calls Apple's `auth/revoke` endpoint to invalidate a refresh token.
  /// This ensures the user is signed out on Apple's side as well for this app.
  ///
  /// **Parameters:**
  /// * [refreshToken]: The token to revoke.
  static Future<void> _revokeAppleToken(String refreshToken) async {
    final clientSecret = await _generateClientSecret(300);

    final response = await http.post(
      Uri.parse(revokeUrl),
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {
        'client_id': _clientId,
        'client_secret': clientSecret,
        'token': refreshToken,
        'token_type_hint': 'refresh_token',
      },
    );

    if (response.statusCode == 200) {
      _log(content: 'Token revoked successfully', title: 'Info');
      _storage.erase();
    } else {
      _log(
          content:
              'Failed to revoke token: ${response.statusCode} ${response.reasonPhrase}',
          title: 'Error');
      _log(content: 'Response body: ${response.body}', title: 'Error');
    }
  }

  /// **Sign In with Apple**
  ///
  /// Triggers the native Apple Sign-In flow.
  ///
  /// **Returns:**
  /// * `Future<AppleSignInResult?>`: A complete object containing the User's Profile (Name, Email) and
  ///   Backend Tokens (ID Token, Access Token, Refresh Token).
  /// * Returns `null` if the user cancels the sign-in or if an error occurs.
  ///
  /// **Usage:**
  /// ```dart
  /// final result = await AppleSignInPlugin.signInWithApple();
  /// if (result != null) {
  ///   print("User ID: ${result.userIdentifier}");
  ///   print("ID Token: ${result.idToken}"); // Send this to your server!
  /// }
  /// ```
  static Future<AppleSignInResult?> signInWithApple() async {
    try {
      // First, check if there's an existing token and revoke it
      final isAppleLogin = _storage.read('isAppleLogin') ?? false;
      if (isAppleLogin) {
        final refreshToken = _storage.read('refreshToken');
        if (refreshToken != null) {
          try {
            await _revokeAppleToken(refreshToken);
          } catch (e) {
            _log(
                content: 'Failed to revoke previous token: $e',
                title: 'Warning');
          } finally {
            // Always clear storage even if revocation fails
            _storage.remove('refreshToken');
            _storage.remove('isAppleLogin');
          }
        }
      }

      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final tokens = await _getTokens(credential.authorizationCode.toString());

      // Save the refresh token using GetStorage
      _storage.write('refreshToken', tokens['refresh_token']);
      _storage.write('isAppleLogin', true);

      String? email = credential.email;
      if (email == null && credential.identityToken != null) {
        var decodedToken =
            JwtDecoder.decode(credential.identityToken.toString());
        email = decodedToken['email'];
      }

      return AppleSignInResult(
        idToken: credential.identityToken,
        accessToken: tokens['access_token'],
        refreshToken: tokens['refresh_token'],
        authorizationCode: credential.authorizationCode,
        userIdentifier: credential.userIdentifier,
        givenName: credential.givenName,
        familyName: credential.familyName,
        email: email,
      );
    } catch (error) {
      _log(content: 'Error during Apple Sign-In: $error', title: 'Error');
      return null;
    }
  }

  /// **Sign Out & Revoke**
  ///
  /// 1. Revokes the `refresh_token` with Apple servers (security best practice).
  /// 2. Clears the local session data.
  ///
  /// Call this when the user logs out of your app.
  static Future<void> signOut() async {
    final isAppleLogin = _storage.read('isAppleLogin') ?? false;

    try {
      if (isAppleLogin) {
        // Retrieve the refresh token from storage
        final refreshToken = _storage.read('refreshToken');
        if (refreshToken != null) {
          await _revokeAppleToken(refreshToken);
          // Clear the stored token after revocation
          _storage.remove('refreshToken');
          _storage.remove('isAppleLogin');
        } else {
          _log(content: 'No refresh token found', title: 'Info');
        }
      } else {
        _log(content: 'not login found to use apple signing', title: 'Info');
      }
    } catch (error) {
      _log(content: 'Error during Apple Sign-Out: $error', title: 'Error');
    }
  }

  /// Custom logging function for debug mode.
  ///
  /// [content] - The content to be logged.
  /// [title] - Optional title for the log entry.
  static void _log({required Object? content, String title = ""}) {
    if (kDebugMode) {
      log(content.toString(), name: title);
    }
  }

  /// **Check Login Status**
  ///
  /// Returns `true` if the user has a valid session (i.e., a stored refresh token).
  /// Note: This does not verify the token with Apple; it only checks local state.
  static bool isSignedIn() {
    return _storage.read('isAppleLogin') ?? false;
  }
}

/// A class containing all relevant data from a successful Apple Sign-In.
class AppleSignInResult {
  /// **ID Token (JWT)**
  ///
  /// This is the most important field for backend verification.
  /// It is a JSON Web Token (JWT) that safely identifies the user.
  /// Send this to your server to verify the user's identity with Apple.
  final String? idToken;

  /// **Access Token**
  ///
  /// A short-lived token used to call Apple's APIs on behalf of the user.
  final String? accessToken;

  /// **Refresh Token**
  ///
  /// A long-lived token used to regenerate a new [accessToken] when it expires.
  /// Store this securely on your server if you need offline access.
  final String? refreshToken;

  /// **Authorization Code**
  ///
  /// A single-use code that is exchanged for the tokens above.
  /// (The plugin handles this exchange automatically, but it is provided here if you need it).
  final String? authorizationCode;

  /// **User Identifier**
  ///
  /// A unique, stable ID for the user (e.g., `000000.abc123...`).
  /// Use this to link the user to a record in your database.
  final String? userIdentifier;

  /// **Given Name**
  ///
  /// The user's first name.
  /// *Note: This is only returned on the **first** sign-in.*
  final String? givenName;

  /// **Family Name**
  ///
  /// The user's last name.
  /// *Note: This is only returned on the **first** sign-in.*
  final String? familyName;

  /// **Email**
  ///
  /// The user's email address.
  /// *Note: This usually comes from the [idToken].*
  final String? email;

  AppleSignInResult({
    this.idToken,
    this.accessToken,
    this.refreshToken,
    this.authorizationCode,
    this.userIdentifier,
    this.givenName,
    this.familyName,
    this.email,
  });

  @override
  String toString() {
    return 'AppleSignInResult(userIdentifier: $userIdentifier, email: $email, givenName: $givenName, familyName: $familyName)';
  }
}

extension SecondsSinceEpoch on DateTime {
  /// Gets the seconds since epoch from [DateTime].
  int get secondsSinceEpoch => millisecondsSinceEpoch ~/ 1000;
}
