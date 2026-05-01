import 'package:flutter/material.dart';

import '../../models/order_models.dart';
import '../../theme/app_theme.dart';
import '../../utils/order_lifecycle.dart';

/// Shared order-list card used in DeliveriesScreen and HistoryScreen.
class OrderCard extends StatelessWidget {
  final OrderRow order;
  final VoidCallback onTap;
  final String tapHint;

  const OrderCard({
    super.key,
    required this.order,
    required this.onTap,
    this.tapHint = 'Open for details →',
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.gray200),
      ),
      elevation: 0,
      color: AppColors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                order.displayRef,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppColors.gray900,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                order.customerName ?? 'Customer',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.gray800,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                order.customerPhone,
                style: const TextStyle(
                  color: AppColors.gray600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                order.deliveryAddress,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.gray700,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                formatOrderStatusLabel(order.orderStatus),
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                order.formatAmount(),
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppColors.secondaryDark,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                tapHint,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
