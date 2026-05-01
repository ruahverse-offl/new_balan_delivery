import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'theme/app_theme.dart';
import 'screens/login_screen.dart';
import 'screens/main_shell.dart';
import 'screens/deliveries_screen.dart';
import 'screens/history_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/order_detail_screen.dart';
import 'screens/notifications_screen.dart';

class NewBalanDeliveryApp extends StatefulWidget {
  const NewBalanDeliveryApp({super.key});

  @override
  State<NewBalanDeliveryApp> createState() => _NewBalanDeliveryAppState();
}

class _NewBalanDeliveryAppState extends State<NewBalanDeliveryApp> {
  GoRouter? _router;
  bool _routerInitialized = false;

  // Build the router exactly once, capturing the AuthProvider instance.
  // go_router re-evaluates redirect() via refreshListenable whenever
  // AuthProvider notifies — no need to recreate the router on auth changes.
  GoRouter _initRouter(AuthProvider auth) => GoRouter(
        refreshListenable: auth,
        initialLocation: '/deliveries',
        redirect: (context, state) {
          final loading = auth.isLoading;
          final loggedIn = auth.isAuthenticated;
          final goingToLogin = state.matchedLocation == '/login';

          if (loading) return null;
          if (!loggedIn && !goingToLogin) return '/login';
          if (loggedIn && goingToLogin) return '/deliveries';
          return null;
        },
        routes: [
          GoRoute(
            path: '/login',
            pageBuilder: (ctx, state) =>
                const NoTransitionPage(child: LoginScreen()),
          ),
          StatefulShellRoute.indexedStack(
            builder: (ctx, state, shell) => MainShell(shell: shell),
            branches: [
              StatefulShellBranch(routes: [
                GoRoute(
                  path: '/deliveries',
                  pageBuilder: (ctx, state) =>
                      const NoTransitionPage(child: DeliveriesScreen()),
                ),
              ]),
              StatefulShellBranch(routes: [
                GoRoute(
                  path: '/history',
                  pageBuilder: (ctx, state) =>
                      const NoTransitionPage(child: HistoryScreen()),
                ),
              ]),
              StatefulShellBranch(routes: [
                GoRoute(
                  path: '/profile',
                  pageBuilder: (ctx, state) =>
                      const NoTransitionPage(child: ProfileScreen()),
                ),
              ]),
            ],
          ),
          GoRoute(
            path: '/order/:id',
            builder: (ctx, state) => OrderDetailScreen(
                orderId: state.pathParameters['id'] ?? ''),
          ),
          GoRoute(
            path: '/notifications',
            builder: (ctx, state) => const NotificationsScreen(),
          ),
        ],
      );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_routerInitialized) {
      _routerInitialized = true;
      _router = _initRouter(context.read<AuthProvider>());
    }
  }

  @override
  void dispose() {
    _router?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Watch so the widget rebuilds (e.g. theme changes), but the router
    // itself re-evaluates redirects via its own refreshListenable.
    context.watch<AuthProvider>();
    return MaterialApp.router(
      title: 'New Balan Delivery',
      theme: AppTheme.theme,
      routerConfig: _router!,
      debugShowCheckedModeBanner: false,
    );
  }
}
