class OrderRow {
  final String id;
  final String? orderReference;
  final String? customerId;
  final String? customerName;
  final String customerPhone;
  final String deliveryAddress;
  final String orderStatus;
  final dynamic finalAmount; // String or num from API
  final String? createdAt;
  final String? deliveryAssignedUserId;
  final String? paymentCompletedAt;

  const OrderRow({
    required this.id,
    this.orderReference,
    this.customerId,
    this.customerName,
    required this.customerPhone,
    required this.deliveryAddress,
    required this.orderStatus,
    required this.finalAmount,
    this.createdAt,
    this.deliveryAssignedUserId,
    this.paymentCompletedAt,
  });

  factory OrderRow.fromJson(Map<String, dynamic> json) => OrderRow(
        id: json['id']?.toString() ?? '',
        orderReference: json['order_reference']?.toString(),
        customerId: json['customer_id']?.toString(),
        customerName: json['customer_name']?.toString(),
        customerPhone: json['customer_phone']?.toString() ?? '',
        deliveryAddress: json['delivery_address']?.toString() ?? '',
        orderStatus: json['order_status']?.toString() ?? '',
        finalAmount: json['final_amount'],
        createdAt: json['created_at']?.toString(),
        deliveryAssignedUserId:
            json['delivery_assigned_user_id']?.toString(),
        paymentCompletedAt: json['payment_completed_at']?.toString(),
      );

  OrderRow copyWithStatus(String newStatus) => OrderRow(
        id: id,
        orderReference: orderReference,
        customerId: customerId,
        customerName: customerName,
        customerPhone: customerPhone,
        deliveryAddress: deliveryAddress,
        orderStatus: newStatus,
        finalAmount: finalAmount,
        createdAt: createdAt,
        deliveryAssignedUserId: deliveryAssignedUserId,
        paymentCompletedAt: paymentCompletedAt,
      );

  String get displayRef => (orderReference ?? '').trim().isEmpty ? id : orderReference!.trim();

  String formatAmount() {
    final raw = finalAmount;
    double? n;
    if (raw is num) {
      n = raw.toDouble();
    } else if (raw is String) {
      n = double.tryParse(raw);
    }
    if (n == null) return raw?.toString() ?? '—';
    return '₹${n.toStringAsFixed(0)}';
  }
}

class OrderItemRow {
  final String id;
  final String? medicineName;
  final String? brandName;
  final int quantity;
  final dynamic unitPrice;
  final dynamic totalPrice;
  final bool requiresPrescription;

  const OrderItemRow({
    required this.id,
    this.medicineName,
    this.brandName,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    required this.requiresPrescription,
  });

  factory OrderItemRow.fromJson(Map<String, dynamic> json) => OrderItemRow(
        id: json['id']?.toString() ?? '',
        medicineName: json['medicine_name']?.toString(),
        brandName: json['brand_name']?.toString(),
        quantity: (json['quantity'] as num?)?.toInt() ?? 0,
        unitPrice: json['unit_price'],
        totalPrice: json['total_price'],
        requiresPrescription:
            json['requires_prescription'] as bool? ?? false,
      );

  String formatTotalPrice() {
    final raw = totalPrice;
    double? n;
    if (raw is num) {
      n = raw.toDouble();
    } else if (raw is String) {
      n = double.tryParse(raw);
    }
    if (n == null) return raw?.toString() ?? '—';
    return '₹${n.toStringAsFixed(0)}';
  }
}

class OrderDetailResponse {
  final OrderRow order;
  final List<OrderItemRow> items;

  const OrderDetailResponse({required this.order, required this.items});

  factory OrderDetailResponse.fromJson(Map<String, dynamic> json) =>
      OrderDetailResponse(
        order: OrderRow.fromJson(json['order'] as Map<String, dynamic>),
        items: (json['items'] as List<dynamic>?)
                ?.map((e) =>
                    OrderItemRow.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
      );

  OrderDetailResponse copyWithOrderStatus(String newStatus) =>
      OrderDetailResponse(
        order: order.copyWithStatus(newStatus),
        items: items,
      );
}
