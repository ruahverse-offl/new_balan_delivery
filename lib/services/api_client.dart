import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';

String? _globalToken;

/// Called automatically on any 401 response — wired to AuthProvider.logout().
void Function()? onUnauthorized;

void setGlobalToken(String? token) => _globalToken = token;

Map<String, String> _headers() => {
      'Content-Type': 'application/json',
      if (_globalToken != null) 'Authorization': 'Bearer $_globalToken',
    };

Map<String, String> _headersWithToken(String token) => {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

/// GET /api/v1/{path}?{params}
Future<T> apiGet<T>(
  String path, {
  Map<String, dynamic>? params,
  required T Function(dynamic json) fromJson,
}) async {
  var uri = Uri.parse(buildApiUrl(path));
  if (params != null && params.isNotEmpty) {
    final q = params.entries
        .where((e) => e.value != null)
        .map((e) => MapEntry(e.key, e.value.toString()))
        .toList();
    uri = uri.replace(queryParameters: Map.fromEntries(q));
  }
  final res = await http
      .get(uri, headers: _headers())
      .timeout(const Duration(seconds: 15));
  return _handle<T>(res, fromJson);
}

/// GET with explicit token (used before token is stored globally).
Future<T> apiGetWithToken<T>(
  String path,
  String token, {
  required T Function(dynamic json) fromJson,
}) async {
  final uri = Uri.parse(buildApiUrl(path));
  final res = await http
      .get(uri, headers: _headersWithToken(token))
      .timeout(const Duration(seconds: 15));
  return _handle<T>(res, fromJson);
}

/// POST /api/v1/{path}
Future<T> apiPost<T>(
  String path,
  Map<String, dynamic> body, {
  required T Function(dynamic json) fromJson,
  String? explicitToken,
}) async {
  final uri = Uri.parse(buildApiUrl(path));
  final hdrs =
      explicitToken != null ? _headersWithToken(explicitToken) : _headers();
  final res = await http
      .post(uri, headers: hdrs, body: jsonEncode(body))
      .timeout(const Duration(seconds: 15));
  return _handle<T>(res, fromJson);
}

/// PATCH /api/v1/{path}
Future<T> apiPatch<T>(
  String path,
  Map<String, dynamic> body, {
  required T Function(dynamic json) fromJson,
}) async {
  final uri = Uri.parse(buildApiUrl(path));
  final res = await http
      .patch(uri, headers: _headers(), body: jsonEncode(body))
      .timeout(const Duration(seconds: 15));
  return _handle<T>(res, fromJson);
}

T _handle<T>(http.Response res, T Function(dynamic) fromJson) {
  // 401 – session expired or token revoked
  if (res.statusCode == 401) {
    onUnauthorized?.call();
    throw Exception('Session expired. Please sign in again.');
  }

  dynamic data;
  try {
    data = jsonDecode(utf8.decode(res.bodyBytes));
  } catch (_) {
    data = {};
  }

  if (res.statusCode >= 200 && res.statusCode < 300) {
    return fromJson(data);
  }

  // Build a human-readable error message from FastAPI's error shapes:
  //   string       → use as-is
  //   {detail: "…"}   → use detail
  //   {detail: [{msg:"…"}, …]}  → join msgs (FastAPI validation errors)
  final msg = _parseError(data, res.statusCode);
  throw Exception(msg);
}

String _parseError(dynamic data, int status) {
  if (data is Map) {
    final detail = data['detail'] ?? data['message'];
    if (detail == null) return 'Request failed ($status)';
    if (detail is String) return detail.isNotEmpty ? detail : 'Request failed ($status)';
    if (detail is List) {
      final parts = detail
          .map((d) {
            if (d is String) return d;
            if (d is Map) return d['msg']?.toString();
            return null;
          })
          .whereType<String>()
          .where((s) => s.isNotEmpty)
          .toList();
      return parts.isNotEmpty ? parts.join(' · ') : 'Request failed ($status)';
    }
    return detail.toString();
  }
  return 'Request failed ($status)';
}

/// POST best-effort (logout, revoke) — ignores all errors.
Future<void> apiPostBestEffort(String path, {String? token}) async {
  try {
    final uri = Uri.parse(buildApiUrl(path));
    await http
        .post(uri, headers: token != null ? _headersWithToken(token) : _headers())
        .timeout(const Duration(seconds: 10));
  } catch (_) {
    // ignore
  }
}
