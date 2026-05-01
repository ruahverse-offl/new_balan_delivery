import React, { createContext, useCallback, useContext, useEffect, useMemo, useState } from 'react';
import { Alert } from 'react-native';
import AsyncStorage from '@react-native-async-storage/async-storage';

/** Same keys as impl — keeps prefs if user later installs a dev build. */
const NOTIFICATIONS_ENABLED_KEY = 'dp_notifications_enabled';

type NotificationContextValue = {
  loading: boolean;
  enabled: boolean;
  permissionGranted: boolean;
  expoPushToken: string | null;
  setEnabled: (next: boolean) => Promise<void>;
  refreshToken: () => Promise<void>;
};

const NotificationContext = createContext<NotificationContextValue | null>(null);

const EXPO_GO_ANDROID_PUSH_MSG =
  'Remote push notifications are not available in Expo Go on Android (SDK 53+). Use a development build to test push: npx expo run:android or EAS Build.';

export function NotificationProvider({ children }: { children: React.ReactNode }) {
  const [loading, setLoading] = useState(true);
  const [enabled, setEnabledState] = useState(false);

  const loadState = useCallback(async () => {
    setLoading(true);
    try {
      const storedPref = await AsyncStorage.getItem(NOTIFICATIONS_ENABLED_KEY);
      const prefEnabled = storedPref !== '0';
      setEnabledState(prefEnabled);
      if (storedPref == null) {
        await AsyncStorage.setItem(NOTIFICATIONS_ENABLED_KEY, '0');
      }
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    void loadState();
  }, [loadState]);

  const refreshToken = useCallback(async () => {
    /* no token in Expo Go Android */
  }, []);

  const setEnabled = useCallback(async (next: boolean) => {
    if (!next) {
      setEnabledState(false);
      await AsyncStorage.setItem(NOTIFICATIONS_ENABLED_KEY, '0');
      return;
    }
    /** Do not persist "on": Expo Go cannot obtain a push token — use a dev APK on the emulator. */
    Alert.alert(
      'Development build required',
      `${EXPO_GO_ANDROID_PUSH_MSG}\n\nFrom project folder: npm run android\n(or install an EAS internal APK on this emulator).`,
      [{ text: 'OK' }],
    );
  }, []);

  const value = useMemo(
    () => ({
      loading,
      enabled,
      permissionGranted: false,
      expoPushToken: null,
      setEnabled,
      refreshToken,
    }),
    [loading, enabled, setEnabled, refreshToken],
  );

  return <NotificationContext.Provider value={value}>{children}</NotificationContext.Provider>;
}

export function useNotifications() {
  const ctx = useContext(NotificationContext);
  if (!ctx) throw new Error('useNotifications must be used within NotificationProvider');
  return ctx;
}
