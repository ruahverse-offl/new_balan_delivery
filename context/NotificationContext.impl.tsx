import React, { createContext, useCallback, useContext, useEffect, useMemo, useRef, useState } from 'react';
import { Alert, Platform } from 'react-native';
import AsyncStorage from '@react-native-async-storage/async-storage';
import * as Notifications from 'expo-notifications';
import Constants from 'expo-constants';

import { useAuth } from '@/context/AuthContext';
import {
  LAST_EXPO_PUSH_TOKEN_KEY,
  NOTIFICATIONS_ENABLED_KEY,
} from '@/lib/pushDeviceSync';
import { getOrCreateInstallationId } from '@/lib/deviceInstallationId';
import { registerMeNotificationDevice, type DevicePlatform } from '@/services/meNotificationSettings';

const NOTIFICATIONS_PROMPTED_KEY = 'dp_notifications_prompted_once';
const ANDROID_CHANNEL_ID = 'delivery_default';

Notifications.setNotificationHandler({
  handleNotification: async () => ({
    shouldShowBanner: true,
    shouldShowList: true,
    shouldPlaySound: true,
    shouldSetBadge: false,
  }),
});

type NotificationContextValue = {
  loading: boolean;
  enabled: boolean;
  permissionGranted: boolean;
  expoPushToken: string | null;
  setEnabled: (next: boolean) => Promise<void>;
  refreshToken: () => Promise<void>;
};

const NotificationContext = createContext<NotificationContextValue | null>(null);

async function ensureAndroidNotificationChannel(): Promise<void> {
  if (Platform.OS !== 'android') return;
  await Notifications.setNotificationChannelAsync(ANDROID_CHANNEL_ID, {
    name: 'Delivery alerts',
    importance: Notifications.AndroidImportance.HIGH,
    vibrationPattern: [0, 250, 250, 250],
  });
}

function getProjectId(): string | undefined {
  const expoConfigProjectId = Constants.expoConfig?.extra?.eas?.projectId;
  const easConfigProjectId = Constants.easConfig?.projectId;
  return typeof easConfigProjectId === 'string'
    ? easConfigProjectId
    : typeof expoConfigProjectId === 'string'
      ? expoConfigProjectId
      : undefined;
}

async function fetchExpoPushTokenSafe(): Promise<string | null> {
  const projectId = getProjectId();
  if (!projectId) return null;
  const token = await Notifications.getExpoPushTokenAsync({ projectId });
  return token?.data || null;
}

function getDevicePlatform(): DevicePlatform {
  if (Platform.OS === 'android') return 'android';
  if (Platform.OS === 'ios') return 'ios';
  if (Platform.OS === 'web') return 'web';
  return 'unknown';
}

export function NotificationProvider({ children }: { children: React.ReactNode }) {
  const { token: authToken } = useAuth();
  const [loading, setLoading] = useState(true);
  const [enabled, setEnabledState] = useState(false);
  const [permissionGranted, setPermissionGranted] = useState(false);
  const [expoPushToken, setExpoPushToken] = useState<string | null>(null);

  const receivedSubscriptionRef = useRef<Notifications.EventSubscription | null>(null);
  const responseSubscriptionRef = useRef<Notifications.EventSubscription | null>(null);

  const refreshToken = useCallback(async () => {
    if (!permissionGranted || !enabled) {
      setExpoPushToken(null);
      await AsyncStorage.removeItem(LAST_EXPO_PUSH_TOKEN_KEY);
      return;
    }
    /** ``POST /me/notification-settings`` requires JWT — do not fetch/persist Expo token before sign-in. */
    if (!authToken) {
      setExpoPushToken(null);
      return;
    }
    try {
      await ensureAndroidNotificationChannel();
      const tokenStr = await fetchExpoPushTokenSafe();
      setExpoPushToken(tokenStr);
      if (tokenStr) {
        await AsyncStorage.setItem(LAST_EXPO_PUSH_TOKEN_KEY, tokenStr);
      } else {
        await AsyncStorage.removeItem(LAST_EXPO_PUSH_TOKEN_KEY);
      }
      if (tokenStr && authToken) {
        try {
          const device_id = await getOrCreateInstallationId();
          await registerMeNotificationDevice({
            expo_push_token: tokenStr,
            device_platform: getDevicePlatform(),
            device_id,
            is_push_enabled: true,
          });
        } catch {
          /* API unreachable or not deployed — token still shown locally */
        }
      }
    } catch {
      setExpoPushToken(null);
      await AsyncStorage.removeItem(LAST_EXPO_PUSH_TOKEN_KEY);
    }
  }, [permissionGranted, enabled, authToken]);

  const loadState = useCallback(async () => {
    setLoading(true);
    try {
      const [storedPref, permissions] = await Promise.all([
        AsyncStorage.getItem(NOTIFICATIONS_ENABLED_KEY),
        Notifications.getPermissionsAsync(),
      ]);
      // Do not call requestPermissionsAsync here — avoid the system dialog before sign-in.
      // Users opt in from Profile (toggle) after login.
      await ensureAndroidNotificationChannel();
      const granted =
        permissions.granted ||
        permissions.ios?.status === Notifications.IosAuthorizationStatus.PROVISIONAL;
      const prefEnabled = storedPref !== '0';
      setPermissionGranted(granted);
      setEnabledState(prefEnabled && granted);
      if (storedPref == null) {
        await AsyncStorage.setItem(NOTIFICATIONS_ENABLED_KEY, prefEnabled && granted ? '1' : '0');
      }
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    loadState();
  }, [loadState]);

  useEffect(() => {
    refreshToken();
  }, [refreshToken]);

  useEffect(() => {
    receivedSubscriptionRef.current = Notifications.addNotificationReceivedListener(() => {});
    responseSubscriptionRef.current = Notifications.addNotificationResponseReceivedListener(() => {});

    return () => {
      receivedSubscriptionRef.current?.remove();
      responseSubscriptionRef.current?.remove();
    };
  }, []);

  const setEnabled = useCallback(
    async (next: boolean) => {
      if (!next) {
        setEnabledState(false);
        setExpoPushToken(null);
        await AsyncStorage.setItem(NOTIFICATIONS_ENABLED_KEY, '0');
        return;
      }

      await ensureAndroidNotificationChannel();
      const current = await Notifications.getPermissionsAsync();
      let granted =
        current.granted ||
        current.ios?.status === Notifications.IosAuthorizationStatus.PROVISIONAL;
      if (!granted) {
        const requested = await Notifications.requestPermissionsAsync();
        granted =
          requested.granted ||
          requested.ios?.status === Notifications.IosAuthorizationStatus.PROVISIONAL;
      }

      if (!granted) {
        setEnabledState(false);
        setPermissionGranted(false);
        setExpoPushToken(null);
        await AsyncStorage.setItem(NOTIFICATIONS_PROMPTED_KEY, '1');
        await AsyncStorage.setItem(NOTIFICATIONS_ENABLED_KEY, '0');
        Alert.alert(
          'Permission required',
          'Notifications are blocked. Please allow notifications in device settings.',
        );
        return;
      }

      setPermissionGranted(true);
      setEnabledState(true);
      await AsyncStorage.setItem(NOTIFICATIONS_PROMPTED_KEY, '1');
      await AsyncStorage.setItem(NOTIFICATIONS_ENABLED_KEY, '1');
    },
    [],
  );

  const value = useMemo(
    () => ({
      loading,
      enabled,
      permissionGranted,
      expoPushToken,
      setEnabled,
      refreshToken,
    }),
    [loading, enabled, permissionGranted, expoPushToken, setEnabled, refreshToken],
  );

  return <NotificationContext.Provider value={value}>{children}</NotificationContext.Provider>;
}

export function useNotifications() {
  const ctx = useContext(NotificationContext);
  if (!ctx) throw new Error('useNotifications must be used within NotificationProvider');
  return ctx;
}
