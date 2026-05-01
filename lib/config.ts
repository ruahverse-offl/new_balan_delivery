import Constants from 'expo-constants';
import { Platform } from 'react-native';

type ApiExtra = { apiOrigin?: string; apiPrefix?: string };

function readExtra(): ApiExtra {
  return (Constants.expoConfig?.extra ?? {}) as ApiExtra;
}

function readApiOrigin(): string {
  const extra = readExtra();
  if (extra.apiOrigin?.trim()) {
    return extra.apiOrigin.replace(/\/$/, '');
  }
  const fromPublic = process.env.EXPO_PUBLIC_API_ORIGIN || process.env.EXPO_PUBLIC_ENVIRONMENT;
  if (typeof fromPublic === 'string' && fromPublic.trim()) {
    return fromPublic.trim().replace(/\/$/, '');
  }
  return 'http://127.0.0.1:8000';
}

const _resolvedOrigin = readApiOrigin();
if (
  Platform.OS !== 'web' &&
  /^(https?:\/\/)?(127\.0\.0\.1|localhost)(:\d+)?\/?$/i.test(_resolvedOrigin.replace(/\/$/, ''))
) {
  console.warn(
    '[API] Base URL points to this machine (127.0.0.1/localhost). Physical devices cannot reach it. ' +
      'Set EXPO_PUBLIC_API_ORIGIN to your backend, e.g. http://192.168.1.10:8000, and rebuild the APK.',
  );
}

export const API_ORIGIN = _resolvedOrigin;

const prefixRaw = readExtra().apiPrefix ?? process.env.EXPO_PUBLIC_API_PREFIX ?? '/api/v1';
const prefix = prefixRaw.startsWith('/') ? prefixRaw : `/${prefixRaw}`;

export function buildApiUrl(path: string): string {
  const p = path.startsWith('/') ? path.slice(1) : path;
  return `${API_ORIGIN}${prefix}/${p}`;
}
