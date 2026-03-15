import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:erp_frontend/features/tasks/presentation/providers/task_provider.dart';
import 'package:erp_frontend/features/tasks/domain/models/task_model.dart';
import 'package:erp_frontend/features/tasks/presentation/widgets/task_comments_sheet.dart';
import 'package:erp_frontend/features/users/presentation/providers/user_provider.dart';
import 'package:erp_frontend/features/auth/domain/models/user_model.dart';

class AdminTasksScreen extends ConsumerWidget {
  const AdminTasksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(adminTasksProvider);
    final theme = Theme.of(context);

    ref.listen(taskActionsProvider, (_, next) {
      next.whenOrNull(
        error: (e, _) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: theme.colorScheme.error,
            duration: const Duration(seconds: 6),
          ));
        },
      );
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des tâches'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(adminTasksProvider),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateTaskDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Nouvelle tâche'),
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(adminTasksProvider),
        child: tasksAsync.when(
          data: (tasks) {
            if (tasks.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.task_outlined,
                        size: 64,
                        color: theme.colorScheme.onSurfaceVariant),
                    const SizedBox(height: 16),
                    Text('Aucune tâche créée',
                        style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant)),
                    const SizedBox(height: 8),
                    FilledButton.icon(
                      onPressed: () => _showCreateTaskDialog(context, ref),
                      icon: const Icon(Icons.add),
                      label: const Text('Créer une tâche'),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: tasks.length,
              itemBuilder: (context, index) {
                final task = tasks[index];
                return _AdminTaskCard(task: task);
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Erreur: $e')),
        ),
      ),
    );
  }

  void _showCreateTaskDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => _CreateTaskDialog(
        onSubmit: ({
          required String title,
          String? description,
          required String priority,
          required List<String> assignedTo,
        }) {
          ref.read(taskActionsProvider.notifier).createTask(
                title: title,
                description: description,
                priority: priority,
                assignedTo: assignedTo.isEmpty ? null : assignedTo,
              );
        },
      ),
    );
  }
}

// ── Create task dialog with intern selection ───────────────────────────────

class _CreateTaskDialog extends ConsumerStatefulWidget {
  final void Function({
    required String title,
    String? description,
    required String priority,
    required List<String> assignedTo,
  }) onSubmit;

  const _CreateTaskDialog({required this.onSubmit});

  @override
  ConsumerState<_CreateTaskDialog> createState() => _CreateTaskDialogState();
}

class _CreateTaskDialogState extends ConsumerState<_CreateTaskDialog> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  String _priority = 'MEDIUM';
  final Set<String> _selectedInterns = {};

  @override
  Widget build(BuildContext context) {
    final internsAsync = ref.watch(internsListProvider);

    return AlertDialog(
      title: const Text('Nouvelle tâche'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Titre *',
                hintText: 'Ex: Créer le rapport mensuel',
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Détails de la tâche...',
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _priority,
              decoration: const InputDecoration(labelText: 'Priorité'),
              items: const [
                DropdownMenuItem(value: 'LOW', child: Text('Basse')),
                DropdownMenuItem(value: 'MEDIUM', child: Text('Moyenne')),
                DropdownMenuItem(value: 'HIGH', child: Text('Haute')),
              ],
              onChanged: (v) => setState(() => _priority = v ?? 'MEDIUM'),
            ),
            const SizedBox(height: 16),
            const Text('Assigner à (optionnel)',
                style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            internsAsync.when(
              loading: () => const CircularProgressIndicator(),
              error: (_, __) => const Text('Impossible de charger les stagiaires'),
              data: (interns) {
                if (interns.isEmpty) {
                  return const Text('Aucun stagiaire disponible',
                      style: TextStyle(color: Colors.grey));
                }
                return Column(
                  children: interns.map((intern) {
                    final selected = _selectedInterns.contains(intern.id);
                    return CheckboxListTile(
                      dense: true,
                      title: Text(intern.fullName),
                      subtitle: Text(intern.email,
                          style: const TextStyle(fontSize: 11)),
                      value: selected,
                      onChanged: (checked) {
                        setState(() {
                          if (checked == true) {
                            _selectedInterns.add(intern.id);
                          } else {
                            _selectedInterns.remove(intern.id);
                          }
                        });
                      },
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: _titleController.text.trim().isEmpty
              ? null
              : () {
                  Navigator.pop(context);
                  widget.onSubmit(
                    title: _titleController.text.trim(),
                    description: _descController.text.trim().isEmpty
                        ? null
                        : _descController.text.trim(),
                    priority: _priority,
                    assignedTo: _selectedInterns.toList(),
                  );
                },
          child: const Text('Créer'),
        ),
      ],
    );
  }
}

class _AdminTaskCard extends ConsumerWidget {
  final TaskModel task;

  const _AdminTaskCard({required this.task});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    task.title,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                _buildPriorityBadge(task.priority),
              ],
            ),
            if (task.description != null) ...[
              const SizedBox(height: 8),
              Text(
                task.description!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                _buildStatusChip(task.status),
                const Spacer(),
                if (task.assignedTo != null)
                  Row(
                    children: [
                      Icon(Icons.person,
                          size: 14,
                          color: theme.colorScheme.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Text('Assigné',
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant)),
                    ],
                  )
                else
                  Text('Non assigné',
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),

            // Actions bar (always shown)
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 4),
            Row(
              children: [
                TextButton.icon(
                  onPressed: () => showTaskCommentsSheet(
                      context, task.id, task.title),
                  icon: const Icon(Icons.chat_bubble_outline, size: 18),
                  label: const Text('Commentaires'),
                ),
                const Spacer(),
                if (task.status == TaskStatus.submitted) ...[
                  OutlinedButton(
                    onPressed: () {
                      ref.read(taskActionsProvider.notifier).updateTask(
                        task.id,
                        {'status': 'REJECTED'},
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                    child: const Text('Rejeter'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () {
                      ref.read(taskActionsProvider.notifier).updateTask(
                        task.id,
                        {'status': 'APPROVED'},
                      );
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    child: const Text('Approuver'),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(TaskStatus status) {
    Color color;
    switch (status) {
      case TaskStatus.pending:
        color = Colors.orange;
      case TaskStatus.inProgress:
        color = Colors.blue;
      case TaskStatus.submitted:
        color = Colors.purple;
      case TaskStatus.approved:
        color = Colors.green;
      case TaskStatus.rejected:
        color = Colors.red;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        status.label,
        style:
            TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget _buildPriorityBadge(TaskPriority priority) {
    Color color;
    IconData icon;
    switch (priority) {
      case TaskPriority.low:
        color = Colors.grey;
        icon = Icons.arrow_downward;
      case TaskPriority.medium:
        color = Colors.orange;
        icon = Icons.remove;
      case TaskPriority.high:
        color = Colors.red;
        icon = Icons.arrow_upward;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 2),
          Text(priority.label,
              style: TextStyle(fontSize: 11, color: color)),
        ],
      ),
    );
  }
}
