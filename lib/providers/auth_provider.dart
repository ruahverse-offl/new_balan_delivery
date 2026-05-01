import 'package:flutter/foundation.dart';
import '../models/auth_models.dart';
import '../services/api_client.dart' show setGlobalToken, onUnauthorized;
import '../services/auth_service.dart' as authSvc;
import '../utils/secure_storage.dart';

enum AuthState { loading, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  AuthUser? _user;
  String? _token;
  String? _roleCode;
  List<MenuItem> _menuItems = [];
  AuthState _state = AuthState.loading;

  AuthUser? get user => _user;
  String? get token => _token;
  String? get roleCode => _roleCode;
  List<MenuItem> get menuItems => _menuItems;
  bool get isLoading => _state == AuthState.loading;
  bool get isAuthenticated => _state == AuthState.authenticated;

  AuthProvider() {
    // Auto-logout when any API call gets a 401 (expired/revoked token).
    onUnauthorized = () => _clear();
    _restore();
  }

  Future<void> _restore() async {
    try {
      final stored = await getStoredAuth();
      if (stored == null || stored.token.isEmpty) {
        _state = AuthState.unauthenticated;
        notifyListeners();
        return;
      }

      final perm = await authSvc.getUserPermissions(stored.token);
      final rc = _normalizeRoleCode(perm.roleCode);
      if (rc != 'DELIVERY_AGENT') {
        await setStoredAuth(null);
        _state = AuthState.unauthenticated;
        notifyListeners();
        return;
      }

      _apply(
        token: stored.token,
        user: stored.user,
        roleCode: rc,
        menuItems: perm.menuItems,
      );
    } catch (_) {
      await setStoredAuth(null);
      _state = AuthState.unauthenticated;
      notifyListeners();
    }
  }

  Future<void> login(String email, String password) async {
    final resp = await authSvc.login(email, password);
    final perm = await authSvc.getUserPermissions(resp.token);
    final rc = _normalizeRoleCode(perm.roleCode);
    if (rc != 'DELIVERY_AGENT') {
      throw Exception(
          'Access denied. This app is for delivery partners only.');
    }

    final stored = StoredAuth(
      token: resp.token,
      refreshToken: resp.refreshToken,
      roleCode: rc,
      user: resp.user,
    );
    await setStoredAuth(stored);
    _apply(
      token: resp.token,
      user: resp.user,
      roleCode: rc,
      menuItems: perm.menuItems,
    );
  }

  Future<void> logout() async {
    final t = _token;
    // Revoke push registration before clearing token (see NotificationProvider).
    await authSvc.logoutApi(t);
    await setStoredAuth(null);
    _clear();
  }

  Future<void> updateLocalUser({
    String? name,
    String? email,
    String? mobileNumber,
  }) async {
    if (_user == null) return;
    final updated = _user!.copyWith(
      name: name,
      email: email,
      mobileNumber: mobileNumber,
    );
    _user = updated;
    notifyListeners();

    final stored = await getStoredAuth();
    if (stored != null) {
      await setStoredAuth(StoredAuth(
        token: stored.token,
        refreshToken: stored.refreshToken,
        roleCode: stored.roleCode,
        user: updated,
      ));
    }
  }

  void _apply({
    required String token,
    required AuthUser user,
    required String roleCode,
    required List<MenuItem> menuItems,
  }) {
    _token = token;
    _user = user;
    _roleCode = roleCode;
    _menuItems = menuItems;
    _state = AuthState.authenticated;
    setGlobalToken(token);
    notifyListeners();
  }

  void _clear() {
    _token = null;
    _user = null;
    _roleCode = null;
    _menuItems = [];
    _state = AuthState.unauthenticated;
    setGlobalToken(null);
    notifyListeners();
  }

  String _normalizeRoleCode(String? raw) {
    if (raw == null) return '';
    return raw.trim().toUpperCase().replaceAll(' ', '_');
  }
}
