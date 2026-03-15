import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:erp_frontend/core/constants/api_constants.dart';
import 'package:erp_frontend/core/network/auth_interceptor.dart';
import 'package:erp_frontend/features/auth/data/auth_local_source.dart';

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(BaseOptions(
    baseUrl: ApiConstants.baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    headers: {
         'Accept': 'application/json',
    },
  ));

  final authLocal = ref.read(authLocalSourceProvider);
  dio.interceptors.add(AuthInterceptor(dio, authLocal));
  dio.interceptors.add(LogInterceptor(
    requestBody: true,
    responseBody: true,
  ));

  return dio;
});
