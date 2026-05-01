import 'api_client.dart';

/// PATCH /api/v1/users/{userId}
Future<void> updateUserProfile(
  String userId, {
  String? fullName,
  String? email,
  String? mobileNumber,
}) =>
    apiPatch<dynamic>(
      'users/$userId',
      {
        if (fullName != null) 'full_name': fullName,
        if (email != null) 'email': email,
        if (mobileNumber != null) 'mobile_number': mobileNumber,
      },
      fromJson: (d) => d,
    );
