import AsyncStorage from '@react-native-async-storage/async-storage';

const KEY = 'dp_installation_id';

/** Stable per-install id for ``device_id`` on notification registration (not hardware id). */
export async function getOrCreateInstallationId(): Promise<string> {
  const existing = await AsyncStorage.getItem(KEY);
  if (existing) return existing;
  const id = `dp-${Date.now().toString(36)}-${Math.random().toString(36).slice(2, 12)}`;
  await AsyncStorage.setItem(KEY, id);
  return id;
}
