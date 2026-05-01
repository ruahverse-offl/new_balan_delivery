import '../models/auth_models.dart';
import 'api_client.dart';

/// POST /api/v1/auth/login
Future<LoginResponse> login(String email, String password) =>
    apiPost<LoginResponse>(
      'auth/login',
      {'email': email, 'password': password},
      fromJson: (data) =>
          LoginResponse.fromJson(data as Map<String, dynamic>),
    );

/// GET /api/v1/auth/me/permissions
Future<({String? roleCode, List<MenuItem> menuItems})> getUserPermissions(
  String token,
) async {
  final data = await apiGetWithToken<Map<String, dynamic>>(
    'auth/me/permissions',
    token,
    fromJson: (d) => d as Map<String, dynamic>,
  );
  final rawMenuItems = data['menuItems'] ?? data['menu_items'];
  final menuItems = rawMenuItems is List
      ? rawMenuItems
          .map((e) => MenuItem.fromJson(e as Map<String, dynamic>))
          .toList()
      : <MenuItem>[];
  final roleCode =
      (data['roleCode'] ?? data['role_code'])?.toString();
  return (roleCode: roleCode, menuItems: menuItems);
}

/// Verify password by re-logging in (same pattern as the React Native app).
Future<void> verifyCurrentPassword(String email, String password) =>
    apiPost<dynamic>(
      'auth/login',
      {'email': email, 'password': password},
      fromJson: (d) => d,
    );

/// POST /api/v1/auth/change-password
Future<void> changePassword(
  String token,
  String currentPassword,
  String newPassword,
) =>
    apiPost<dynamic>(
      'auth/change-password',
      {
        'current_password': currentPassword,
        'new_password': newPassword,
      },
      fromJson: (d) => d,
      explicitToken: token,
    );

/// POST /api/v1/auth/logout – best-effort.
Future<void> logoutApi(String? token) async {
  if (token == null) return;
  await apiPostBestEffort('auth/logout', token: token);
}
