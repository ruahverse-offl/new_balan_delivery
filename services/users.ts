import { apiPatch } from '@/lib/api';

export type UpdateMeBody = {
  full_name?: string;
  mobile_number?: string;
  email?: string;
};

export async function updateUserProfile(userId: string, body: UpdateMeBody) {
  return apiPatch<Record<string, unknown>>(`users/${userId}`, body);
}
