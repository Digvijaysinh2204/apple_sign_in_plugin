import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:jose/jose.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class AppleSignInPlugin {
  static String? _pemKeyPath;
  static String? _keyId;
  static String? _teamId;
  static String? _clientId;

  static final _storage = GetStorage();

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
    await GetStorage.init();
  }

  static const tokenUrl = 'https://appleid.apple.com/auth/token';
  static const revokeUrl = 'https://appleid.apple.com/auth/revoke';
  static Future<String> _loadPemKey() async {
    return await rootBundle.loadString(_pemKeyPath!);
  }

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
      throw Exception(
          'Failed to get tokens: ${response.statusCode} ${response.reasonPhrase}');
    }
  }

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
      if (kDebugMode) {
        print('Token revoked successfully');
      }
      _storage.erase();
    } else {
      if (kDebugMode) {
        print(
            'Failed to revoke token: ${response.statusCode} ${response.reasonPhrase}');
      }
      if (kDebugMode) {
        print('Response body: ${response.body}');
      }
    }
  }

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

      return credential;
    } catch (error) {
      if (kDebugMode) {
        print('Error during Apple Sign-In: $error');
      }
      return null;
    }
  }

  static Future<void> signOut() async {
    try {
      // Retrieve the refresh token from storage
      final refreshToken = _storage.read('refreshToken');
      if (refreshToken != null) {
        await _revokeAppleToken(refreshToken);
        // Clear the stored token after revocation
        _storage.remove('refreshToken');
      } else {
        if (kDebugMode) {
          print('No refresh token found');
        }
      }
    } catch (error) {
      if (kDebugMode) {
        print('Error during Apple Sign-Out: $error');
      }
    }
  }
}

extension SecondsSinceEpoch on DateTime {
  int get secondsSinceEpoch => millisecondsSinceEpoch ~/ 1000;
}
