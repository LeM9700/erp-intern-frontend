import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:erp_frontend/core/constants/api_constants.dart';
import 'package:erp_frontend/core/network/dio_client.dart';
import 'package:erp_frontend/features/notifications/domain/models/notification_model.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository(ref.read(dioProvider));
});

class NotificationRepository {
  final Dio _dio;

  NotificationRepository(this._dio);

  Future<List<NotificationModel>> getNotifications() async {
    final response = await _dio.get(ApiConstants.notifications);
    final data = response.data;
    final list = data is List ? data : (data['items'] as List<dynamic>);
    return list
        .map((e) => NotificationModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<NotificationModel> markAsRead(String id) async {
    final response = await _dio.patch(ApiConstants.notificationMarkRead(id));
    return NotificationModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<int> markAllAsRead() async {
    final response = await _dio.patch(ApiConstants.notificationsMarkAllRead);
    return (response.data as Map<String, dynamic>)['marked_as_read'] as int;
  }
}
