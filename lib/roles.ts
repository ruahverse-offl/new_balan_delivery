/**
 * Delivery APK accepts only DELIVERY_AGENT from GET /auth/me/permissions.
 */

export function normalizeRoleCode(role: string | null | undefined): string {
  return String(role || '').toUpperCase();
}

export function assertDeliveryAgentRole(roleCode: string | null | undefined): string {
  const r = normalizeRoleCode(roleCode);
  if (r !== 'DELIVERY_AGENT') {
    throw new Error(
      'This app is for delivery partners only. Sign in with the delivery account issued by the pharmacy.',
    );
  }
  return r;
}
