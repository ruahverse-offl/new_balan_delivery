import type { Href } from 'expo-router';

/** Delivery app route hrefs (expo-router groups omit segment names in URLs). */
export const HREF_DELIVERIES = '/deliveries' as Href;
export const HREF_PROFILE = '/profile' as Href;
export const HREF_NOTIFICATIONS = '/notifications' as Href;
export const HREF_AUTH_LOGIN = '/auth/login' as Href;
export const HREF_ROOT = '/' as Href;

export function hrefOrderDetail(orderId: string): Href {
  return `/order/${orderId}` as Href;
}
