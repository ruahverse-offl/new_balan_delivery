import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/notifications_service.dart';
import '../utils/device_id.dart';

const _kPushEnabledKey = 'dp_notifications_enabled';
const _kLastTokenKey = 'dp_last_fcm_token';

/// Manages push-notification opt-in/opt-out and device registration.
///
/// Firebase / FCM integration:
///   1. Add google-services.json to android/app/
///   2. Add GoogleService-Info.plist to ios/Runner/
///   3. Uncomment firebase_core and firebase_messaging in pubspec.yaml
///   4. Call Firebase.initializeApp() in main() before runApp()
///   5. Uncomment the FirebaseMessaging calls below
class NotificationProvider extends ChangeNotifier {
  bool _loading = true;
  bool _enabled = false;
  String? _pushToken;

  bool get loading => _loading;
  bool get enabled => _enabled;
  String? get pushToken => _pushToken;

  NotificationProvider() {
    _init();
  }

  Future<void> _init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _enabled = prefs.getBool(_kPushEnabledKey) ?? false;
      _pushToken = prefs.getString(_kLastTokenKey);
    } catch (_) {
      // ignore
    } finally {
      _loading = false;
      notifyListeners();
    }
    // TODO: when Firebase is enabled, call _getFcmToken() here.
  }

  /// Called from ProfileScreen when the user flips the switch.
  Future<void> setEnabled(bool next) async {
    _enabled = next;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kPushEnabledKey, next);

    if (next) {
      await _requestAndRegister();
    } else {
      await _revoke();
    }
  }

  /// Call on login / session restore to ensure the device is registered.
  Future<void> syncWithServer() async {
    if (!_enabled || _pushToken == null) return;
    await _register(_pushToken!);
  }

  Future<void> _requestAndRegister() async {
    // ── Firebase (uncomment when configured) ─────────────────────────
    // final messaging = FirebaseMessaging.instance;
    // final settings = await messaging.requestPermission();
    // if (settings.authorizationStatus != AuthorizationStatus.authorized) {
    //   _enabled = false;
    //   notifyListeners();
    //   return;
    // }
    // final token = await messaging.getToken();
    // if (token == null) return;
    // ─────────────────────────────────────────────────────────────────

    // Stub: no token available without Firebase. Log and return.
    if (kDebugMode) {
      print('[NotificationProvider] Firebase not configured – skipping token registration.');
    }
    // When Firebase is configured, replace the stub with:
    // await _persist(token);
    // await _register(token);
  }

  Future<void> _revoke() async {
    if (_pushToken == null) return;
    try {
      final deviceId = await getInstallationId();
      await revokeNotificationDevice(
          deviceId: deviceId, expoPushToken: _pushToken);
    } catch (_) {
      // best-effort
    }
  }

  Future<void> _register(String token) async {
    try {
      final deviceId = await getInstallationId();
      final platform = defaultTargetPlatform.name.toLowerCase();
      await registerNotificationDevice(
        expoPushToken: token,
        devicePlatform: platform,
        deviceId: deviceId,
        isPushEnabled: true,
      );
    } catch (_) {
      // best-effort
    }
  }

  Future<void> _persist(String token) async {
    _pushToken = token;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLastTokenKey, token);
  }

  /// Call on logout to revoke push registration.
  Future<void> onLogout() async => _revoke();
}
