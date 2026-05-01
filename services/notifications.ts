import { apiGet } from '@/lib/api';

export type MyNotificationItem = {
  id: string;
  title: string;
  body?: string | null;
  send_status: string;
  channel: string;
  created_at: string;
  sent_at?: string | null;
};

/** GET /api/v1/me/notifications — latest 30 rows for the signed-in user. */
export async function getMyNotifications() {
  return apiGet<{ items: MyNotificationItem[] }>('me/notifications');
}
