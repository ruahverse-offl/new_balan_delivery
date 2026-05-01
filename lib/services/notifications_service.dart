import '../models/notification_models.dart';
import 'api_client.dart';

/// GET /api/v1/me/notifications – latest 30 rows.
Future<List<MyNotificationItem>> getMyNotifications() async {
  final data = await apiGet<Map<String, dynamic>>(
    'me/notifications',
    fromJson: (d) => d as Map<String, dynamic>,
  );
  final items = data['items'] as List<dynamic>? ?? [];
  return items
      .map((e) =>
          MyNotificationItem.fromJson(e as Map<String, dynamic>))
      .toList();
}

/// POST /api/v1/me/notification-settings
/// Registers or updates the device push token on the backend.
/// [expoPushToken] will carry the FCM token when using Flutter + Firebase.
Future<void> registerNotificationDevice({
  required String expoPushToken,
  required String devicePlatform,
  String? deviceId,
  bool isPushEnabled = true,
}) =>
    apiPost<dynamic>(
      'me/notification-settings',
      {
        'expo_push_token': expoPushToken,
        'device_platform': devicePlatform,
        if (deviceId != null) 'device_id': deviceId,
        'is_push_enabled': isPushEnabled,
      },
      fromJson: (d) => d,
    );

/// POST /api/v1/me/notification-settings/revoke
/// Soft-deletes the device registration on logout.
Future<void> revokeNotificationDevice({
  String? deviceId,
  String? expoPushToken,
}) =>
    apiPost<dynamic>(
      'me/notification-settings/revoke',
      {
        if (deviceId != null) 'device_id': deviceId,
        if (expoPushToken != null) 'expo_push_token': expoPushToken,
      },
      fromJson: (d) => d,
    );
