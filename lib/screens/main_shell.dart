import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_theme.dart';

/// Broadcasts the active tab index so tab screens can reload on focus,
/// matching React Native's `useFocusEffect` behaviour.
final tabIndexNotifier = ValueNotifier<int>(0);

class MainShell extends StatelessWidget {
  final StatefulNavigationShell shell;

  const MainShell({super.key, required this.shell});

  void _onTap(BuildContext context, int index) {
    tabIndexNotifier.value = index;
    shell.goBranch(
      index,
      initialLocation: index == shell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: shell,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: shell.currentIndex,
        onTap: (i) => _onTap(context, i),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.local_shipping_outlined),
            activeIcon: Icon(Icons.local_shipping),
            label: 'Deliveries',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_outlined),
            activeIcon: Icon(Icons.history),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

/// Bell icon button shown in each tab's AppBar.
class NotificationHeaderButton extends StatelessWidget {
  const NotificationHeaderButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.notifications_none_outlined,
          color: AppColors.gray900),
      tooltip: 'Notifications',
      onPressed: () => context.push('/notifications'),
    );
  }
}
