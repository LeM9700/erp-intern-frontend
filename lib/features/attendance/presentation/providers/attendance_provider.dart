import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:erp_frontend/features/attendance/data/attendance_repository.dart';
import 'package:erp_frontend/features/attendance/domain/models/attendance_model.dart';

// ── Current open session (intern) ──
final currentSessionProvider =
    FutureProvider.autoDispose<AttendanceSessionModel?>((ref) async {
  return ref.read(attendanceRepositoryProvider).getCurrentSession();
});

// ── Live attendance (admin) ──
final liveAttendanceProvider =
    FutureProvider.autoDispose<List<LiveAttendanceModel>>((ref) async {
  return ref.read(attendanceRepositoryProvider).getLiveSessions();
});

// ── Summary ──
final myAttendanceSummaryProvider =
    FutureProvider.autoDispose<AttendanceSummaryModel>((ref) async {
  return ref.read(attendanceRepositoryProvider).getMySummary();
});

// ── Attendance actions ──
class AttendanceActionsNotifier
    extends Notifier<AsyncValue<AttendanceSessionModel?>> {
  @override
  AsyncValue<AttendanceSessionModel?> build() => const AsyncValue.data(null);

  Future<void> clockIn(XFile photo) async {
    state = const AsyncValue.loading();
    try {
      final session =
          await ref.read(attendanceRepositoryProvider).clockIn(photo);
      ref.invalidate(liveAttendanceProvider);
      ref.invalidate(myAttendanceSummaryProvider);
      ref.invalidate(currentSessionProvider);
      state = AsyncValue.data(session);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> clockOut(String note) async {
    state = const AsyncValue.loading();
    try {
      final session = await ref
          .read(attendanceRepositoryProvider)
          .clockOut(note);
      ref.invalidate(liveAttendanceProvider);
      ref.invalidate(myAttendanceSummaryProvider);
      ref.invalidate(currentSessionProvider);
      state = AsyncValue.data(session);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final attendanceActionsProvider = NotifierProvider<AttendanceActionsNotifier,
    AsyncValue<AttendanceSessionModel?>>(AttendanceActionsNotifier.new);

// ── Admin: intern session list ──
final internSessionsProvider = FutureProvider.autoDispose
    .family<AdminAttendanceSessionListModel, String>((ref, userId) {
  return ref.read(attendanceRepositoryProvider).getInternSessions(userId);
});

// ── Admin: intern session detail ──
final internSessionDetailProvider = FutureProvider.autoDispose
    .family<AdminAttendanceSessionModel, (String, String)>((ref, args) {
  return ref
      .read(attendanceRepositoryProvider)
      .getInternSessionDetail(args.$1, args.$2);
});
