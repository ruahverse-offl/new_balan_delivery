import React, { createContext, useCallback, useContext, useEffect, useMemo, useState } from 'react';
import {
  getUserPermissions,
  login as loginApi,
  logoutApi,
  type LoginResponse,
  type MenuItem,
} from '@/services/auth';
import { getStoredAuth, setStoredAuth, StoredAuth } from '@/lib/api';
import { revokePushRegistrationOnServer, syncPushRegistrationWithServer } from '@/lib/pushDeviceSync';
import { assertDeliveryAgentRole, normalizeRoleCode } from '@/lib/roles';

export type AuthUser = {
  id: string;
  email: string;
  name: string;
  mobile_number?: string | null;
};

type AuthContextValue = {
  user: AuthUser | null;
  token: string | null;
  isAuthenticated: boolean;
  roleCode: string | null;
  menuItems: MenuItem[];
  loading: boolean;
  login: (email: string, password: string) => Promise<void>;
  logout: () => Promise<void>;
  updateLocalUser: (updates: Partial<Pick<AuthUser, 'name' | 'email' | 'mobile_number'>>) => Promise<void>;
};

const AuthContext = createContext<AuthContextValue | null>(null);

async function persistSession(
  data: LoginResponse,
  perm: { roleCode: string | null; menuItems: MenuItem[] },
  assertedRole: string,
) {
  const u: AuthUser = {
    id: String(data.user.id),
    email: data.user.email,
    name: data.user.full_name,
    mobile_number: data.user.mobile_number ?? null,
  };
  const stored: StoredAuth = {
    token: data.token,
    refresh_token: data.refresh_token,
    role_code: assertedRole,
    user: {
      id: u.id,
      email: u.email,
      name: u.name,
      full_name: data.user.full_name,
      mobile_number: u.mobile_number ?? undefined,
    },
  };
  await setStoredAuth(stored);
  return { user: u, roleCode: assertedRole, menuItems: perm.menuItems };
}

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [user, setUser] = useState<AuthUser | null>(null);
  const [token, setToken] = useState<string | null>(null);
  const [roleCode, setRoleCode] = useState<string | null>(null);
  const [menuItems, setMenuItems] = useState<MenuItem[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    (async () => {
      try {
        const s = await getStoredAuth();
        if (!s?.token) {
          setLoading(false);
          return;
        }
        const perm = await getUserPermissions(s.token);
        const rc = normalizeRoleCode(perm.roleCode ?? (s.role_code as string | undefined));
        if (rc !== 'DELIVERY_AGENT') {
          await setStoredAuth(null);
          setLoading(false);
          return;
        }
        assertDeliveryAgentRole(perm.roleCode);
        setToken(s.token);
        setRoleCode(rc);
        setMenuItems(perm.menuItems || []);
        if (s.user) {
          setUser({
            id: String(s.user.id ?? ''),
            email: s.user.email ?? '',
            name: s.user.name ?? s.user.full_name ?? '',
            mobile_number: s.user.mobile_number ?? null,
          });
        }
        void syncPushRegistrationWithServer();
      } catch {
        await setStoredAuth(null);
        setToken(null);
        setUser(null);
        setRoleCode(null);
        setMenuItems([]);
      } finally {
        setLoading(false);
      }
    })();
  }, []);

  const login = useCallback(async (email: string, password: string) => {
    const data: LoginResponse = await loginApi(email, password);
    const perm = await getUserPermissions(data.token);
    const asserted = assertDeliveryAgentRole(perm.roleCode);
    const { user: nextUser, roleCode: nextRole, menuItems: menus } = await persistSession(data, perm, asserted);
    setToken(data.token);
    setUser(nextUser);
    setRoleCode(nextRole);
    setMenuItems(menus);
    void syncPushRegistrationWithServer();
  }, []);

  const logout = useCallback(async () => {
    const t = token;
    await revokePushRegistrationOnServer();
    await logoutApi(t);
    await setStoredAuth(null);
    setToken(null);
    setUser(null);
    setRoleCode(null);
    setMenuItems([]);
  }, [token]);

  const updateLocalUser = useCallback(
    async (updates: Partial<Pick<AuthUser, 'name' | 'email' | 'mobile_number'>>) => {
      setUser((prev) => {
        if (!prev) return prev;
        return { ...prev, ...updates };
      });
      const s = await getStoredAuth();
      if (!s?.token || !s.user) return;
      const nextName = updates.name ?? s.user.name ?? s.user.full_name ?? '';
      const nextEmail = updates.email ?? s.user.email ?? '';
      const nextMobile = updates.mobile_number ?? s.user.mobile_number;
      const stored: StoredAuth = {
        ...s,
        user: {
          ...s.user,
          name: nextName,
          full_name: nextName,
          email: nextEmail,
          mobile_number: nextMobile ?? undefined,
        },
      };
      await setStoredAuth(stored);
    },
    [],
  );

  const value = useMemo(
    () => ({
      user,
      token,
      isAuthenticated: Boolean(user && token),
      roleCode,
      menuItems,
      loading,
      login,
      logout,
      updateLocalUser,
    }),
    [user, token, roleCode, menuItems, loading, login, logout, updateLocalUser],
  );

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuth() {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error('useAuth must be used within AuthProvider');
  return ctx;
}
