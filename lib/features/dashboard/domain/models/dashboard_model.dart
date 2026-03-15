class InternSummaryModel {
  final String userId;
  final String fullName;
  final String email;
  final double hoursThisWeek;
  final double hoursThisMonth;
  final bool isCurrentlyClockedIn;
  final int tasksPending;
  final int tasksInProgress;
  final int tasksSubmitted;
  final int tasksApproved;
  final int tasksRejected;

  const InternSummaryModel({
    required this.userId,
    required this.fullName,
    required this.email,
    required this.hoursThisWeek,
    required this.hoursThisMonth,
    required this.isCurrentlyClockedIn,
    required this.tasksPending,
    required this.tasksInProgress,
    required this.tasksSubmitted,
    required this.tasksApproved,
    required this.tasksRejected,
  });

  factory InternSummaryModel.fromJson(Map<String, dynamic> json) {
    return InternSummaryModel(
      userId: json['user_id'] as String,
      fullName: json['full_name'] as String,
      email: json['email'] as String,
      hoursThisWeek: (json['hours_this_week'] as num).toDouble(),
      hoursThisMonth: (json['hours_this_month'] as num).toDouble(),
      isCurrentlyClockedIn: json['is_currently_clocked_in'] as bool,
      tasksPending: json['tasks_pending'] as int,
      tasksInProgress: json['tasks_in_progress'] as int,
      tasksSubmitted: json['tasks_submitted'] as int,
      tasksApproved: json['tasks_approved'] as int,
      tasksRejected: json['tasks_rejected'] as int,
    );
  }
}

class DashboardKpisModel {
  final int totalInterns;
  final int activeInterns;
  final int liveSessionsCount;
  final double totalHoursThisWeek;
  final double totalHoursThisMonth;
  final int tasksPending;
  final int tasksInProgress;
  final int tasksSubmitted;
  final int tasksApproved;
  final int tasksRejected;
  final List<InternSummaryModel> interns;

  const DashboardKpisModel({
    required this.totalInterns,
    required this.activeInterns,
    required this.liveSessionsCount,
    required this.totalHoursThisWeek,
    required this.totalHoursThisMonth,
    required this.tasksPending,
    required this.tasksInProgress,
    required this.tasksSubmitted,
    required this.tasksApproved,
    required this.tasksRejected,
    required this.interns,
  });

  factory DashboardKpisModel.fromJson(Map<String, dynamic> json) {
    return DashboardKpisModel(
      totalInterns: json['total_interns'] as int,
      activeInterns: json['active_interns'] as int,
      liveSessionsCount: json['live_sessions_count'] as int,
      totalHoursThisWeek: (json['total_hours_this_week'] as num).toDouble(),
      totalHoursThisMonth: (json['total_hours_this_month'] as num).toDouble(),
      tasksPending: json['tasks_pending'] as int,
      tasksInProgress: json['tasks_in_progress'] as int,
      tasksSubmitted: json['tasks_submitted'] as int,
      tasksApproved: json['tasks_approved'] as int,
      tasksRejected: json['tasks_rejected'] as int,
      interns: (json['interns'] as List<dynamic>)
          .map((e) => InternSummaryModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
