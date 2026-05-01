import { buildApiUrl } from '@/lib/config';

export type LoginResponse = {
  token: string;
  refresh_token?: string;
  token_type?: string;
  user: {
    id: string;
    email: string;
    full_name: string;
    role_id?: string;
    mobile_number?: string | null;
  };
};

export type MenuGrants = {
  canCreate?: boolean;
  canRead?: boolean;
  canUpdate?: boolean;
  canDelete?: boolean;
  can_create?: boolean;
  can_read?: boolean;
  can_update?: boolean;
  can_delete?: boolean;
};

export type MenuItem = {
  code?: string;
  displayName?: string;
  display_name?: string;
  displayOrder?: number;
  display_order?: number;
  iconKey?: string;
  icon_key?: string;
  grants?: MenuGrants | null;
};

export type PermissionsPayload = {
  roleCode: string | null;
  roleDisplayName: string | null;
  roleDescription: string | null;
  menuItems: MenuItem[];
};

function normalizeMenuGrants(g: unknown): MenuGrants | null {
  if (!g || typeof g !== 'object') return null;
  const o = g as Record<string, unknown>;
  const canCreate = Boolean(o.canCreate ?? o.can_create);
  const canRead = Boolean(o.canRead ?? o.can_read);
  const canUpdate = Boolean(o.canUpdate ?? o.can_update);
  const canDelete = Boolean(o.canDelete ?? o.can_delete);
  return {
    canCreate,
    canRead,
    canUpdate,
    canDelete,
    can_create: canCreate,
    can_read: canRead,
    can_update: canUpdate,
    can_delete: canDelete,
  };
}

function normalizeMenuItem(m: unknown): MenuItem {
  if (!m || typeof m !== 'object') return {};
  const row = m as Record<string, unknown>;
  const displayName = (row.displayName ?? row.display_name) as string | undefined;
  const grants = normalizeMenuGrants(row.grants);
  const base: MenuItem = {
    code: row.code as string | undefined,
    displayName,
    display_name: displayName,
    displayOrder: (row.displayOrder ?? row.display_order) as number | undefined,
    display_order: (row.display_order ?? row.displayOrder) as number | undefined,
    iconKey: (row.iconKey ?? row.icon_key) as string | undefined,
    icon_key: (row.icon_key ?? row.iconKey) as string | undefined,
  };
  return grants ? { ...base, grants } : base;
}

function normalizePermissionsPayload(data: unknown): PermissionsPayload {
  const d = (data && typeof data === 'object' ? data : {}) as Record<string, unknown>;
  const raw = d.menuItems ?? d.menu_items;
  const menuItems = Array.isArray(raw) ? raw.map(normalizeMenuItem) : [];
  const roleCode = (d.roleCode ?? d.role_code ?? null) as string | null;
  const roleDisplayName = (d.roleDisplayName ?? d.role_display_name ?? null) as string | null;
  const roleDescription = (d.roleDescription ?? d.role_description ?? null) as string | null;
  return {
    roleCode: roleCode != null ? String(roleCode) : null,
    roleDisplayName: roleDisplayName != null ? String(roleDisplayName) : null,
    roleDescription: roleDescription != null ? String(roleDescription) : null,
    menuItems,
  };
}

export async function login(email: string, password: string): Promise<LoginResponse> {
  const res = await fetch(buildApiUrl('auth/login'), {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email, password }),
  });
  const data = await res.json();
  if (!res.ok) {
    throw new Error(data.detail || data.message || 'Login failed');
  }
  return data as LoginResponse;
}

export async function getUserPermissions(token: string): Promise<PermissionsPayload> {
  const res = await fetch(buildApiUrl('auth/me/permissions'), {
    method: 'GET',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${token}`,
    },
  });
  const data = await res.json();
  if (!res.ok) {
    throw new Error(data.detail || data.message || 'Failed to fetch permissions');
  }
  return normalizePermissionsPayload(data);
}

export async function verifyCurrentPassword(email: string, password: string): Promise<void> {
  const res = await fetch(buildApiUrl('auth/login'), {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email, password }),
  });
  const data = await res.json().catch(() => ({}));
  if (!res.ok) {
    const d = data as { detail?: string; message?: string };
    throw new Error(d.detail || d.message || 'Incorrect password');
  }
}

export async function changePassword(
  token: string,
  current_password: string,
  new_password: string,
): Promise<void> {
  const res = await fetch(buildApiUrl('auth/change-password'), {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${token}`,
    },
    body: JSON.stringify({ current_password, new_password }),
  });
  const data = await res.json().catch(() => ({}));
  if (!res.ok) {
    throw new Error((data as { detail?: string }).detail || 'Password change failed');
  }
}

export async function logoutApi(token: string | null | undefined): Promise<void> {
  if (!token) return;
  try {
    await fetch(buildApiUrl('auth/logout'), {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${token}`,
      },
    });
  } catch {
    /* best-effort */
  }
}
