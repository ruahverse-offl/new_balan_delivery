import * as SecureStore from 'expo-secure-store';
import { Platform } from 'react-native';

import { buildApiUrl } from './config';

/** Separate from customer app `nb_auth` so both APKs can be installed side by side. */
const AUTH_KEY = 'nb_delivery_auth';

export type StoredAuth = {
  token: string;
  refresh_token?: string;
  role_code?: string | null;
  user?: {
    id?: string;
    email?: string;
    name?: string;
    full_name?: string;
    mobile_number?: string | null;
  };
};

async function readAuthRaw(): Promise<string | null> {
  if (Platform.OS === 'web') {
    try {
      return typeof globalThis !== 'undefined' && 'localStorage' in globalThis
        ? (globalThis as unknown as { localStorage: Storage }).localStorage.getItem(AUTH_KEY)
        : null;
    } catch {
      return null;
    }
  }
  return SecureStore.getItemAsync(AUTH_KEY);
}

async function writeAuthRaw(value: string): Promise<void> {
  if (Platform.OS === 'web') {
    (globalThis as unknown as { localStorage: Storage }).localStorage.setItem(AUTH_KEY, value);
    return;
  }
  await SecureStore.setItemAsync(AUTH_KEY, value, {
    keychainAccessible: SecureStore.AFTER_FIRST_UNLOCK_THIS_DEVICE_ONLY,
  });
}

async function removeAuthRaw(): Promise<void> {
  if (Platform.OS === 'web') {
    try {
      (globalThis as unknown as { localStorage: Storage }).localStorage.removeItem(AUTH_KEY);
    } catch {
      /* ignore */
    }
    return;
  }
  try {
    await SecureStore.deleteItemAsync(AUTH_KEY);
  } catch {
    /* ignore */
  }
}

export async function getStoredAuth(): Promise<StoredAuth | null> {
  try {
    const raw = await readAuthRaw();
    if (!raw) return null;
    return JSON.parse(raw) as StoredAuth;
  } catch {
    return null;
  }
}

export async function setStoredAuth(auth: StoredAuth | null): Promise<void> {
  if (!auth) {
    await removeAuthRaw();
    return;
  }
  await writeAuthRaw(JSON.stringify(auth));
}

export function formatApiErrorDetail(detail: unknown): string {
  if (detail == null || detail === '') return 'Request failed';
  if (typeof detail === 'string') return detail;
  if (Array.isArray(detail)) {
    const parts = detail
      .map((d) => {
        if (typeof d === 'string') return d;
        if (d && typeof d === 'object' && 'msg' in d && typeof (d as { msg: string }).msg === 'string') {
          return (d as { msg: string }).msg;
        }
        return null;
      })
      .filter(Boolean) as string[];
    if (parts.length) return parts.join(' ');
  }
  if (typeof detail === 'object' && detail !== null && 'msg' in detail) {
    return String((detail as { msg: string }).msg);
  }
  try {
    return JSON.stringify(detail);
  } catch {
    return 'Request failed';
  }
}

type RequestOptions = RequestInit & { timeoutMs?: number };

export async function apiRequest(path: string, options: RequestOptions = {}): Promise<Response> {
  const auth = await getStoredAuth();
  const token = auth?.token;
  const headers: Record<string, string> = {
    'Content-Type': 'application/json',
    ...(options.headers as Record<string, string> | undefined),
  };
  if (token && token !== 'admin-token') {
    headers.Authorization = `Bearer ${token}`;
  }

  const timeoutMs = options.timeoutMs ?? 30000;
  const controller = new AbortController();
  const id = setTimeout(() => controller.abort(), timeoutMs);

  try {
    const url = buildApiUrl(path);
    return await fetch(url, {
      ...options,
      headers,
      signal: controller.signal,
    });
  } finally {
    clearTimeout(id);
  }
}

export async function apiGet<T>(path: string, params: Record<string, string | number | boolean | undefined> = {}): Promise<T> {
  const qs = new URLSearchParams();
  Object.entries(params).forEach(([k, v]) => {
    if (v !== null && v !== undefined && v !== '') qs.set(k, String(v));
  });
  const q = qs.toString();
  const url = q ? `${path}?${q}` : path;
  const res = await apiRequest(url, { method: 'GET' });
  if (!res.ok) {
    const body = await res.json().catch(() => ({ detail: 'Request failed' }));
    const msg = formatApiErrorDetail(body.detail) || body.message || 'Request failed';
    const err = new Error(msg) as Error & { status?: number };
    err.status = res.status;
    throw err;
  }
  return res.json() as Promise<T>;
}

export async function apiPost<T>(path: string, data: unknown): Promise<T> {
  const res = await apiRequest(path, { method: 'POST', body: JSON.stringify(data) });
  if (!res.ok) {
    const body = await res.json().catch(() => ({ detail: 'Request failed' }));
    const msg = formatApiErrorDetail(body.detail) || body.message || 'Request failed';
    const err = new Error(msg) as Error & { status?: number };
    err.status = res.status;
    throw err;
  }
  return res.json() as Promise<T>;
}

export async function apiPatch<T>(path: string, data: unknown): Promise<T> {
  const res = await apiRequest(path, { method: 'PATCH', body: JSON.stringify(data) });
  if (!res.ok) {
    const body = await res.json().catch(() => ({ detail: 'Request failed' }));
    const msg = formatApiErrorDetail(body.detail) || body.message || 'Request failed';
    const err = new Error(msg) as Error & { status?: number };
    err.status = res.status;
    throw err;
  }
  return res.json() as Promise<T>;
}
