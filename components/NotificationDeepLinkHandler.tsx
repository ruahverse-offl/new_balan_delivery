import React from 'react';

import { shouldUseNotificationsStub } from '@/lib/notificationGate';

/**
 * Opens `/notifications` (or an order) when the user taps a push. Not used in Android Expo Go
 * because `expo-notifications` is not loaded there.
 */
export function NotificationDeepLinkHandler() {
  if (shouldUseNotificationsStub()) {
    return null;
  }
  const { NotificationDeepLinkHandlerImpl } = require('./NotificationDeepLinkHandler.impl') as typeof import('./NotificationDeepLinkHandler.impl');
  return <NotificationDeepLinkHandlerImpl />;
}
