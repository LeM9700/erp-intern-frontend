import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:erp_frontend/features/tasks/presentation/providers/task_provider.dart';
import 'package:erp_frontend/features/tasks/domain/models/task_model.dart';
import 'package:erp_frontend/features/tasks/presentation/widgets/task_comments_sheet.dart';

class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key, this.initialStatus});

  final String? initialStatus;

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen> {
  static const _chips = [
    (label: 'Tous', value: null),
    (label: 'En attente', value: 'PENDING'),
    (label: 'En cours', value: 'IN_PROGRESS'),
    (label: 'Soumises', value: 'SUBMITTED'),
    (label: 'Approuvées', value: 'APPROVED'),
    (label: 'Rejetées', value: 'REJECTED'),
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialStatus != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(internTaskStatusFilterProvider.notifier).set(widget.initialStatus);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(internTasksProvider);
    final currentFilter = ref.watch(internTaskStatusFilterProvider);
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
        title: const Text('Mes tâches'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(internTasksProvider),
          ),
        ],
      ),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: _chips.map((chip) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(chip.value == null ? 'Tous' : chip.label),
                    selected: currentFilter == chip.value,
                    onSelected: (_) {
                      ref
                          .read(internTaskStatusFilterProvider.notifier)
                          .set(chip.value);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => ref.invalidate(internTasksProvider),
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
                          Text('Aucune tâche assignée',
                              style: theme.textTheme.titleMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant)),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: tasks.length,
                    itemBuilder: (context, index) {
                      final task = tasks[index];
                      return _InternTaskCard(task: task);
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Erreur: $e')),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InternTaskCard extends ConsumerStatefulWidget {
  final TaskModel task;

  const _InternTaskCard({required this.task});

  @override
  ConsumerState<_InternTaskCard> createState() => _InternTaskCardState();
}

class _InternTaskCardState extends ConsumerState<_InternTaskCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final task = widget.task;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Text(
                    task.title,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                _PriorityBadge(priority: task.priority),
              ],
            ),

            if (task.description != null) ...[
              const SizedBox(height: 8),
              Text(
                task.description!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                maxLines: _expanded ? null : 2,
                overflow: _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
              ),
              if (task.description!.length > 100)
                GestureDetector(
                  onTap: () => setState(() => _expanded = !_expanded),
                  child: Text(
                    _expanded ? 'Voir moins' : 'Voir plus',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],

            const SizedBox(height: 12),

            // Status and due date
            Row(
              children: [
                _StatusChip(status: task.status),
                const Spacer(),
                if (task.dueDate != null)
                  Row(
                    children: [
                      Icon(Icons.calendar_today,
                          size: 14,
                          color: theme.colorScheme.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Text(
                        _formatDate(task.dueDate!),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
              ],
            ),

            // Actions
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 4),
            Row(
              children: [
                // Comments button
                TextButton.icon(
                  onPressed: () => showTaskCommentsSheet(
                      context, task.id, task.title),
                  icon: const Icon(Icons.chat_bubble_outline, size: 18),
                  label: const Text('Commentaires'),
                ),
                const Spacer(),
                if (task.status == TaskStatus.pending)
                  FilledButton.tonal(
                    onPressed: () {
                      ref.read(taskActionsProvider.notifier).startTask(task.id);
                    },
                    child: const Text('Commencer'),
                  ),
                if (task.status == TaskStatus.inProgress)
                  FilledButton(
                    onPressed: () => _showSubmitDialog(context, ref),
                    child: const Text('Soumettre'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showSubmitDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _SubmitProofDialog(
        onSubmit: (note, proofFile, proofUrl) {
          ref.read(taskActionsProvider.notifier).submitTask(
            widget.task.id,
            note: note,
            proofFile: proofFile,
            proofUrl: proofUrl,
          );
        },
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }
}

class _StatusChip extends StatelessWidget {
  final TaskStatus status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _color.withValues(alpha: 0.3)),
      ),
      child: Text(
        status.label,
        style: TextStyle(color: _color, fontSize: 12, fontWeight: FontWeight.w500),
      ),
    );
  }

  Color get _color {
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
}

class _PriorityBadge extends StatelessWidget {
  final TaskPriority priority;

  const _PriorityBadge({required this.priority});

  @override
  Widget build(BuildContext context) {
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

// ── Submit proof dialog ────────────────────────────────────────────────────

class _SubmitProofDialog extends StatefulWidget {
  final void Function(String note, XFile? proofFile, String? proofUrl) onSubmit;
  const _SubmitProofDialog({required this.onSubmit});

  @override
  State<_SubmitProofDialog> createState() => _SubmitProofDialogState();
}

class _SubmitProofDialogState extends State<_SubmitProofDialog> {
  final _noteController = TextEditingController();
  final _urlController = TextEditingController();
  bool _useFile = false;
  XFile? _pickedFile;

  bool get _isValid {
    if (_noteController.text.trim().isEmpty) return false;
    if (_useFile) return _pickedFile != null;
    final url = _urlController.text.trim();
    return url.startsWith('http://') || url.startsWith('https://');
  }

  Future<void> _pickFile() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (file != null) setState(() => _pickedFile = file);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Soumettre la tâche'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _noteController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Description du travail *',
                hintText: 'Décrivez brièvement ce que vous avez réalisé...',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            const Text('Preuve du travail *',
                style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _ProofTypeButton(
                    label: 'Image',
                    icon: Icons.image_outlined,
                    selected: _useFile,
                    onTap: () => setState(() => _useFile = true),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ProofTypeButton(
                    label: 'Lien URL',
                    icon: Icons.link,
                    selected: !_useFile,
                    onTap: () => setState(() => _useFile = false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_useFile) ...[
              OutlinedButton.icon(
                onPressed: _pickFile,
                icon: const Icon(Icons.upload_file),
                label: Text(
                  _pickedFile != null ? _pickedFile!.name : 'Choisir un fichier',
                ),
              ),
            ] else ...[
              TextField(
                controller: _urlController,
                decoration: const InputDecoration(
                  labelText: 'URL (http:// ou https://)',
                  hintText: 'https://github.com/...',
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: _isValid
              ? () {
                  Navigator.pop(context);
                  widget.onSubmit(
                    _noteController.text.trim(),
                    _useFile ? _pickedFile : null,
                    _useFile ? null : _urlController.text.trim(),
                  );
                }
              : null,
          child: const Text('Soumettre'),
        ),
      ],
    );
  }
}

class _ProofTypeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _ProofTypeButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected
                ? theme.colorScheme.primary
                : theme.colorScheme.outline.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          children: [
            Icon(icon,
                color: selected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(
                  fontSize: 12,
                  color: selected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                  fontWeight:
                      selected ? FontWeight.w600 : FontWeight.normal,
                )),
          ],
        ),
      ),
    );
  }
}
