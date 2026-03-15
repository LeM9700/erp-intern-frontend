import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:erp_frontend/features/dashboard/data/dashboard_repository.dart';
import 'package:erp_frontend/features/dashboard/domain/models/dashboard_model.dart';

final adminDashboardProvider =
    FutureProvider.autoDispose<DashboardKpisModel>((ref) async {
  return ref.read(dashboardRepositoryProvider).getKpis();
});
