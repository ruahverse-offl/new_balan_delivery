import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/order_models.dart';
import '../providers/auth_provider.dart';
import '../services/orders_service.dart';
import '../theme/app_theme.dart';
import 'main_shell.dart';
import 'widgets/order_card.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  static const _tabIndex = 1;

  List<OrderRow> _items = [];
  bool _loading = true;
  bool _refreshing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Reload every time this tab gains focus — matches useFocusEffect in RN.
    tabIndexNotifier.addListener(_onTabChange);
    _load();
  }

  @override
  void dispose() {
    tabIndexNotifier.removeListener(_onTabChange);
    super.dispose();
  }

  void _onTabChange() {
    if (tabIndexNotifier.value == _tabIndex && !_loading) {
      _load();
    }
  }

  Future<void> _load() async {
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated) return;
    setState(() { _loading = true; _error = null; });
    try {
      final items = await getAssignedOrders(deliveryListScope: 'history');
      if (mounted) setState(() => _items = items);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _items = [];
        });
      }
    } finally {
      if (mounted) setState(() { _loading = false; _refreshing = false; });
    }
  }

  Future<void> _onRefresh() async {
    setState(() => _refreshing = true);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        actions: const [NotificationHeaderButton()],
      ),
      body: _loading && !_refreshing
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              color: AppColors.primary,
              onRefresh: _onRefresh,
              child: _items.isEmpty
                  ? _buildEmpty()
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      itemCount: _items.length + 1,
                      itemBuilder: (ctx, i) {
                        if (i == 0) return _buildHeader();
                        return OrderCard(
                          order: _items[i - 1],
                          tapHint: 'Open for details →',
                          onTap: () =>
                              ctx.push('/order/${_items[i - 1].id}'),
                        );
                      },
                    ),
            ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'History',
            style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                  color: AppColors.gray900,
                  fontWeight: FontWeight.w800,
                  fontSize: 24,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'Delivered orders and returns when the customer did not accept.',
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
                  color: AppColors.gray600,
                  fontSize: 14,
                  height: 1.4,
                ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!,
                style: const TextStyle(
                    color: AppColors.gray500, fontSize: 13)),
          ],
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      children: [
        _buildHeader(),
        const SizedBox(height: 60),
        Center(
          child: Text(
            _error == null
                ? 'No completed deliveries yet.\nPull to refresh.'
                : _error!,
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: AppColors.gray600, fontSize: 16, height: 1.5),
          ),
        ),
      ],
    );
  }
}
