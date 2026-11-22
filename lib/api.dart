import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Android emulator alias for the computer running the backend.
const defaultServerUrl = 'http://10.0.2.2:3000';

class ApiException implements Exception {
  final String message;
  final bool network; // true when the server could not be reached
  final bool unauthorized;
  const ApiException(this.message, {this.network = false, this.unauthorized = false});
  @override
  String toString() => message;
}

class ScanResult {
  final String result; // valid | expired | revoked | invalid
  final String message;
  final String? holderName;
  final String? fromStation;
  final String? toStation;
  final String? ticketClass;
  final String? validFrom;
  final String? validTo;
  final String? photoPath; // e.g. /api/staff/users/<id>/docs/photo
  final bool offline;

  const ScanResult({
    required this.result,
    required this.message,
    this.holderName,
    this.fromStation,
    this.toStation,
    this.ticketClass,
    this.validFrom,
    this.validTo,
    this.photoPath,
    this.offline = false,
  });

  bool get isValid => result == 'valid';

  factory ScanResult.fromJson(Map<String, dynamic> j) {
    final holder = j['holder'] is Map<String, dynamic> ? j['holder'] as Map<String, dynamic> : const <String, dynamic>{};
    return ScanResult(
      result: '${j['result'] ?? 'invalid'}',
      message: '${j['message'] ?? ''}',
      holderName: holder['name'] as String?,
      photoPath: holder['photoUrl'] as String?,
      fromStation: j['fromStation'] as String?,
      toStation: j['toStation'] as String?,
      ticketClass: j['ticketClass'] as String?,
      validFrom: j['validFrom'] as String?,
      validTo: j['validTo'] as String?,
    );
  }
}

/// Talks to the E-Season backend as station staff. The server address is
/// stored on the phone so it can be changed without rebuilding the app.
class StationApi {
  static const _timeout = Duration(seconds: 8);
  static const _urlKey = 'server_url';
  static const _keyKey = 'ticket_public_key';

  String baseUrl;
  String? _token;
  String? staffName;
  String? staffRole;

  StationApi({this.baseUrl = defaultServerUrl});

  bool get signedIn => _token != null;

  static Future<StationApi> load() async {
    final p = await SharedPreferences.getInstance();
    return StationApi(baseUrl: p.getString(_urlKey) ?? defaultServerUrl);
  }

  Future<void> setBaseUrl(String url) async {
    baseUrl = url.trim().replaceAll(RegExp(r'/+$'), '');
    final p = await SharedPreferences.getInstance();
    await p.setString(_urlKey, baseUrl);
  }

  Future<String?> cachedPublicKey() async =>
      (await SharedPreferences.getInstance()).getString(_keyKey);

  void signOut() {
    _token = null;
    staffName = null;
    staffRole = null;
  }

  Uri _uri(String path) => Uri.parse('$baseUrl/api$path');

  Future<http.Response> _send(Future<http.Response> Function() call) async {
    try {
      return await call().timeout(_timeout);
    } on SocketException {
      throw ApiException('Cannot reach the server ($baseUrl)', network: true);
    } on TimeoutException {
      throw ApiException('The server did not answer ($baseUrl)', network: true);
    } on http.ClientException {
      throw ApiException('Cannot reach the server ($baseUrl)', network: true);
    }
  }

  ApiException _error(http.Response r) {
    String msg = 'Request failed (${r.statusCode})';
    try {
      final j = jsonDecode(r.body);
      if (j is Map && j['error'] is Map && j['error']['message'] is String) {
        msg = j['error']['message'] as String;
      }
    } catch (_) {}
    return ApiException(msg, unauthorized: r.statusCode == 401);
  }

  Map<String, String> get _auth => {'Authorization': 'Bearer $_token'};

  Future<void> login(String email, String password) async {
    final r = await _send(() => http.post(_uri('/auth/staff/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email.trim(), 'password': password})));
    if (r.statusCode != 200) throw _error(r);
    final j = jsonDecode(r.body) as Map<String, dynamic>;
    final staff = j['staff'] as Map<String, dynamic>;
    final role = '${staff['role']}';
    if (role != 'station_staff' && role != 'admin') {
      throw const ApiException('This app is for station staff. Use the admin console instead.');
    }
    _token = j['token'] as String;
    staffName = '${staff['fullName']}';
    staffRole = role;
    // Cache the public key so tickets can still be checked without internet.
    try {
      await refreshPublicKey();
    } on ApiException {
      // Not fatal: online scanning still works.
    }
  }

  Future<void> refreshPublicKey() async {
    final r = await _send(() => http.get(_uri('/ticket-public-key')));
    if (r.statusCode != 200 || !r.body.contains('BEGIN PUBLIC KEY')) throw _error(r);
    final p = await SharedPreferences.getInstance();
    await p.setString(_keyKey, r.body);
  }

  /// Server-side check: signature, dates and revocation. Needs internet.
  Future<ScanResult> scan(String token) async {
    final r = await _send(() => http.post(_uri('/staff/tickets/scan'),
        headers: {'Content-Type': 'application/json', ..._auth},
        body: jsonEncode({'token': token})));
    if (r.statusCode != 200) throw _error(r);
    return ScanResult.fromJson(jsonDecode(r.body) as Map<String, dynamic>);
  }

  /// Passenger photo (needs the staff token, so it cannot be a plain URL).
  Future<Uint8List?> photo(String path) async {
    try {
      final r = await _send(() => http.get(Uri.parse('$baseUrl$path'), headers: _auth));
      return r.statusCode == 200 ? r.bodyBytes : null;
    } on ApiException {
      return null;
    }
  }
}
