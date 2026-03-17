import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:erp_frontend/features/tasks/presentation/providers/task_provider.dart';
import 'package:erp_frontend/features/tasks/presentation/screens/submissions_screen.dart';

class TaskSubmissionsScreen extends ConsumerWidget {
  final String taskId;
  final String taskTitle;

  const TaskSubmissionsScreen({
    super.key,
    required this.taskId,
    required this.taskTitle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final submissionsAsync = ref.watch(taskSubmissionsProvider(taskId));
    final currentPage = ref.watch(taskSubmissionsPageProvider(taskId));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Soumissions — $taskTitle'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(taskSubmissionsProvider(taskId)),
          ),
        ],
      ),
      body: submissionsAsync.when(
        data: (page) {
          if (page.items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.assignment_turned_in_outlined,
                    size: 64,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Aucune soumission pour cette tâche',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: page.items.length,
                  itemBuilder: (context, index) {
                    return SubmissionCard(submission: page.items[index]);
                  },
                ),
              ),
              if (page.pages > 1)
                _TaskPaginationBar(
                  currentPage: currentPage,
                  totalPages: page.pages,
                  total: page.total,
                  onPrevious: currentPage > 1
                      ? () => ref
                          .read(taskSubmissionsPageProvider(taskId).notifier)
                          .state = currentPage - 1
                      : null,
                  onNext: currentPage < page.pages
                      ? () => ref
                          .read(taskSubmissionsPageProvider(taskId).notifier)
                          .state = currentPage + 1
                      : null,
                ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur : $e')),
      ),
    );
  }
}

class _TaskPaginationBar extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final int total;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  const _TaskPaginationBar({
    required this.currentPage,
    required this.totalPages,
    required this.total,
    this.onPrevious,
    this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          OutlinedButton.icon(
            onPressed: onPrevious,
            icon: const Icon(Icons.chevron_left, size: 18),
            label: const Text('Précédent'),
          ),
          Text(
            'Page $currentPage / $totalPages  ($total résultats)',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          OutlinedButton.icon(
            onPressed: onNext,
            icon: const Icon(Icons.chevron_right, size: 18),
            label: const Text('Suivant'),
            iconAlignment: IconAlignment.end,
          ),
        ],
      ),
    );
  }
}
