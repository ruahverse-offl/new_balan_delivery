import { apiGet, apiPatch } from '@/lib/api';

export type OrderRow = {
  id: string;
  order_reference?: string | null;
  customer_id?: string | null;
  customer_name?: string | null;
  customer_phone: string;
  delivery_address: string;
  order_status: string;
  final_amount: string | number;
  created_at?: string | null;
  delivery_assigned_user_id?: string | null;
  payment_completed_at?: string | null;
};

export type OrderItemRow = {
  id: string;
  medicine_name?: string | null;
  brand_name?: string | null;
  quantity: number;
  unit_price: string | number;
  total_price: string | number;
  requires_prescription: boolean;
};

export type OrderDetailResponse = {
  order: OrderRow;
  items: OrderItemRow[];
  payment?: { payment_status?: string | null; amount?: string | number | null } | null;
};

export type DeliveryListScope = 'active' | 'history';

/**
 * Assigned orders for the signed-in delivery agent (backend scopes list by
 * `delivery-orders` read/update when the user is not staff-wide).
 *
 * `delivery_list_scope`: `active` = in-progress runs; `history` = delivered or customer refused (returned).
 */
export async function getAssignedOrders(params?: {
  limit?: number;
  offset?: number;
  delivery_list_scope?: DeliveryListScope;
}) {
  return apiGet<{ items: OrderRow[] }>('orders/', {
    limit: params?.limit ?? 50,
    offset: params?.offset ?? 0,
    sort_by: 'created_at',
    sort_order: 'desc',
    delivery_list_scope: params?.delivery_list_scope,
  });
}

/** GET /api/v1/orders/{id}/detail — allowed when the order is assigned to the agent. */
export async function getOrderDetail(orderId: string) {
  return apiGet<OrderDetailResponse>(`orders/${orderId}/detail`);
}

export type OrderPatchBody = {
  order_status?: string;
  return_reason?: string;
};

/** PATCH /api/v1/orders/{id} — lifecycle transitions (delivery agent: `delivery-orders` update). */
export async function updateOrder(orderId: string, body: OrderPatchBody) {
  return apiPatch<OrderRow>(`orders/${orderId}`, body);
}
