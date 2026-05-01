import { shouldUseNotificationsStub } from '@/lib/notificationGate';

/**
 * Avoid loading `expo-notifications` in Android Expo Go (SDK 53+), which triggers noisy errors.
 * Dev / production builds use the full implementation.
 */
const impl = shouldUseNotificationsStub()
  ? require('./NotificationContext.stub')
  : require('./NotificationContext.impl');

export const NotificationProvider = impl.NotificationProvider;
export const useNotifications = impl.useNotifications;
