import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

const _kKey = 'dp_installation_id';

/// Returns a stable per-install ID (survives app restarts, lost on reinstall).
/// Equivalent to lib/deviceInstallationId.ts in the React Native app.
Future<String> getInstallationId() async {
  final prefs = await SharedPreferences.getInstance();
  final existing = prefs.getString(_kKey);
  if (existing != null && existing.isNotEmpty) return existing;
  final id = 'dp-${const Uuid().v4()}';
  await prefs.setString(_kKey, id);
  return id;
}
