import { Platform } from 'react-native';
import { isRunningInExpoGo } from 'expo';

/**
 * SDK 53+: `expo-notifications` remote push is not supported in Android Expo Go.
 * Importing the package runs side effects that surface as console errors in dev.
 * Use a development build (`npx expo run:android` or EAS Build) for real push.
 */
export function shouldUseNotificationsStub(): boolean {
  return Platform.OS === 'android' && isRunningInExpoGo();
}
