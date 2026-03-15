import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:erp_frontend/features/auth/presentation/providers/auth_provider.dart';
import 'package:erp_frontend/features/tasks/presentation/providers/task_provider.dart';
import 'package:erp_frontend/features/tasks/domain/models/task_model.dart';

class InternDashboardScreen extends ConsumerWidget {
  const InternDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final tasksAsync = ref.watch(internTasksProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Salut ${user?.fullName?.split(' ').first ?? "toi"} ! 👋'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(internTasksProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Quick Stats ──
            tasksAsync.when(
              data: (tasks) {
                final pending =
                    tasks.where((t) => t.status == TaskStatus.pending).length;
                final inProgress = tasks
                    .where((t) => t.status == TaskStatus.inProgress)
                    .length;
                final submitted = tasks
                    .where((t) => t.status == TaskStatus.submitted)
                    .length;
                final approved = tasks
                    .where((t) => t.status == TaskStatus.approved)
                    .length;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Mes tâches',
                        style: theme.textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),

                    // Progress indicator
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Progression',
                                    style: theme.textTheme.titleMedium),
                                Text(
                                  '${tasks.isEmpty ? 0 : ((approved / tasks.length) * 100).round()}%',
                                  style:
                                      theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: LinearProgressIndicator(
                                value: tasks.isEmpty
                                    ? 0
                                    : approved / tasks.length,
                                minHeight: 10,
                                backgroundColor:
                                    theme.colorScheme.surfaceContainerHighest,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Quick stat chips
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _QuickChip(
                            label: '$pending en attente',
                            color: Colors.orange),
                        _QuickChip(
                            label: '$inProgress en cours',
                            color: Colors.blue),
                        _QuickChip(
                            label: '$submitted soumises',
                            color: Colors.purple),
                        _QuickChip(
                            label: '$approved approuvées',
                            color: Colors.green),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // ── Recent tasks ──
                    Text('Tâches récentes',
                        style: theme.textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),

                    if (tasks.isEmpty)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(Icons.task_outlined,
                                    size: 48,
                                    color:
                                        theme.colorScheme.onSurfaceVariant),
                                const SizedBox(height: 8),
                                Text('Aucune tâche assignée',
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                        color: theme
                                            .colorScheme.onSurfaceVariant)),
                              ],
                            ),
                          ),
                        ),
                      )
                    else
                      ...tasks.take(5).map((task) => _TaskQuickCard(task: task)),
                  ],
                );
              },
              loading: () => const Center(
                  child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              )),
              error: (e, _) => Card(
                color: theme.colorScheme.errorContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('Erreur: $e'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickChip extends StatelessWidget {
  final String label;
  final Color color;

  const _QuickChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label, style: TextStyle(color: color, fontSize: 13)),
      backgroundColor: color.withValues(alpha: 0.1),
      side: BorderSide(color: color.withValues(alpha: 0.3)),
      padding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }
}

class _TaskQuickCard extends StatelessWidget {
  final TaskModel task;

  const _TaskQuickCard({required this.task});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: _statusIcon(task.status),
        title: Text(task.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(task.status.label,
            style: TextStyle(color: _statusColor(task.status))),
        trailing: _priorityChip(task.priority),
      ),
    );
  }

  Widget _statusIcon(TaskStatus status) {
    switch (status) {
      case TaskStatus.pending:
        return const Icon(Icons.hourglass_empty, color: Colors.orange);
      case TaskStatus.inProgress:
        return const Icon(Icons.play_circle, color: Colors.blue);
      case TaskStatus.submitted:
        return const Icon(Icons.upload_file, color: Colors.purple);
      case TaskStatus.approved:
        return const Icon(Icons.check_circle, color: Colors.green);
      case TaskStatus.rejected:
        return const Icon(Icons.cancel, color: Colors.red);
    }
  }

  Color _statusColor(TaskStatus status) {
    switch (status) {
      case TaskStatus.pending:
        return Colors.orange;
      case TaskStatus.inProgress:
        return Colors.blue;
      case TaskStatus.submitted:
        return Colors.purple;
      case TaskStatus.approved:
        return Colors.green;
      case TaskStatus.rejected:
        return Colors.red;
    }
  }

  Widget _priorityChip(TaskPriority priority) {
    Color color;
    switch (priority) {
      case TaskPriority.low:
        color = Colors.grey;
      case TaskPriority.medium:
        color = Colors.orange;
      case TaskPriority.high:
        color = Colors.red;
    }
    return Chip(
      label: Text(priority.label, style: TextStyle(fontSize: 11, color: color)),
      backgroundColor: color.withValues(alpha: 0.1),
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
    );
  }
}
