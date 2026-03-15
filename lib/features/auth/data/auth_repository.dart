import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:erp_frontend/core/constants/api_constants.dart';
import 'package:erp_frontend/core/network/dio_client.dart';
import 'package:erp_frontend/features/auth/domain/models/token_response.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.read(dioProvider));
});

class AuthRepository {
  final Dio _dio;

  AuthRepository(this._dio);

  Future<TokenResponse> login(String email, String password) async {
    final response = await _dio.post(
      ApiConstants.login,
      data: {'email': email, 'password': password},
    );
    return TokenResponse.fromJson(response.data as Map<String, dynamic>);
  }

  Future<TokenResponse> refresh(String refreshToken) async {
    final response = await _dio.post(
      ApiConstants.refresh,
      data: {'refresh_token': refreshToken},
    );
    return TokenResponse.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> changePassword(String currentPassword, String newPassword) async {
    await _dio.put(
      ApiConstants.changePassword,
      data: {
        'current_password': currentPassword,
        'new_password': newPassword,
      },
    );
  }
}
