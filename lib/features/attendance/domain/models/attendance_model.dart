enum AttendanceStatus {
  open('OPEN'),
  closed('CLOSED');

  final String value;
  const AttendanceStatus(this.value);

  static AttendanceStatus fromString(String s) {
    return AttendanceStatus.values.firstWhere(
      (e) => e.value == s.toUpperCase(),
      orElse: () => AttendanceStatus.open,
    );
  }
}

class AttendanceSessionModel {
  final String id;
  final String userId;
  final AttendanceStatus status;
  final String clockInPhotoId;
  final String? clockOutPhotoId;
  final DateTime? endedAt;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? note;

  const AttendanceSessionModel({
    required this.id,
    required this.userId,
    required this.status,
    required this.clockInPhotoId,
    this.clockOutPhotoId,
    this.endedAt,
    required this.createdAt,
    this.updatedAt,
    this.note,
  });

  factory AttendanceSessionModel.fromJson(Map<String, dynamic> json) {
    return AttendanceSessionModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      status: AttendanceStatus.fromString(json['status'] as String),
      clockInPhotoId: json['clock_in_photo_id'] as String,
      clockOutPhotoId: json['clock_out_photo_id'] as String?,
      endedAt: json['ended_at'] != null
          ? DateTime.parse(json['ended_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      note: json['note'] as String?,
    );
  }

  bool get isOpen => status == AttendanceStatus.open;
}

class LiveAttendanceModel {
  final String id;
  final String userId;
  final String userFullName;
  final String clockInPhotoId;
  final AttendanceStatus status;
  final DateTime createdAt;

  const LiveAttendanceModel({
    required this.id,
    required this.userId,
    required this.userFullName,
    required this.clockInPhotoId,
    required this.status,
    required this.createdAt,
  });

  factory LiveAttendanceModel.fromJson(Map<String, dynamic> json) {
    return LiveAttendanceModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      userFullName: json['user_full_name'] as String,
      clockInPhotoId: json['clock_in_photo_id'] as String,
      status: AttendanceStatus.fromString(json['status'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

class AttendanceSummarySessionItem {
  final String id;
  final DateTime clockIn;
  final DateTime clockOut;
  final double durationMinutes;
  final String? note;

  const AttendanceSummarySessionItem({
    required this.id,
    required this.clockIn,
    required this.clockOut,
    required this.durationMinutes,
    this.note,
  });

  factory AttendanceSummarySessionItem.fromJson(Map<String, dynamic> json) {
    return AttendanceSummarySessionItem(
      id: json['id'] as String,
      clockIn: DateTime.parse(json['clock_in'] as String),
      clockOut: DateTime.parse(json['clock_out'] as String),
      durationMinutes: (json['duration_minutes'] as num).toDouble(),
      note: json['note'] as String?,
    );
  }

  String get durationLabel {
    final h = (durationMinutes / 60).floor();
    final m = (durationMinutes % 60).round();
    return h > 0 ? '${h}h${m.toString().padLeft(2, '0')}' : '${m}min';
  }
}

class AttendanceSummaryModel {
  final String userId;
  final double totalHours;
  final int totalSessions;
  final List<AttendanceSummarySessionItem> sessions;

  const AttendanceSummaryModel({
    required this.userId,
    required this.totalHours,
    required this.totalSessions,
    required this.sessions,
  });

  factory AttendanceSummaryModel.fromJson(Map<String, dynamic> json) {
    return AttendanceSummaryModel(
      userId: json['user_id'] as String,
      totalHours: (json['total_hours'] as num).toDouble(),
      totalSessions: json['total_sessions'] as int,
      sessions: (json['sessions'] as List<dynamic>)
          .map((e) => AttendanceSummarySessionItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
