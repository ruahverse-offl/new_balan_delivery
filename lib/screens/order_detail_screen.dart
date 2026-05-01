import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/order_models.dart';
import '../providers/auth_provider.dart';
import '../services/orders_service.dart';
import '../theme/app_theme.dart';
import '../utils/order_lifecycle.dart';

class OrderDetailScreen extends StatefulWidget {
  final String orderId;
  const OrderDetailScreen({super.key, required this.orderId});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  OrderDetailResponse? _detail;
  bool _loading = true;
  bool _busy = false;
  String? _error;

  // Return modal
  bool _returnModalOpen = false;
  NextStatusAction? _returnAction;
  final _returnReasonCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _returnReasonCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (widget.orderId.isEmpty) return;
    setState(() { _error = null; _loading = true; });
    try {
      final d = await getOrderDetail(widget.orderId);
      if (mounted) setState(() => _detail = d);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _detail = null;
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<NextStatusAction> _actions() {
    if (_detail == null) return [];
    final auth = context.read<AuthProvider>();
    return getAllowedNextStatusActions(
      orderStatus: _detail!.order.orderStatus,
      deliveryAssignedUserId: _detail!.order.deliveryAssignedUserId,
      menuItems: auth.menuItems,
      userId: auth.user?.id,
    );
  }

  Future<void> _onAction(NextStatusAction act) async {
    if (_detail == null) return;
    if (act.requires == NextStatusRequires.returnReason) {
      _returnReasonCtrl.clear();
      setState(() { _returnAction = act; _returnModalOpen = true; });
      return;
    }
    // Confirm dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Update status'),
        content: Text(
            'Set order to ${formatOrderStatusLabel(act.status)}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Confirm')),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    setState(() => _busy = true);
    try {
      final updated = await updateOrder(widget.orderId,
          orderStatus: act.status);
      if (mounted) {
        setState(() {
          _detail = OrderDetailResponse(
            order: updated,
            items: _detail!.items,
          );
        });
        _showAlert('Done', 'Order status was updated.');
      }
    } catch (e) {
      if (mounted) {
        _showAlert('Could not update',
            e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirmReturn() async {
    if (_returnAction == null) return;
    final reason = _returnReasonCtrl.text.trim();
    if (reason.isEmpty) {
      _showAlert('Reason required',
          'Please enter why the delivery could not be completed.');
      return;
    }
    setState(() { _busy = true; _returnModalOpen = false; });
    try {
      final updated = await updateOrder(widget.orderId,
          orderStatus: _returnAction!.status, returnReason: reason);
      if (mounted) {
        setState(() {
          _detail = OrderDetailResponse(
            order: updated,
            items: _detail!.items,
          );
          _returnAction = null;
        });
        _showAlert('Done', 'Order marked as returned to store.');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _returnModalOpen = true);
        _showAlert('Could not update',
            e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showAlert(String title, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.orderId.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Order')),
        body: const Center(child: Text('Invalid order.')),
      );
    }

    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Order')),
        body: const Center(
            child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    if (_error != null || _detail == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Order')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const SizedBox(height: 40),
              Text(_error ?? 'Order not found.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.gray600,fontSize: 16)),
              const SizedBox(height: 20),
              _outlineButton('Back to deliveries',
                  () => context.go('/deliveries')),
            ],
          ),
        ),
      );
    }

    final order = _detail!.order;
    final actions = _actions();

    return Scaffold(
      appBar: AppBar(title: Text(order.displayRef)),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),

                // Title + status
                Text(
                  order.displayRef,
                  style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppColors.gray900),
                ),
                const SizedBox(height: 4),
                Text(
                  formatOrderStatusLabel(order.orderStatus),
                  style: const TextStyle(
                      fontSize: 14, color: AppColors.gray600, height: 1.4),
                ),
                const SizedBox(height: 16),

                // Customer + address + amount
                _card(children: [
                  _labelText('Customer'),
                  _bodyBold(order.customerName ?? '—'),
                  _bodySub(order.customerPhone),
                  const SizedBox(height: 12),
                  _labelText('Address'),
                  _bodyBold(order.deliveryAddress),
                  const SizedBox(height: 12),
                  _labelText('Amount'),
                  Text(
                    order.formatAmount(),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.secondaryDark,
                    ),
                  ),
                ]),

                // Actions
                if (actions.isNotEmpty) ...[
                  _labelText('Your actions'),
                  _card(children: [
                    for (final act in actions)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed:
                                _busy ? null : () => _onAction(act),
                            child: Text(actionButtonLabel(act),
                                style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16)),
                          ),
                        ),
                      ),
                  ]),
                ] else
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      'No actions available for this status, or this order is not assigned to you.',
                      style: TextStyle(
                          color: AppColors.gray600.withOpacity(0.9),
                          fontSize: 13),
                    ),
                  ),

                // Items
                _labelText('Items'),
                _card(children: [
                  if (_detail!.items.isEmpty)
                    const Text('No line items.',
                        style:
                            TextStyle(color: AppColors.gray600, fontSize: 13))
                  else
                    for (final line in _detail!.items)
                      _lineItemRow(line),
                ]),

                // Close button
                _outlineButton('Close', () => context.pop()),
              ],
            ),
          ),

          // Return-to-store modal (bottom sheet style)
          if (_returnModalOpen) _returnModal(),
        ],
      ),
    );
  }

  Widget _returnModal() {
    return GestureDetector(
      onTap: () {
        if (!_busy) setState(() => _returnModalOpen = false);
      },
      child: Container(
        color: const Color(0x660F172A),
        alignment: Alignment.bottomCenter,
        child: GestureDetector(
          onTap: () {}, // prevent dismiss when tapping inside
          child: Container(
            decoration: const BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Return to store',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.gray900)),
                const SizedBox(height: 8),
                const Text('Brief reason (shown to pharmacy staff).',
                    style:
                        TextStyle(fontSize: 14, color: AppColors.gray600)),
                const SizedBox(height: 12),
                TextField(
                  controller: _returnReasonCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                      hintText: 'e.g. Customer not available'),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _busy
                            ? null
                            : () => setState(
                                () => _returnModalOpen = false),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: AppColors.gray300),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Cancel',
                            style: TextStyle(
                                color: AppColors.gray800,
                                fontWeight: FontWeight.w700)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _busy ? null : _confirmReturn,
                        child: _busy
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.white))
                            : const Text('Submit',
                                style: TextStyle(
                                    fontWeight: FontWeight.w800)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────

  Widget _card({required List<Widget> children}) => Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.gray200),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children),
      );

  Widget _labelText(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 4, top: 2),
        child: Text(t.toUpperCase(),
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppColors.gray500,
                letterSpacing: 0.5)),
      );

  Widget _bodyBold(String t) => Text(t,
      style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.gray900));

  Widget _bodySub(String t) => Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(t,
            style: const TextStyle(
                fontSize: 14, color: AppColors.gray600)),
      );

  Widget _lineItemRow(OrderItemRow line) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              [line.medicineName ?? 'Item', if (line.brandName != null) '· ${line.brandName}']
                  .join(' '),
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.gray900),
            ),
            const SizedBox(height: 4),
            Text(
              '×${line.quantity} · ${line.formatTotalPrice()}',
              style: const TextStyle(
                  fontSize: 14, color: AppColors.gray600),
            ),
            const Divider(height: 16),
          ],
        ),
      );

  Widget _outlineButton(String label, VoidCallback onTap) => Padding(
        padding: const EdgeInsets.only(top: 8),
        child: SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: _busy ? null : onTap,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: const BorderSide(color: AppColors.gray300),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(label,
                style: const TextStyle(
                    color: AppColors.gray800,
                    fontWeight: FontWeight.w700)),
          ),
        ),
      );
}
