import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:erp_frontend/features/auth/presentation/providers/auth_provider.dart';
import 'package:erp_frontend/features/tasks/presentation/providers/task_provider.dart';
import 'package:erp_frontend/features/tasks/domain/models/task_model.dart';

/// Ouvre le bottom sheet des commentaires pour une tâche.
void showTaskCommentsSheet(BuildContext context, String taskId, String taskTitle) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _TaskCommentsSheet(taskId: taskId, taskTitle: taskTitle),
  );
}

class _TaskCommentsSheet extends ConsumerStatefulWidget {
  final String taskId;
  final String taskTitle;
  const _TaskCommentsSheet({required this.taskId, required this.taskTitle});

  @override
  ConsumerState<_TaskCommentsSheet> createState() => _TaskCommentsSheetState();
}

class _TaskCommentsSheetState extends ConsumerState<_TaskCommentsSheet> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _submit() {
    final content = _controller.text.trim();
    if (content.isEmpty) return;
    _controller.clear();
    ref.read(commentActionsProvider.notifier).addComment(widget.taskId, content);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final commentsAsync = ref.watch(taskCommentsProvider(widget.taskId));
    final currentUser = ref.watch(currentUserProvider);
    final actionsState = ref.watch(commentActionsProvider);

    // Show error snackbar if action fails
    ref.listen(commentActionsProvider, (_, next) {
      next.whenOrNull(
        error: (e, _) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: theme.colorScheme.error,
          ));
        },
      );
    });

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (_, scrollController) => Column(
        children: [
          // ── Handle + title ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Row(
                  children: [
                    const Icon(Icons.chat_bubble_outline, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Commentaires — ${widget.taskTitle}',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // ── Comment list ──
          Expanded(
            child: commentsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Erreur: $e')),
              data: (comments) {
                if (comments.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline,
                            size: 48,
                            color: theme.colorScheme.onSurfaceVariant),
                        const SizedBox(height: 8),
                        Text('Aucun commentaire',
                            style: theme.textTheme.bodyLarge?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant)),
                      ],
                    ),
                  );
                }
                return ListView.separated(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: comments.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) => _CommentBubble(
                    comment: comments[i],
                    isOwn: comments[i].authorId == currentUser?.id,
                    onDelete: () => ref
                        .read(commentActionsProvider.notifier)
                        .deleteComment(widget.taskId, comments[i].id),
                  ),
                );
              },
            ),
          ),

          // ── Input ──
          const Divider(height: 1),
          Padding(
            padding: EdgeInsets.fromLTRB(
              12,
              8,
              12,
              MediaQuery.of(context).viewInsets.bottom + 12,
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _submit(),
                    decoration: InputDecoration(
                      hintText: 'Écrire un commentaire...',
                      filled: true,
                      fillColor: theme.colorScheme.surfaceContainerHighest,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 8),
                actionsState.isLoading
                    ? const SizedBox(
                        width: 40,
                        height: 40,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : IconButton.filled(
                        onPressed: _controller.text.trim().isNotEmpty
                            ? _submit
                            : null,
                        icon: const Icon(Icons.send),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CommentBubble extends StatelessWidget {
  final TaskCommentModel comment;
  final bool isOwn;
  final VoidCallback onDelete;

  const _CommentBubble({
    required this.comment,
    required this.isOwn,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment:
          isOwn ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (!isOwn) ...[
          CircleAvatar(
            radius: 16,
            backgroundColor: theme.colorScheme.secondaryContainer,
            child: Text(
              comment.authorFullName.isNotEmpty
                  ? comment.authorFullName[0].toUpperCase()
                  : '?',
              style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSecondaryContainer),
            ),
          ),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Column(
            crossAxisAlignment:
                isOwn ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              if (!isOwn)
                Padding(
                  padding: const EdgeInsets.only(bottom: 2, left: 4),
                  child: Text(
                    comment.authorFullName.isNotEmpty
                        ? comment.authorFullName
                        : 'Utilisateur',
                    style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant),
                  ),
                ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isOwn
                      ? theme.colorScheme.primaryContainer
                      : theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: Radius.circular(isOwn ? 16 : 4),
                    bottomRight: Radius.circular(isOwn ? 4 : 16),
                  ),
                ),
                child: Text(
                  comment.content,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isOwn
                        ? theme.colorScheme.onPrimaryContainer
                        : theme.colorScheme.onSurface,
                  ),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 2, left: 4, right: 4),
                    child: Text(
                      _formatTime(comment.createdAt),
                      style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ),
                  if (isOwn)
                    GestureDetector(
                      onTap: onDelete,
                      child: Icon(Icons.delete_outline,
                          size: 14,
                          color: theme.colorScheme.error),
                    ),
                ],
              ),
            ],
          ),
        ),
        if (isOwn) ...[
          const SizedBox(width: 8),
          CircleAvatar(
            radius: 16,
            backgroundColor: theme.colorScheme.primaryContainer,
            child: Text(
              comment.authorFullName.isNotEmpty
                  ? comment.authorFullName[0].toUpperCase()
                  : 'V',
              style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onPrimaryContainer),
            ),
          ),
        ],
      ],
    );
  }

  String _formatTime(DateTime dt) {
    final l = dt.toLocal();
    return '${l.day.toString().padLeft(2, '0')}/${l.month.toString().padLeft(2, '0')} '
        '${l.hour.toString().padLeft(2, '0')}:${l.minute.toString().padLeft(2, '0')}';
  }
}
