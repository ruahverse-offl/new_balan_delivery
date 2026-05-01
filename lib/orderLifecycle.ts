/**
 * Mirrors `new_balan_fe/src/constants/orderLifecycle.js` + backend `order_lifecycle.py`
 * for delivery-agent transitions only.
 */
import type { MenuItem } from '@/services/auth';

import { hasModuleGrant } from '@/lib/permissions';

export const ORDER_STATUS_LABELS: Record<string, string> = {
  PENDING: 'Payment pending',
  PAYMENT_CANCELLED: 'Payment failed',
  ORDER_RECEIVED: 'Order received (staff)',
  ORDER_TAKEN: 'Order taken',
  ORDER_PROCESSING: 'Processing',
  DELIVERY_ASSIGNED: 'Delivery agent assigned',
  PARCEL_TAKEN: 'Given to delivery agent',
  OUT_FOR_DELIVERY: 'Out for delivery',
  DELIVERED: 'Delivered',
  CANCELLED_BY_STAFF: 'Cancelled by staff',
  DELIVERY_RETURNED: 'Customer refused – returned to store',
  REFUND_INITIATED: 'Refund initiated',
  REFUNDED: 'Refunded',
  CONFIRMED: 'Order received (staff)',
  CANCELLED: 'Cancelled',
  PROCESSING: 'Processing',
  COMPLETED: 'Delivered',
  SHIPPED: 'Out for delivery',
};

/** Short labels for delivery action buttons (aligned with web `FULFILLMENT_CHAIN_BUTTON_LABELS`). */
export const DELIVERY_ACTION_LABELS: Record<string, string> = {
  PARCEL_TAKEN: 'Pick from store',
  OUT_FOR_DELIVERY: 'Out for delivery',
  DELIVERED: 'Mark delivered',
  DELIVERY_RETURNED: 'Return to store',
};

const TERMINAL = new Set([
  'PAYMENT_CANCELLED',
  'DELIVERED',
  'CANCELLED_BY_STAFF',
  'DELIVERY_RETURNED',
  'REFUND_INITIATED',
  'REFUNDED',
  'CANCELLED',
  'COMPLETED',
]);

const DELIVERY_NEXT: Record<string, string[]> = {
  DELIVERY_ASSIGNED: ['PARCEL_TAKEN'],
  PARCEL_TAKEN: ['OUT_FOR_DELIVERY'],
  OUT_FOR_DELIVERY: ['DELIVERED', 'DELIVERY_RETURNED'],
};

export function normalizeOrderStatus(raw: string | null | undefined): string {
  if (raw == null || raw === '') return 'PENDING';
  const r = String(raw).trim().toUpperCase();
  if (r === 'CONFIRMED') return 'ORDER_RECEIVED';
  if (r === 'CANCELLED') return 'CANCELLED_BY_STAFF';
  if (r === 'COMPLETED') return 'DELIVERED';
  if (r === 'SHIPPED') return 'OUT_FOR_DELIVERY';
  if (r === 'PROCESSING') return 'ORDER_PROCESSING';
  return r;
}

export function isTerminalOrderStatus(raw: string | null | undefined): boolean {
  const n = normalizeOrderStatus(raw);
  return TERMINAL.has(n) || TERMINAL.has(String(raw || '').toUpperCase());
}

export function formatOrderStatusLabel(code: string | null | undefined): string {
  if (!code) return '—';
  const u = String(code).toUpperCase();
  return ORDER_STATUS_LABELS[u] || ORDER_STATUS_LABELS[code] || code;
}

export type NextStatusAction = {
  status: string;
  label: string;
  requires: 'return_reason' | 'cancellation_reason' | 'delivery_assigned_user_id' | null;
};

type OrderLike = {
  order_status?: string | null;
  delivery_assigned_user_id?: string | null;
};

/**
 * Allowed PATCH `order_status` targets for the signed-in courier (same rules as web admin).
 */
export function getAllowedNextStatusActions(opts: {
  order: OrderLike;
  menuItems?: MenuItem[];
  userId: string | null | undefined;
  isAdminRole?: boolean;
}): NextStatusAction[] {
  const { order, menuItems = [], userId, isAdminRole = false } = opts;
  const raw = order?.order_status;
  const current = normalizeOrderStatus(raw);
  if (isTerminalOrderStatus(raw)) return [];

  const hasStaff = isAdminRole || hasModuleGrant(menuItems, 'orders', 'update');
  const hasDelivery = hasModuleGrant(menuItems, 'delivery-orders', 'update');
  const assignedId = order?.delivery_assigned_user_id;
  const isAssignedCourier =
    assignedId != null && userId != null && String(assignedId) === String(userId);

  const out: NextStatusAction[] = [];
  const add = (code: string) => {
    if (!out.some((x) => x.status === code)) {
      out.push({
        status: code,
        label: ORDER_STATUS_LABELS[code] || code,
        requires:
          code === 'CANCELLED_BY_STAFF'
            ? 'cancellation_reason'
            : code === 'DELIVERY_RETURNED'
              ? 'return_reason'
              : code === 'DELIVERY_ASSIGNED'
                ? 'delivery_assigned_user_id'
                : null,
      });
    }
  };

  if (hasStaff) {
    /* staff transitions — delivery APK users are agents only; keep empty unless role misconfigured */
    const STAFF_NEXT: Record<string, string[]> = {
      PENDING: ['CANCELLED_BY_STAFF'],
      ORDER_RECEIVED: ['ORDER_TAKEN', 'CANCELLED_BY_STAFF'],
      ORDER_TAKEN: ['ORDER_PROCESSING', 'CANCELLED_BY_STAFF'],
      ORDER_PROCESSING: ['DELIVERY_ASSIGNED', 'CANCELLED_BY_STAFF'],
      DELIVERY_ASSIGNED: ['CANCELLED_BY_STAFF'],
    };
    (STAFF_NEXT[current] || []).forEach(add);
  }
  if (hasDelivery && isAssignedCourier) {
    (DELIVERY_NEXT[current] || []).forEach(add);
  }

  return out;
}

export function actionButtonLabel(action: NextStatusAction): string {
  return DELIVERY_ACTION_LABELS[action.status] || action.label;
}
