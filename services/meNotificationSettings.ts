import { apiPost } from '@/lib/api';

export type DevicePlatform = 'android' | 'ios' | 'web' | 'unknown';

/** POST /api/v1/me/notification-settings — upserts ``M_notification_settings`` for push delivery. */
export async function registerMeNotificationDevice(payload: {
  expo_push_token: string;
  device_platform: DevicePlatform;
  device_id?: string | null;
  is_push_enabled: boolean;
}) {
  return apiPost<Record<string, unknown>>('me/notification-settings', payload);
}

/** POST /api/v1/me/notification-settings/revoke — soft-delete rows for logout. */
export async function revokeMeNotificationDevices(payload: {
  device_id?: string | null;
  expo_push_token?: string | null;
}) {
  return apiPost<{ revoked_count: number }>('me/notification-settings/revoke', payload);
}
