import 'dart:convert';

class MenuGrants {
  final bool canCreate;
  final bool canRead;
  final bool canUpdate;
  final bool canDelete;

  const MenuGrants({
    required this.canCreate,
    required this.canRead,
    required this.canUpdate,
    required this.canDelete,
  });

  factory MenuGrants.fromJson(Map<String, dynamic> json) => MenuGrants(
        canCreate: (json['canCreate'] ?? json['can_create'] ?? false) as bool,
        canRead: (json['canRead'] ?? json['can_read'] ?? false) as bool,
        canUpdate: (json['canUpdate'] ?? json['can_update'] ?? false) as bool,
        canDelete: (json['canDelete'] ?? json['can_delete'] ?? false) as bool,
      );
}

class MenuItem {
  final String? code;
  final String? displayName;
  final MenuGrants? grants;

  const MenuItem({this.code, this.displayName, this.grants});

  factory MenuItem.fromJson(Map<String, dynamic> json) => MenuItem(
        code: json['code']?.toString(),
        displayName:
            (json['displayName'] ?? json['display_name'])?.toString(),
        grants: json['grants'] != null
            ? MenuGrants.fromJson(json['grants'] as Map<String, dynamic>)
            : null,
      );
}

class AuthUser {
  final String id;
  final String email;
  final String name;
  final String? mobileNumber;

  const AuthUser({
    required this.id,
    required this.email,
    required this.name,
    this.mobileNumber,
  });

  AuthUser copyWith({
    String? id,
    String? email,
    String? name,
    String? mobileNumber,
  }) =>
      AuthUser(
        id: id ?? this.id,
        email: email ?? this.email,
        name: name ?? this.name,
        mobileNumber: mobileNumber ?? this.mobileNumber,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'name': name,
        'full_name': name,
        'mobile_number': mobileNumber,
      };

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
        id: json['id']?.toString() ?? '',
        email: json['email']?.toString() ?? '',
        name: (json['name'] ?? json['full_name'])?.toString() ?? '',
        mobileNumber: json['mobile_number']?.toString(),
      );
}

class LoginResponse {
  final String token;
  final String? refreshToken;
  final AuthUser user;

  const LoginResponse({
    required this.token,
    this.refreshToken,
    required this.user,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) => LoginResponse(
        token: json['token']?.toString() ?? '',
        refreshToken: json['refresh_token']?.toString(),
        user: AuthUser.fromJson(json['user'] as Map<String, dynamic>),
      );
}

class StoredAuth {
  final String token;
  final String? refreshToken;
  final String roleCode;
  final AuthUser user;

  const StoredAuth({
    required this.token,
    this.refreshToken,
    required this.roleCode,
    required this.user,
  });

  String toJsonString() => jsonEncode({
        'token': token,
        'refresh_token': refreshToken,
        'role_code': roleCode,
        'user': user.toJson(),
      });

  factory StoredAuth.fromJsonString(String s) {
    final json = jsonDecode(s) as Map<String, dynamic>;
    return StoredAuth(
      token: json['token']?.toString() ?? '',
      refreshToken: json['refresh_token']?.toString(),
      roleCode: json['role_code']?.toString() ?? '',
      user: AuthUser.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}
