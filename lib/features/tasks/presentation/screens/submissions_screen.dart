import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:erp_frontend/features/tasks/domain/models/task_model.dart';
import 'package:erp_frontend/features/tasks/presentation/providers/task_provider.dart';

class SubmissionsScreen extends ConsumerWidget {
  const SubmissionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final submissionsAsync = ref.watch(submissionsProvider);
    final currentPage = ref.watch(submissionsPageProvider);
    final currentStatus = ref.watch(submissionsStatusFilterProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Soumissions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(submissionsProvider),
          ),
        ],
      ),
      body: Column(
        children: [
          _StatusFilterBar(
            currentStatus: currentStatus,
            onStatusChanged: (status) {
              ref.read(submissionsStatusFilterProvider.notifier).state = status;
              ref.read(submissionsPageProvider.notifier).state = 1;
            },
          ),
          Expanded(
            child: submissionsAsync.when(
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
                          'Aucune soumission trouvée',
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
                    _PaginationBar(
                      currentPage: currentPage,
                      totalPages: page.pages,
                      total: page.total,
                      onPrevious: currentPage > 1
                          ? () => ref
                              .read(submissionsPageProvider.notifier)
                              .state = currentPage - 1
                          : null,
                      onNext: currentPage < page.pages
                          ? () => ref
                              .read(submissionsPageProvider.notifier)
                              .state = currentPage + 1
                          : null,
                    ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Erreur : $e')),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Status filter bar ──────────────────────────────────────────────────────

class _StatusFilterBar extends StatelessWidget {
  final String? currentStatus;
  final void Function(String?) onStatusChanged;

  const _StatusFilterBar({
    required this.currentStatus,
    required this.onStatusChanged,
  });

  static const _filters = [
    (label: 'Tous', value: null),
    (label: 'En attente', value: 'PENDING'),
    (label: 'En cours', value: 'IN_PROGRESS'),
    (label: 'Soumise', value: 'SUBMITTED'),
    (label: 'Approuvée', value: 'APPROVED'),
    (label: 'Rejetée', value: 'REJECTED'),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: _filters.map((f) {
          final selected = currentStatus == f.value;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(f.label),
              selected: selected,
              onSelected: (_) => onStatusChanged(f.value),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Pagination bar ─────────────────────────────────────────────────────────

class _PaginationBar extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final int total;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  const _PaginationBar({
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

// ── Submission card (public — reused in TaskSubmissionsScreen) ─────────────

class SubmissionCard extends StatelessWidget {
  final TaskSubmissionModel submission;

  const SubmissionCard({super.key, required this.submission});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: stagiaire + statut
            Row(
              children: [
                Icon(
                  Icons.person_outline,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    submission.internFullName ?? 'Stagiaire inconnu',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                _buildStatusChip(submission.taskStatus),
              ],
            ),

            const SizedBox(height: 8),

            // Titre de la tâche
            Row(
              children: [
                Icon(
                  Icons.task_outlined,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    submission.taskTitle,
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Note soumise
            Text(
              submission.note,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontStyle: FontStyle.italic,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),

            // Lien preuve
            if (submission.proofUrl != null) ...[
              const SizedBox(height: 8),
              _ProofUrlButton(url: submission.proofUrl!),
            ],

            // Date de soumission
            if (submission.submittedAt != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.schedule,
                    size: 14,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Soumis le ${_formatDate(submission.submittedAt!)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
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
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final local = date.toLocal();
    return DateFormat('dd/MM/yyyy à HH:mm').format(local);
  }
}

// ── Proof URL button ───────────────────────────────────────────────────────

class _ProofUrlButton extends StatelessWidget {
  final String url;

  const _ProofUrlButton({required this.url});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () async {
        await Clipboard.setData(ClipboardData(text: url));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Lien copié dans le presse-papiers'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.link,
              size: 16,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                url,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                  decoration: TextDecoration.underline,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.copy,
              size: 14,
              color: theme.colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }
}
