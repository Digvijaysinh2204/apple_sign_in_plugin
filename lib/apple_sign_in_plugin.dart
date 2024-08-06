import 'dart:convert';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:jose/jose.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

/// A plugin for handling Apple Sign-In functionality.
class AppleSignInPlugin {
  static String? _pemKeyPath;
  static String? _keyId;
  static String? _teamId;
  static String? _clientId;

  static final _storage = GetStorage('AppleSignInPlugin');

  /// Initializes the AppleSignInPlugin with necessary parameters.
  ///
  /// [pemKeyPath] - Path to the PEM key file.
  /// [keyId] - The key identifier.
  /// [teamId] - The team identifier.
  /// [clientId] - The client identifier.
  static Future<void> initialize({
    required String pemKeyPath,
    required String keyId,
    required String teamId,
    required String clientId,
  }) async {
    _pemKeyPath = pemKeyPath;
    _keyId = keyId;
    _teamId = teamId;
    _clientId = clientId;
    await GetStorage.init('AppleSignInPlugin');
  }

  static const tokenUrl = 'https://appleid.apple.com/auth/token';
  static const revokeUrl = 'https://appleid.apple.com/auth/revoke';

  /// Loads the PEM key content from the specified path.
  static Future<String> _loadPemKey() async {
    return await rootBundle.loadString(_pemKeyPath!);
  }

  /// Generates a client secret for Apple authentication.
  ///
  /// [validDuration] - The duration for which the client secret is valid, in seconds.
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

  /// Retrieves tokens using the provided authorization code.
  ///
  /// [authorizationCode] - The authorization code obtained from Apple Sign-In.
  static Future<Map<String, dynamic>> _getTokens(
      String authorizationCode) async {
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
      return Map<String, dynamic>.from(json.decode(response.body));
    } else {
      kLog(
          content:
              'Failed to get tokens: ${response.statusCode} ${response.reasonPhrase}',
          title: 'Error');
      throw Exception(
          'Failed to get tokens: ${response.statusCode} ${response.reasonPhrase}');
    }
  }

  /// Revokes the Apple refresh token.
  ///
  /// [refreshToken] - The refresh token to be revoked.
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
      kLog(content: 'Token revoked successfully', title: 'Info');
      _storage.erase();
    } else {
      kLog(
          content:
              'Failed to revoke token: ${response.statusCode} ${response.reasonPhrase}',
          title: 'Error');
      kLog(content: 'Response body: ${response.body}', title: 'Error');
    }
  }

  /// Signs in the user with Apple and returns the [AuthorizationCredentialAppleID].
  static Future<AuthorizationCredentialAppleID?> signInWithApple() async {
    try {
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
      if (credential.email != null) {
        return credential;
      } else {
        var decodedToken =
            JwtDecoder.decode(credential.identityToken.toString());
        return AuthorizationCredentialAppleID(
            userIdentifier: credential.userIdentifier,
            givenName: credential.givenName ?? "",
            familyName: credential.familyName ?? "",
            authorizationCode: credential.authorizationCode,
            email: decodedToken['email'] ?? "",
            identityToken: credential.identityToken,
            state: credential.state);
      }
    } catch (error) {
      kLog(content: 'Error during Apple Sign-In: $error', title: 'Error');
      return null;
    }
  }

  /// Signs out the user by revoking the Apple refresh token.
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
          kLog(content: 'No refresh token found', title: 'Info');
        }
      } else {
        kLog(content: 'not login found to use apple signing', title: 'Info');
      }
    } catch (error) {
      kLog(content: 'Error during Apple Sign-Out: $error', title: 'Error');
    }
  }

  /// Custom logging function for debug mode.
  ///
  /// [content] - The content to be logged.
  /// [title] - Optional title for the log entry.
  static void kLog({required content, String title = ""}) {
    if (kDebugMode) {
      log(content.toString(), name: title);
    }
  }
}

extension SecondsSinceEpoch on DateTime {
  /// Gets the seconds since epoch from [DateTime].
  int get secondsSinceEpoch => millisecondsSinceEpoch ~/ 1000;
}
