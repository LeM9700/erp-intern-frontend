import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:erp_frontend/core/constants/api_constants.dart';
import 'package:erp_frontend/core/network/dio_client.dart';
import 'package:erp_frontend/features/auth/domain/models/user_model.dart';

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository(ref.read(dioProvider));
});

class UserRepository {
  final Dio _dio;

  UserRepository(this._dio);

  /// List all users (admin only). Optional role filter.
  Future<({List<UserModel> users, int total})> getUsers({
    String? role,
    int skip = 0,
    int limit = 50,
  }) async {
    final queryParams = <String, dynamic>{
      'skip': skip,
      'limit': limit,
    };
    if (role != null) queryParams['role'] = role;

    final response = await _dio.get(
      ApiConstants.users,
      queryParameters: queryParams,
    );
    final data = response.data as Map<String, dynamic>;
    final users = (data['users'] as List<dynamic>)
        .map((e) => UserModel.fromJson(e as Map<String, dynamic>))
        .toList();
    final total = data['total'] as int;
    return (users: users, total: total);
  }

  /// Create a new user (admin only).
  Future<UserModel> createUser({
    required String email,
    required String password,
    required String fullName,
    String role = 'INTERN',
  }) async {
    final response = await _dio.post(
      ApiConstants.users,
      data: {
        'email': email,
        'password': password,
        'full_name': fullName,
        'role': role,
      },
    );
    return UserModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// Update a user (admin only).
  Future<UserModel> updateUser(
    String userId, {
    String? fullName,
    String? email,
    bool? isActive,
  }) async {
    final data = <String, dynamic>{};
    if (fullName != null) data['full_name'] = fullName;
    if (email != null) data['email'] = email;
    if (isActive != null) data['is_active'] = isActive;

    final response = await _dio.patch(
      ApiConstants.userById(userId),
      data: data,
    );
    return UserModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// Deactivate a user (admin only).
  Future<UserModel> deactivateUser(String userId) async {
    final response = await _dio.delete(ApiConstants.userById(userId));
    return UserModel.fromJson(response.data as Map<String, dynamic>);
  }
}
