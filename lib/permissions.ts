import type { MenuItem } from '@/services/auth';

export function getModuleGrants(menuItems: MenuItem[] | undefined, moduleCode: string) {
  if (!Array.isArray(menuItems) || !moduleCode) return null;
  const m = menuItems.find((x) => x && String(x.code) === String(moduleCode));
  return m?.grants ?? null;
}

export function hasModuleGrant(
  menuItems: MenuItem[] | undefined,
  moduleCode: string,
  action: 'create' | 'read' | 'update' | 'delete',
): boolean {
  const g = getModuleGrants(menuItems, moduleCode);
  if (!g) return false;
  const c = g.canCreate ?? g.can_create;
  const r = g.canRead ?? g.can_read;
  const u = g.canUpdate ?? g.can_update;
  const d = g.canDelete ?? g.can_delete;
  if (action === 'create') return Boolean(c);
  if (action === 'read') return Boolean(r);
  if (action === 'update') return Boolean(u);
  if (action === 'delete') return Boolean(d);
  return false;
}
