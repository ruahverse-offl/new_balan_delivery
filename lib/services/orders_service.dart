import '../models/order_models.dart';
import 'api_client.dart';

/// GET /api/v1/orders/
/// scope: 'active' = in-progress; 'history' = delivered or returned.
Future<List<OrderRow>> getAssignedOrders({
  int limit = 50,
  int offset = 0,
  String deliveryListScope = 'active',
}) async {
  final data = await apiGet<Map<String, dynamic>>(
    'orders/',
    params: {
      'limit': limit,
      'offset': offset,
      'sort_by': 'created_at',
      'sort_order': 'desc',
      'delivery_list_scope': deliveryListScope,
    },
    fromJson: (d) => d as Map<String, dynamic>,
  );
  final items = data['items'] as List<dynamic>? ?? [];
  return items
      .map((e) => OrderRow.fromJson(e as Map<String, dynamic>))
      .toList();
}

/// GET /api/v1/orders/{id}/detail
Future<OrderDetailResponse> getOrderDetail(String orderId) =>
    apiGet<OrderDetailResponse>(
      'orders/$orderId/detail',
      fromJson: (d) =>
          OrderDetailResponse.fromJson(d as Map<String, dynamic>),
    );

/// PATCH /api/v1/orders/{id}
Future<OrderRow> updateOrder(
  String orderId, {
  String? orderStatus,
  String? returnReason,
}) =>
    apiPatch<OrderRow>(
      'orders/$orderId',
      {
        if (orderStatus != null) 'order_status': orderStatus,
        if (returnReason != null) 'return_reason': returnReason,
      },
      fromJson: (d) => OrderRow.fromJson(d as Map<String, dynamic>),
    );
