enum TaskStatus {
  pending('PENDING'),
  inProgress('IN_PROGRESS'),
  submitted('SUBMITTED'),
  approved('APPROVED'),
  rejected('REJECTED');

  final String value;
  const TaskStatus(this.value);

  static TaskStatus fromString(String s) {
    return TaskStatus.values.firstWhere(
      (e) => e.value == s.toUpperCase(),
      orElse: () => TaskStatus.pending,
    );
  }

  String get label {
    switch (this) {
      case TaskStatus.pending:
        return 'En attente';
      case TaskStatus.inProgress:
        return 'En cours';
      case TaskStatus.submitted:
        return 'Soumise';
      case TaskStatus.approved:
        return 'Approuvée';
      case TaskStatus.rejected:
        return 'Rejetée';
    }
  }
}

enum TaskPriority {
  low('LOW'),
  medium('MEDIUM'),
  high('HIGH');

  final String value;
  const TaskPriority(this.value);

  static TaskPriority fromString(String s) {
    return TaskPriority.values.firstWhere(
      (e) => e.value == s.toUpperCase(),
      orElse: () => TaskPriority.medium,
    );
  }

  String get label {
    switch (this) {
      case TaskPriority.low:
        return 'Basse';
      case TaskPriority.medium:
        return 'Moyenne';
      case TaskPriority.high:
        return 'Haute';
    }
  }
}

class TaskProofModel {
  final String id;
  final String? fileId;
  final String? proofUrl;
  final String note;
  final DateTime createdAt;

  const TaskProofModel({
    required this.id,
    this.fileId,
    this.proofUrl,
    required this.note,
    required this.createdAt,
  });

  factory TaskProofModel.fromJson(Map<String, dynamic> json) {
    return TaskProofModel(
      id: json['id'] as String,
      fileId: json['file_id'] as String?,
      proofUrl: json['proof_url'] as String?,
      note: json['note'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

class TaskCommentModel {
  final String id;
  final String taskId;
  final String authorId;
  final String authorFullName;
  final String content;
  final DateTime createdAt;

  const TaskCommentModel({
    required this.id,
    required this.taskId,
    required this.authorId,
    required this.authorFullName,
    required this.content,
    required this.createdAt,
  });

  factory TaskCommentModel.fromJson(Map<String, dynamic> json) {
    return TaskCommentModel(
      id: json['id'] as String,
      taskId: json['task_id'] as String,
      authorId: json['author_id'] as String,
      authorFullName: json['author_full_name'] as String? ?? '',
      content: json['content'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

class TaskSubmissionModel {
  final String id;
  final String taskId;
  final String taskTitle;
  final TaskStatus taskStatus;
  final String? internId;
  final String? internFullName;
  final String note;
  final String? fileId;
  final String? proofUrl;
  final DateTime? submittedAt;
  final DateTime createdAt;

  const TaskSubmissionModel({
    required this.id,
    required this.taskId,
    required this.taskTitle,
    required this.taskStatus,
    this.internId,
    this.internFullName,
    required this.note,
    this.fileId,
    this.proofUrl,
    this.submittedAt,
    required this.createdAt,
  });

  factory TaskSubmissionModel.fromJson(Map<String, dynamic> json) {
    return TaskSubmissionModel(
      id: json['id'] as String,
      taskId: json['task_id'] as String,
      taskTitle: json['task_title'] as String,
      taskStatus: TaskStatus.fromString(json['task_status'] as String),
      internId: json['intern_id'] as String?,
      internFullName: json['intern_full_name'] as String?,
      note: json['note'] as String,
      fileId: json['file_id'] as String?,
      proofUrl: json['proof_url'] as String?,
      submittedAt: json['submitted_at'] != null
          ? DateTime.parse(json['submitted_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

class TaskSubmissionPageModel {
  final List<TaskSubmissionModel> items;
  final int total;
  final int page;
  final int size;
  final int pages;

  const TaskSubmissionPageModel({
    required this.items,
    required this.total,
    required this.page,
    required this.size,
    required this.pages,
  });

  factory TaskSubmissionPageModel.fromJson(Map<String, dynamic> json) {
    return TaskSubmissionPageModel(
      items: (json['items'] as List<dynamic>)
          .map((e) => TaskSubmissionModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: json['total'] as int,
      page: json['page'] as int,
      size: json['size'] as int,
      pages: json['pages'] as int,
    );
  }
}

class TaskModel {
  final String id;
  final String title;
  final String? description;
  final TaskStatus status;
  final TaskPriority priority;
  final String? assignedTo;
  final String createdBy;
  final DateTime? dueDate;
  final DateTime? startedAt;
  final DateTime? submittedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<TaskProofModel> proofs;

  const TaskModel({
    required this.id,
    required this.title,
    this.description,
    required this.status,
    required this.priority,
    this.assignedTo,
    required this.createdBy,
    this.dueDate,
    this.startedAt,
    this.submittedAt,
    required this.createdAt,
    required this.updatedAt,
    this.proofs = const [],
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      status: TaskStatus.fromString(json['status'] as String),
      priority: TaskPriority.fromString(json['priority'] as String),
      assignedTo: json['assigned_to'] as String?,
      createdBy: json['created_by'] as String,
      dueDate: json['due_date'] != null
          ? DateTime.parse(json['due_date'] as String)
          : null,
      startedAt: json['started_at'] != null
          ? DateTime.parse(json['started_at'] as String)
          : null,
      submittedAt: json['submitted_at'] != null
          ? DateTime.parse(json['submitted_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      proofs: (json['proofs'] as List<dynamic>?)
              ?.map((e) => TaskProofModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
