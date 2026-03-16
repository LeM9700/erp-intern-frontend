import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:erp_frontend/features/tasks/data/task_repository.dart';
import 'package:erp_frontend/features/tasks/domain/models/task_model.dart';

// ── Admin tasks ──
final adminTasksProvider =
    FutureProvider.autoDispose<List<TaskModel>>((ref) async {
  final repo = ref.read(taskRepositoryProvider);
  return repo.getAdminTasks();
});

// ── Intern tasks ──
final internTasksProvider =
    FutureProvider.autoDispose<List<TaskModel>>((ref) async {
  final repo = ref.read(taskRepositoryProvider);
  return repo.getMyTasks();
});

// ── Task actions notifier ──
class TaskActionsNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  Future<void> createTask({
    required String title,
    String? description,
    String priority = 'MEDIUM',
    List<String>? assignedTo,
    DateTime? dueDate,
  }) async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(taskRepositoryProvider);
      await repo.createTask(
        title: title,
        description: description,
        priority: priority,
        assignedTo: assignedTo,
        dueDate: dueDate,
      );
      ref.invalidate(adminTasksProvider);
      ref.invalidate(internTasksProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> startTask(String taskId) async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(taskRepositoryProvider);
      await repo.startTask(taskId);
      ref.invalidate(internTasksProvider);
      ref.invalidate(adminTasksProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> submitTask(
    String taskId, {
    required String note,
    XFile? proofFile,
    String? proofUrl,
  }) async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(taskRepositoryProvider);
      await repo.submitTask(taskId, note: note, proofFile: proofFile, proofUrl: proofUrl);
      ref.invalidate(internTasksProvider);
      ref.invalidate(adminTasksProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateTask(String taskId, Map<String, dynamic> data) async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(taskRepositoryProvider);
      await repo.updateTask(taskId, data);
      ref.invalidate(adminTasksProvider);
      ref.invalidate(internTasksProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteTask(String taskId) async {
    state = const AsyncValue.loading();
    try {
      await ref.read(taskRepositoryProvider).deleteTask(taskId);
      ref.invalidate(adminTasksProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final taskActionsProvider =
    NotifierProvider<TaskActionsNotifier, AsyncValue<void>>(
        TaskActionsNotifier.new);

// ── Task comments ──
final taskCommentsProvider =
    FutureProvider.autoDispose.family<List<TaskCommentModel>, String>((ref, taskId) async {
  return ref.read(taskRepositoryProvider).getComments(taskId);
});

class CommentActionsNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  Future<void> addComment(String taskId, String content) async {
    state = const AsyncValue.loading();
    try {
      await ref.read(taskRepositoryProvider).addComment(taskId, content);
      ref.invalidate(taskCommentsProvider(taskId));
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteComment(String taskId, String commentId) async {
    state = const AsyncValue.loading();
    try {
      await ref.read(taskRepositoryProvider).deleteComment(commentId);
      ref.invalidate(taskCommentsProvider(taskId));
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final commentActionsProvider =
    NotifierProvider<CommentActionsNotifier, AsyncValue<void>>(
        CommentActionsNotifier.new);
