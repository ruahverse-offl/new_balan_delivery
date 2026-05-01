/// Mirrors lib/orderLifecycle.ts from the React Native app.
/// Delivery-agent transitions only.
import '../models/auth_models.dart';
import 'permissions.dart';

const Map<String, String> orderStatusLabels = {
  'PENDING': 'Payment pending',
  'PAYMENT_CANCELLED': 'Payment failed',
  'ORDER_RECEIVED': 'Order received (staff)',
  'ORDER_TAKEN': 'Order taken',
  'ORDER_PROCESSING': 'Processing',
  'DELIVERY_ASSIGNED': 'Delivery agent assigned',
  'PARCEL_TAKEN': 'Given to delivery agent',
  'OUT_FOR_DELIVERY': 'Out for delivery',
  'DELIVERED': 'Delivered',
  'CANCELLED_BY_STAFF': 'Cancelled by staff',
  'DELIVERY_RETURNED': 'Customer refused – returned to store',
  'REFUND_INITIATED': 'Refund initiated',
  'REFUNDED': 'Refunded',
  'CONFIRMED': 'Order received (staff)',
  'CANCELLED': 'Cancelled',
  'PROCESSING': 'Processing',
  'COMPLETED': 'Delivered',
  'SHIPPED': 'Out for delivery',
};

const Map<String, String> deliveryActionLabels = {
  'PARCEL_TAKEN': 'Pick from store',
  'OUT_FOR_DELIVERY': 'Out for delivery',
  'DELIVERED': 'Mark delivered',
  'DELIVERY_RETURNED': 'Return to store',
};

const Set<String> _terminal = {
  'PAYMENT_CANCELLED',
  'DELIVERED',
  'CANCELLED_BY_STAFF',
  'DELIVERY_RETURNED',
  'REFUND_INITIATED',
  'REFUNDED',
  'CANCELLED',
  'COMPLETED',
};

const Map<String, List<String>> _deliveryNext = {
  'DELIVERY_ASSIGNED': ['PARCEL_TAKEN'],
  'PARCEL_TAKEN': ['OUT_FOR_DELIVERY'],
  'OUT_FOR_DELIVERY': ['DELIVERED', 'DELIVERY_RETURNED'],
};

String normalizeOrderStatus(String? raw) {
  if (raw == null || raw.isEmpty) return 'PENDING';
  final r = raw.trim().toUpperCase();
  if (r == 'CONFIRMED') return 'ORDER_RECEIVED';
  if (r == 'CANCELLED') return 'CANCELLED_BY_STAFF';
  if (r == 'COMPLETED') return 'DELIVERED';
  if (r == 'SHIPPED') return 'OUT_FOR_DELIVERY';
  if (r == 'PROCESSING') return 'ORDER_PROCESSING';
  return r;
}

bool isTerminalOrderStatus(String? raw) {
  final n = normalizeOrderStatus(raw);
  return _terminal.contains(n) ||
      _terminal.contains((raw ?? '').toUpperCase());
}

String formatOrderStatusLabel(String? code) {
  if (code == null || code.isEmpty) return '—';
  final u = code.toUpperCase();
  return orderStatusLabels[u] ?? orderStatusLabels[code] ?? code;
}

enum NextStatusRequires {
  none,
  returnReason,
  cancellationReason,
  deliveryAssignedUserId,
}

class NextStatusAction {
  final String status;
  final String label;
  final NextStatusRequires requires;

  const NextStatusAction({
    required this.status,
    required this.label,
    required this.requires,
  });
}

NextStatusRequires _requiresFor(String code) {
  if (code == 'CANCELLED_BY_STAFF') return NextStatusRequires.cancellationReason;
  if (code == 'DELIVERY_RETURNED') return NextStatusRequires.returnReason;
  if (code == 'DELIVERY_ASSIGNED') return NextStatusRequires.deliveryAssignedUserId;
  return NextStatusRequires.none;
}

List<NextStatusAction> getAllowedNextStatusActions({
  required String? orderStatus,
  required String? deliveryAssignedUserId,
  required List<MenuItem> menuItems,
  required String? userId,
  bool isAdminRole = false,
}) {
  if (isTerminalOrderStatus(orderStatus)) return [];
  final current = normalizeOrderStatus(orderStatus);

  final hasStaff =
      isAdminRole || hasModuleGrant(menuItems, 'orders', 'update');
  final hasDelivery = hasModuleGrant(menuItems, 'delivery-orders', 'update');
  final isAssignedCourier = deliveryAssignedUserId != null &&
      userId != null &&
      deliveryAssignedUserId == userId;

  final out = <NextStatusAction>[];
  void add(String code) {
    if (out.any((x) => x.status == code)) return;
    out.add(NextStatusAction(
      status: code,
      label: orderStatusLabels[code] ?? code,
      requires: _requiresFor(code),
    ));
  }

  if (hasStaff) {
    const staffNext = {
      'PENDING': ['CANCELLED_BY_STAFF'],
      'ORDER_RECEIVED': ['ORDER_TAKEN', 'CANCELLED_BY_STAFF'],
      'ORDER_TAKEN': ['ORDER_PROCESSING', 'CANCELLED_BY_STAFF'],
      'ORDER_PROCESSING': ['DELIVERY_ASSIGNED', 'CANCELLED_BY_STAFF'],
      'DELIVERY_ASSIGNED': ['CANCELLED_BY_STAFF'],
    };
    for (final code in staffNext[current] ?? []) {
      add(code);
    }
  }
  if (hasDelivery && isAssignedCourier) {
    for (final code in _deliveryNext[current] ?? []) {
      add(code);
    }
  }

  return out;
}

String actionButtonLabel(NextStatusAction action) =>
    deliveryActionLabels[action.status] ?? action.label;
