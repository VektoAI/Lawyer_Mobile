/// Auth/billing HTTP client for the mobile app (Render + Supabase).
library;

import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../crypto/vault_crypto.dart' show randomBytes;

class AuthException implements Exception {
  AuthException(this.message, {this.status});
  final String message;
  final int? status;
  @override
  String toString() => message;
}

class AuthService {
  AuthService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  static const _storage = FlutterSecureStorage();

  static const _tokenKey = 'munshi_token';
  static const _refreshKey = 'munshi_refresh';
  static const _pendingSignupKey = 'munshi_pending_signup';

  Future<bool> hasToken() async {
    final token = await _storage.read(key: _tokenKey);
    return token != null && token.isNotEmpty;
  }

  Future<void> saveSession({required String token, String? refreshToken}) async {
    await _storage.write(key: _tokenKey, value: token);
    if (refreshToken != null && refreshToken.isNotEmpty) {
      await _storage.write(key: _refreshKey, value: refreshToken);
    }
  }

  Future<void> clearSession() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _refreshKey);
  }

  Future<void> stashPendingSignup({
    required String email,
    required String password,
    String? displayName,
  }) async {
    await _storage.write(
      key: _pendingSignupKey,
      value: jsonEncode({
        'email': email.trim().toLowerCase(),
        'password': password,
        if (displayName != null && displayName.trim().isNotEmpty) 'display_name': displayName.trim(),
      }),
    );
  }

  Future<Map<String, dynamic>?> readPendingSignup() async {
    final raw = await _storage.read(key: _pendingSignupKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<void> clearPendingSignup() async {
    await _storage.delete(key: _pendingSignupKey);
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    return _postJson('/login', {'email': email.trim().toLowerCase(), 'password': password});
  }

  Future<Map<String, dynamic>> signup({
    required String email,
    required String password,
    String? displayName,
    String? phone,
  }) async {
    final saltB64 = base64Encode(randomBytes(16));
    await stashPendingSignup(email: email, password: password, displayName: displayName);
    return _postJson('/signup', {
      'email': email.trim().toLowerCase(),
      'password': password,
      'salt': saltB64,
      if (displayName != null && displayName.trim().isNotEmpty) 'display_name': displayName.trim(),
      if (phone != null && phone.trim().isNotEmpty) 'phone': phone.trim(),
      'email_redirect_to': ApiConfig.emailConfirmRedirect,
    });
  }

  Future<Map<String, dynamic>> demoLogin() async {
    return _postJson('/auth/demo', {});
  }

  Future<void> resendConfirmation(String email) async {
    await _postJson('/auth/resend-confirm', {
      'email': email.trim().toLowerCase(),
      'email_redirect_to': ApiConfig.emailConfirmRedirect,
    });
  }

  Future<Map<String, dynamic>> confirmWithTokenHash({
    required String tokenHash,
    String type = 'signup',
  }) async {
    return _postJson('/auth/confirm', {'token_hash': tokenHash, 'type': type});
  }

  /// Parse Supabase redirect URI (deep link) into a session payload or token_hash confirm.
  Future<Map<String, dynamic>?> sessionFromAuthCallbackUri(Uri uri) async {
    final q = uri.queryParameters;
    Map<String, String> frag = {};
    if (uri.fragment.isNotEmpty) {
      frag = Uri.splitQueryString(uri.fragment);
    }

    final tokenHash = q['token_hash'] ?? frag['token_hash'];
    final otpType = q['type'] ?? frag['type'] ?? 'signup';
    if (tokenHash != null && tokenHash.isNotEmpty) {
      return confirmWithTokenHash(tokenHash: tokenHash, type: otpType);
    }

    final access = frag['access_token'] ?? q['access_token'];
    if (access != null && access.isNotEmpty) {
      return {
        'token': access,
        'refresh_token': frag['refresh_token'] ?? q['refresh_token'],
      };
    }

    final err = q['error_description'] ?? frag['error_description'] ?? q['error'];
    if (err != null && err.isNotEmpty) {
      throw AuthException(Uri.decodeComponent(err));
    }
    return null;
  }

  /// Returns true if a new access token was stored (Supabase session extended).
  Future<bool> refreshAccessToken() async {
    final refresh = await _storage.read(key: _refreshKey);
    if (refresh == null || refresh.isEmpty) return false;
    try {
      final r = await _postJson('/auth/refresh', {'refresh_token': refresh});
      final token = r['token'] as String?;
      if (token == null || token.isEmpty) return false;
      await saveSession(
        token: token,
        refreshToken: r['refresh_token'] as String? ?? refresh,
      );
      return true;
    } on AuthException {
      return false;
    }
  }

  Future<Map<String, dynamic>> _postJson(String path, Map<String, dynamic> body) async {
    final uri = Uri.parse('${ApiConfig.apiRoot}$path');
    final res = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
      body: jsonEncode(body),
    );
    Map<String, dynamic>? decoded;
    try {
      decoded = jsonDecode(res.body) as Map<String, dynamic>?;
    } catch (_) {
      decoded = null;
    }
    if (res.statusCode >= 400) {
      final detail = decoded?['detail'];
      final msg = detail is String
          ? detail
          : detail != null
              ? detail.toString()
              : res.body.isNotEmpty
                  ? res.body
                  : 'Request failed (${res.statusCode})';
      throw AuthException(msg, status: res.statusCode);
    }
    return decoded ?? {'ok': true};
  }
}
