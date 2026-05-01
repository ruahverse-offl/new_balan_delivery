import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/auth_models.dart';

const _kAuthKey = 'nb_delivery_auth';

const _storage = FlutterSecureStorage(
  aOptions: AndroidOptions(encryptedSharedPreferences: true),
  iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
);

Future<StoredAuth?> getStoredAuth() async {
  final raw = await _storage.read(key: _kAuthKey);
  if (raw == null || raw.isEmpty) return null;
  try {
    return StoredAuth.fromJsonString(raw);
  } catch (_) {
    return null;
  }
}

Future<void> setStoredAuth(StoredAuth? auth) async {
  if (auth == null) {
    await _storage.delete(key: _kAuthKey);
  } else {
    await _storage.write(key: _kAuthKey, value: auth.toJsonString());
  }
}
