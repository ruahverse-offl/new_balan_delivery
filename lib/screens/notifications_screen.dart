import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/notification_models.dart';
import '../providers/auth_provider.dart';
import '../services/notifications_service.dart';
import '../theme/app_theme.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<MyNotificationItem> _items = [];
  bool _loading = true;
  bool _refreshing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated) return;
    setState(() => _error = null);
    try {
      final items = await getMyNotifications();
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
        title: const Text('Notifications'),
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
                      padding:
                          const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      itemCount: _items.length + 1,
                      itemBuilder: (ctx, i) {
                        if (i == 0) return _buildHeader();
                        return _NotificationCard(item: _items[i - 1]);
                      },
                    ),
            ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Showing your latest 30 notifications.',
            style: Theme.of(context)
                .textTheme
                .bodySmall!
                .copyWith(color: AppColors.gray600, fontSize: 14),
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
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        _buildHeader(),
        const SizedBox(height: 60),
        Center(
          child: Text(
            _error == null
                ? 'No notifications yet.\nPull to refresh.'
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

class _NotificationCard extends StatelessWidget {
  final MyNotificationItem item;
  const _NotificationCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gray100),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.gray900,
            ),
          ),
          if (item.body != null && item.body!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              item.body!,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.gray700,
                height: 1.4,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            [
              if (item.displayTime != null) item.displayTime!,
              if (item.sendStatus.isNotEmpty) item.sendStatus,
            ].join(' · '),
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.gray500,
            ),
          ),
        ],
      ),
    );
  }
}
