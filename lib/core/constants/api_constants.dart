class ApiConstants {
  static const String baseUrl = 'https://erp-intern-backend-production.up.railway.app/api/v1';

  // Auth
  static const String login = '/auth/login';
  static const String refresh = '/auth/refresh';
  static const String changePassword = '/auth/change-password';

  // Attendance
  static const String clockIn = '/attendance/clock-in';
  static const String clockOut = '/attendance/clock-out';
  static const String attendanceCurrent = '/attendance/current';
  static const String adminLive = '/attendance/admin/live';
  static const String attendanceSummaryMe = '/attendance/summary/me';
  static String attendanceSummaryUser(String userId) => '/attendance/admin/summary/$userId';
  static String adminInternSessions(String userId) =>
      '/attendance/admin/sessions/$userId';
  static String adminInternSessionDetail(String userId, String sessionId) =>
      '/attendance/admin/sessions/$userId/$sessionId';

  // Tasks
  static const String tasks = '/tasks';
  static const String tasksAdmin = '/tasks/admin';
  static const String tasksMe = '/tasks/me';
  static String taskStart(String id) => '/tasks/$id/start';
  static String taskSubmit(String id) => '/tasks/$id/submit';
  static String taskUpdate(String id) => '/tasks/$id';
  static String taskDelete(String id) => '/tasks/$id';
  static String taskComments(String id) => '/tasks/$id/comments';
  static String taskCommentDelete(String id) => '/tasks/comments/$id';
  static const String taskSubmissions = '/tasks/submissions';
  static String taskSubmissionsById(String taskId) => '/tasks/$taskId/submissions';

  // Users
  static const String users = '/users';
  static String userById(String id) => '/users/$id';

  // Files
  static const String filesPresign = '/files/presign';
  static const String filesConfirm = '/files/confirm';

  // Activity
  static const String activityAll = '/activity';
  static const String activityMe = '/activity/me';

  // Notifications
  static const String notifications = '/notifications';
  static String notificationMarkRead(String id) => '/notifications/$id/read';
  static const String notificationsMarkAllRead = '/notifications/read-all';

  // Dashboard
  static const String adminDashboard = '/admin/dashboard';

  // Health
  static const String health = '/health';
}
