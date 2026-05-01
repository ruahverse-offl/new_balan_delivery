import AsyncStorage from '@react-native-async-storage/async-storage';
import { Platform } from 'react-native';

import { getStoredAuth } from '@/lib/api';
import { getOrCreateInstallationId } from '@/lib/deviceInstallationId';
import {
  registerMeNotificationDevice,
  revokeMeNotificationDevices,
  type DevicePlatform,
} from '@/services/meNotificationSettings';

/** Must match ``NotificationContext`` / profile prefs. */
export const NOTIFICATIONS_ENABLED_KEY = 'dp_notifications_enabled';

/** Last known Expo push token for login-time sync and logout revoke (not a secret; device-scoped). */
export const LAST_EXPO_PUSH_TOKEN_KEY = 'dp_last_expo_push_token';

function getDevicePlatform(): DevicePlatform {
  if (Platform.OS === 'android') return 'android';
  if (Platform.OS === 'ios') return 'ios';
  if (Platform.OS === 'web') return 'web';
  return 'unknown';
}

/**
 * Upserts ``M_notification_settings`` using the last local Expo token and prefs.
 * Call after login and when restoring a session so the server always has the current user ↔ device mapping.
 */
export async function syncPushRegistrationWithServer(): Promise<void> {
  const auth = await getStoredAuth();
  if (!auth?.token) return;
  const expo = await AsyncStorage.getItem(LAST_EXPO_PUSH_TOKEN_KEY);
  if (!expo) return;
  const enabledPref = (await AsyncStorage.getItem(NOTIFICATIONS_ENABLED_KEY)) !== '0';
  const device_id = await getOrCreateInstallationId();
  try {
    await registerMeNotificationDevice({
      expo_push_token: expo,
      device_platform: getDevicePlatform(),
      device_id,
      is_push_enabled: enabledPref,
    });
  } catch {
    /* offline / server down */
  }
}

/**
 * Soft-deletes notification settings for this user on the server while the JWT is still valid.
 * Call on logout before clearing local auth.
 */
export async function revokePushRegistrationOnServer(): Promise<void> {
  const auth = await getStoredAuth();
  if (!auth?.token) return;
  const expo = await AsyncStorage.getItem(LAST_EXPO_PUSH_TOKEN_KEY);
  const device_id = await getOrCreateInstallationId();
  try {
    await revokeMeNotificationDevices({
      device_id,
      ...(expo ? { expo_push_token: expo } : {}),
    });
  } catch {
    /* still sign out locally */
  }
}
