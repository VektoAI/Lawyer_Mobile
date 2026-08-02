/// Authenticated API calls — Render-hosted backend (`../backend/app/main.py`).
library;

import 'dart:async';
import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import 'auth_service.dart';

/// See auth_service.dart's `_requestTimeout` — same reasoning: fail fast and
/// clearly instead of hanging on a stalled/cold-starting connection.
const _requestTimeout = Duration(seconds: 25);

class ApiClient {
  ApiClient({http.Client? client, AuthService? auth}) : _client = client ?? http.Client(), _auth = auth ?? AuthService();

  final http.Client _client;
  final AuthService _auth;
  static const _storage = FlutterSecureStorage();
  static const _tokenKey = 'munshi_token';

  Future<String?> _token() => _storage.read(key: _tokenKey);

  Future<Map<String, String>> _authHeaders({bool jsonBody = false}) async {
    final token = await _token();
    return {
      'Accept': 'application/json',
      if (jsonBody) 'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  Future<Map<String, dynamic>> post(String path, Map<String, dynamic> body) async {
    return _withRefresh((headers) => _client.post(
          Uri.parse('${ApiConfig.apiRoot}$path'),
          headers: {...headers, 'Content-Type': 'application/json'},
          body: jsonEncode(body),
        ));
  }

  Future<Map<String, dynamic>> get(String path) async {
    return _withRefresh((headers) => _client.get(Uri.parse('${ApiConfig.apiRoot}$path'), headers: headers));
  }

  Future<Map<String, dynamic>> patch(String path, Map<String, dynamic> body) async {
    return _withRefresh((headers) => _client.patch(
          Uri.parse('${ApiConfig.apiRoot}$path'),
          headers: {...headers, 'Content-Type': 'application/json'},
          body: jsonEncode(body),
        ));
  }

  Future<http.Response> _send(Future<http.Response> Function(Map<String, String> headers) send, Map<String, String> headers) async {
    try {
      return await send(headers).timeout(_requestTimeout);
    } on TimeoutException {
      throw Exception('Request timed out — check your connection and try again.');
    }
  }

  Future<Map<String, dynamic>> _withRefresh(Future<http.Response> Function(Map<String, String> headers) send) async {
    var headers = await _authHeaders();
    var res = await _send(send, headers);
    if (res.statusCode == 401) {
      final ok = await _auth.refreshAccessToken();
      if (ok) {
        headers = await _authHeaders();
        res = await _send(send, headers);
      }
    }
    return _decode(res);
  }

  Map<String, dynamic> _decode(http.Response res) {
    Map<String, dynamic>? json;
    try {
      json = jsonDecode(res.body) as Map<String, dynamic>?;
    } catch (_) {
      json = null;
    }
    if (res.statusCode >= 400) {
      final detail = json?['detail'];
      throw Exception(detail?.toString() ?? res.body);
    }
    return json ?? {'ok': true};
  }
}

class CourtLookupResult {
  CourtLookupResult({
    required this.found,
    this.parties,
    this.stage,
    this.nextDetail,
    this.nextDate,
    this.warning,
  });

  final bool found;
  final String? parties;
  final String? stage;
  final String? nextDetail;
  final String? nextDate;
  final String? warning;

  factory CourtLookupResult.fromJson(Map<String, dynamic> j) => CourtLookupResult(
        found: j['found'] == true,
        parties: j['parties'] as String?,
        stage: j['stage'] as String?,
        nextDetail: j['next_detail'] as String?,
        nextDate: j['next_date'] as String?,
        warning: j['warning'] as String? ?? j['reason'] as String?,
      );
}

Future<CourtLookupResult> lookupCaseOnCourt({
  required ApiClient api,
  required int courtId,
  required String caseNo,
  String? listDate,
}) async {
  final j = await api.post('/courts/lookup', {
    'court_id': courtId,
    'case_no': caseNo,
    if (listDate != null && listDate.isNotEmpty) 'list_date': listDate,
  });
  return CourtLookupResult.fromJson(j);
}

Future<Map<String, dynamic>> syncCourtHearings({
  required ApiClient api,
  required List<Map<String, dynamic>> cases,
  String? advocateName,
  List<int>? scanCourtIds,
}) async {
  return api.post('/courts/sync-hearings', {
    'cases': cases,
    if (advocateName != null && advocateName.isNotEmpty) 'advocate_name': advocateName,
    if (scanCourtIds != null && scanCourtIds.isNotEmpty) 'scan_court_ids': scanCourtIds,
  });
}
