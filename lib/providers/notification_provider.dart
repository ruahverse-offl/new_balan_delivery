import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/notifications_service.dart';
import '../utils/device_id.dart';

const _kPushEnabledKey = 'dp_notifications_enabled';
const _kLastTokenKey = 'dp_last_fcm_token';

/// Android notification channel for delivery alerts.
const _kAndroidChannel = AndroidNotificationChannel(
  'delivery_default',
  'Delivery Notifications',
  description: 'Order assignments and delivery updates',
  importance: Importance.high,
);

final _localNotifications = FlutterLocalNotificationsPlugin();

/// Top-level handler for background FCM messages (must be top-level function).
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Firebase is already initialised by main() before this handler fires.
  // No further action needed — FCM shows the notification automatically when
  // the app is in the background/terminated and the message has a notification payload.
}

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

      await _setupLocalNotifications();
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      _listenForeground();

      if (_enabled) {
        await _getFcmToken();
      }
    } catch (e) {
      if (kDebugMode) print('[NotificationProvider] init error: $e');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> _setupLocalNotifications() async {
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_kAndroidChannel);

    await _localNotifications.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
    );

    // Show FCM notifications while the app is in the foreground.
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  void _listenForeground() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;
      if (notification == null) return;
      _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _kAndroidChannel.id,
            _kAndroidChannel.name,
            channelDescription: _kAndroidChannel.description,
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
      );
    });
  }

  Future<void> _getFcmToken() async {
    final messaging = FirebaseMessaging.instance;

    // Refresh listener — re-register whenever FCM rotates the token.
    messaging.onTokenRefresh.listen((newToken) async {
      await _persist(newToken);
      await _register(newToken);
    });

    final token = await messaging.getToken();
    if (token == null) return;
    if (token != _pushToken) {
      await _persist(token);
    }
    await _register(token);
  }

  /// Called from ProfileScreen when the user flips the notification switch.
  Future<void> setEnabled(bool next) async {
    _enabled = next;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kPushEnabledKey, next);

    if (next) {
      await _requestAndRegister();
    } else {
      // Update the backend row with is_push_enabled=false instead of revoking
      // the token — this preserves the row for re-enable without orphan rows.
      final token = _pushToken;
      if (token != null) {
        try {
          final deviceId = await getInstallationId();
          final platform = defaultTargetPlatform.name.toLowerCase();
          await registerNotificationDevice(
            expoPushToken: token,
            devicePlatform: platform,
            deviceId: deviceId,
            isPushEnabled: false,
          );
        } catch (_) {
          // best-effort
        }
      }
    }
  }

  /// Call on login / session restore to ensure the device is registered.
  Future<void> syncWithServer() async {
    if (!_enabled) return;
    if (_pushToken != null) {
      await _register(_pushToken!);
    } else {
      await _getFcmToken();
    }
  }

  Future<void> _requestAndRegister() async {
    final messaging = FirebaseMessaging.instance;
    final settings = await messaging.requestPermission();
    if (settings.authorizationStatus != AuthorizationStatus.authorized &&
        settings.authorizationStatus != AuthorizationStatus.provisional) {
      _enabled = false;
      notifyListeners();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kPushEnabledKey, false);
      return;
    }
    await _getFcmToken();
  }

  Future<void> _revoke() async {
    final token = _pushToken;
    if (token == null) return;
    try {
      final deviceId = await getInstallationId();
      await revokeNotificationDevice(deviceId: deviceId, expoPushToken: token);
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
