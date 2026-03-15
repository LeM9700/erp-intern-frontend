import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:erp_frontend/core/constants/api_constants.dart';
import 'package:erp_frontend/core/network/dio_client.dart';
import 'package:erp_frontend/features/dashboard/domain/models/dashboard_model.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepository(ref.read(dioProvider));
});

class DashboardRepository {
  final Dio _dio;
  DashboardRepository(this._dio);

  Future<DashboardKpisModel> getKpis() async {
    final response = await _dio.get(ApiConstants.adminDashboard);
    return DashboardKpisModel.fromJson(response.data as Map<String, dynamic>);
  }
}
