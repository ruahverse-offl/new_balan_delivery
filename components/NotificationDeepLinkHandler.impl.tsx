import { useEffect } from 'react';
import * as Notifications from 'expo-notifications';
import { useRouter } from 'expo-router';

/**
 * Opens the in-app notifications list when the user taps a push notification.
 */
export function NotificationDeepLinkHandlerImpl() {
  const router = useRouter();

  useEffect(() => {
    const sub = Notifications.addNotificationResponseReceivedListener((response) => {
      const data = response.notification.request.content.data as Record<string, unknown> | undefined;
      const screen = data && typeof data.screen === 'string' ? data.screen : null;
      if (screen === 'order' && data && typeof data.orderId === 'string') {
        router.push(`/order/${data.orderId}`);
        return;
      }
      router.push('/notifications');
    });
    return () => sub.remove();
  }, [router]);

  return null;
}
