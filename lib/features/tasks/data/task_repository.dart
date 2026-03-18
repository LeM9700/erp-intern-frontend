import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:erp_frontend/core/constants/api_constants.dart';
import 'package:erp_frontend/core/network/dio_client.dart';
import 'package:erp_frontend/features/tasks/domain/models/task_model.dart';

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  return TaskRepository(ref.read(dioProvider));
});

class TaskRepository {
  final Dio _dio;

  TaskRepository(this._dio);

  /// Admin: list all tasks
  Future<List<TaskModel>> getAdminTasks({String? status}) async {
    final response = await _dio.get(
      ApiConstants.tasksAdmin,
      queryParameters: status != null ? {'status': status} : null,
    );
    final data = response.data;
    final list = data is List ? data : (data['items'] as List<dynamic>);
    return list
        .map((e) => TaskModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Intern: list my tasks
  Future<List<TaskModel>> getMyTasks({String? status}) async {
    final response = await _dio.get(
      ApiConstants.tasksMe,
      queryParameters: status != null ? {'status': status} : null,
    );
    final data = response.data;
    final list = data is List ? data : (data['items'] as List<dynamic>);
    return list
        .map((e) => TaskModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Admin: create a task (returns list — one per assignee)
  Future<List<TaskModel>> createTask({
    required String title,
    String? description,
    String priority = 'MEDIUM',
    List<String>? assignedTo,
    DateTime? dueDate,
  }) async {
    final response = await _dio.post(
      ApiConstants.tasks,
      data: {
        'title': title,
        if (description != null) 'description': description,
        'priority': priority,
        if (assignedTo != null && assignedTo.isNotEmpty) 'assigned_to': assignedTo,
        if (dueDate != null) 'due_date': dueDate.toIso8601String(),
      },
    );
    final list = response.data as List<dynamic>;
    return list.map((e) => TaskModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Admin: update a task
  Future<TaskModel> updateTask(String taskId, Map<String, dynamic> data) async {
    final response = await _dio.patch(
      ApiConstants.taskUpdate(taskId),
      data: data,
    );
    return TaskModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// Intern: start a task
  Future<TaskModel> startTask(String taskId) async {
    final response = await _dio.patch(ApiConstants.taskStart(taskId));
    return TaskModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// Get comments for a task
  Future<List<TaskCommentModel>> getComments(String taskId) async {
    final response = await _dio.get(ApiConstants.taskComments(taskId));
    final data = response.data;
    final list = data is List ? data : (data['items'] as List<dynamic>);
    return list
        .map((e) => TaskCommentModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Add a comment to a task
  Future<TaskCommentModel> addComment(String taskId, String content) async {
    final response = await _dio.post(
      ApiConstants.taskComments(taskId),
      data: {'content': content},
    );
    return TaskCommentModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// Admin: delete a task
  Future<void> deleteTask(String taskId) async {
    await _dio.delete(ApiConstants.taskDelete(taskId));
  }

  /// Delete a comment
  Future<void> deleteComment(String commentId) async {
    await _dio.delete(ApiConstants.taskCommentDelete(commentId));
  }

  /// Admin: list all task submissions (paginated, optional status filter)
  Future<TaskSubmissionPageModel> getSubmissions({
    int page = 1,
    int size = 20,
    String? status,
  }) async {
    final response = await _dio.get(
      ApiConstants.taskSubmissions,
      queryParameters: {
        'page': page,
        'size': size,
        if (status != null) 'status': status,
      },
    );
    return TaskSubmissionPageModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// Admin: list submissions for a specific task (paginated)
  Future<TaskSubmissionPageModel> getTaskSubmissions(
    String taskId, {
    int page = 1,
    int size = 20,
  }) async {
    final response = await _dio.get(
      ApiConstants.taskSubmissionsById(taskId),
      queryParameters: {'page': page, 'size': size},
    );
    return TaskSubmissionPageModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// Intern: submit a task with a note and either a file or a URL
  Future<TaskModel> submitTask(
    String taskId, {
    required String note,
    XFile? proofFile,
    String? proofUrl,
  }) async {
    final formData = FormData.fromMap({
      'note': note,
      if (proofUrl != null) 'proof_url': proofUrl,
    });
    if (proofFile != null) {
      final bytes = await proofFile.readAsBytes();
      formData.files.add(MapEntry(
        'proof_file',
        MultipartFile.fromBytes(bytes, filename: proofFile.name),
      ));
    }
    final response = await _dio.post(
      ApiConstants.taskSubmit(taskId),
      data: formData,
    );
    return TaskModel.fromJson(response.data as Map<String, dynamic>);
  }
}
