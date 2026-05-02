import 'package:flutter_dotenv/flutter_dotenv.dart';

/// API origin — resolved in this order:
/// 1. Compile-time `--dart-define=API_ORIGIN=...`
/// 2. `.env`: `API_ORIGIN` or `VITE_API_BASE_URL` (aligned with new_balan_fe)
/// 3. Default: Android emulator → host `http://10.0.2.2:8000`
String _apiOrigin = 'http://10.0.2.2:8000';

/// Path prefix before route segments, always with leading and trailing `/`.
String _apiPrefix = '/api/v1/';

/// Current API origin (after [loadApiConfig] in `main`).
String get kApiOrigin => _apiOrigin;

/// Load API origin/prefix from dart-define and/or `.env`.
///
/// Call after [dotenv.load] (if using `.env`). Safe to call if dotenv was not loaded.
void loadApiConfig() {
  const dartDefineOrigin = String.fromEnvironment(
    'API_ORIGIN',
    defaultValue: '',
  );
  const dartDefinePrefix = String.fromEnvironment(
    'API_PREFIX',
    defaultValue: '',
  );

  if (dartDefineOrigin.isNotEmpty) {
    _apiOrigin = _stripTrailingSlashes(dartDefineOrigin);
  } else {
    final env = dotenv.isInitialized ? dotenv.env : const {};
    final origin = env['API_ORIGIN'] ?? env['VITE_API_BASE_URL'];
    if (origin != null && origin.trim().isNotEmpty) {
      _apiOrigin = _stripTrailingSlashes(origin.trim());
    }
  }

  if (dartDefinePrefix.isNotEmpty) {
    _apiPrefix = _normalizeApiPrefix(dartDefinePrefix);
  } else {
    final env = dotenv.isInitialized ? dotenv.env : const {};
    final prefix = env['API_PREFIX'] ?? env['VITE_API_PREFIX'];
    if (prefix != null && prefix.trim().isNotEmpty) {
      _apiPrefix = _normalizeApiPrefix(prefix.trim());
    }
  }
}

String _stripTrailingSlashes(String s) => s.replaceAll(RegExp(r'/+$'), '');

String _normalizeApiPrefix(String p) {
  var x = p.startsWith('/') ? p : '/$p';
  if (!x.endsWith('/')) {
    x = '$x/';
  }
  return x;
}

String buildApiUrl(String path) {
  final clean = path.startsWith('/') ? path.substring(1) : path;
  return '$_apiOrigin$_apiPrefix$clean';
}
