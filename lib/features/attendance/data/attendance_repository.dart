import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:erp_frontend/core/constants/api_constants.dart';
import 'package:erp_frontend/core/network/dio_client.dart';
import 'package:erp_frontend/features/attendance/domain/models/attendance_model.dart';

final attendanceRepositoryProvider = Provider<AttendanceRepository>((ref) {
  return AttendanceRepository(ref.read(dioProvider));
});

class AttendanceRepository {
  final Dio _dio;

  AttendanceRepository(this._dio);

  /// Renvoie la session ouverte de l'utilisateur courant, ou null.
  Future<AttendanceSessionModel?> getCurrentSession() async {
    final response = await _dio.get(ApiConstants.attendanceCurrent);
    if (response.data == null || (response.data is String && response.data == 'null')) {
      return null;
    }
    return AttendanceSessionModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<AttendanceSessionModel> clockIn(XFile photo) async {
    final bytes = await photo.readAsBytes();
    final formData = FormData.fromMap({
      'photo': MultipartFile.fromBytes(bytes, filename: photo.name),
    });
    final response = await _dio.post(ApiConstants.clockIn, data: formData);
    return AttendanceSessionModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<AttendanceSessionModel> clockOut(String note) async {
    final response = await _dio.post(ApiConstants.clockOut, data: {'note': note});
    return AttendanceSessionModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<LiveAttendanceModel>> getLiveSessions() async {
    final response = await _dio.get(ApiConstants.adminLive);
    final list = response.data as List<dynamic>;
    return list
        .map((e) => LiveAttendanceModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<AttendanceSummaryModel> getMySummary() async {
    final response = await _dio.get(ApiConstants.attendanceSummaryMe);
    return AttendanceSummaryModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<AttendanceSummaryModel> getUserSummary(String userId) async {
    final response = await _dio.get(ApiConstants.attendanceSummaryUser(userId));
    return AttendanceSummaryModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<AdminAttendanceSessionListModel> getInternSessions(
    String userId, {
    int page = 1,
    int size = 20,
    DateTime? dateFrom,
    DateTime? dateTo,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'size': size,
      if (dateFrom != null) 'date_from': dateFrom.toIso8601String(),
      if (dateTo != null) 'date_to': dateTo.toIso8601String(),
    };
    final response = await _dio.get(
      ApiConstants.adminInternSessions(userId),
      queryParameters: queryParams,
    );
    return AdminAttendanceSessionListModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<AdminAttendanceSessionModel> getInternSessionDetail(
    String userId,
    String sessionId,
  ) async {
    final response = await _dio.get(
      ApiConstants.adminInternSessionDetail(userId, sessionId),
    );
    return AdminAttendanceSessionModel.fromJson(response.data as Map<String, dynamic>);
  }
}
