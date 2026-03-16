import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:erp_frontend/core/router/app_router.dart';
import 'package:erp_frontend/features/attendance/domain/models/attendance_model.dart';
import 'package:erp_frontend/features/attendance/presentation/providers/attendance_provider.dart';

class AdminInternSessionsScreen extends ConsumerWidget {
  final String userId;

  const AdminInternSessionsScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(internSessionsProvider(userId));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: sessionsAsync.maybeWhen(
          data: (data) => Text(
            data.items.isNotEmpty
                ? 'Pointages de ${data.items.first.userFullName}'
                : 'Pointages',
          ),
          orElse: () => const Text('Pointages'),
        ),
      ),
      body: sessionsAsync.when(
        data: (data) {
          if (data.items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history_toggle_off,
                      size: 64, color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(height: 16),
                  Text(
                    'Aucun pointage enregistré',
                    style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: data.items.length,
            itemBuilder: (context, index) =>
                _SessionCard(session: data.items[index], userId: userId),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline,
                  size: 48, color: theme.colorScheme.error),
              const SizedBox(height: 16),
              Text('Erreur: $e'),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => ref.invalidate(internSessionsProvider(userId)),
                icon: const Icon(Icons.refresh),
                label: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  final AdminAttendanceSessionModel session;
  final String userId;

  const _SessionCard({required this.session, required this.userId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isOpen = session.status == AttendanceStatus.open;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push(
            AppRoutes.adminSessionDetailPath(userId, session.id)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _formatDate(session.clockIn),
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                  _StatusBadge(isOpen: isOpen),
                  if (session.note != null) ...[
                    const SizedBox(width: 8),
                    Icon(Icons.notes,
                        size: 18, color: theme.colorScheme.onSurfaceVariant),
                  ],
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.access_time,
                      size: 16, color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(
                    _formatTimeRange(session),
                    style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(width: 12),
                  Icon(Icons.timelapse,
                      size: 16, color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(
                    session.durationLabel,
                    style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    const days = ['Lun.', 'Mar.', 'Mer.', 'Jeu.', 'Ven.', 'Sam.', 'Dim.'];
    const months = ['', 'janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin',
        'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.'];
    return '${days[dt.weekday - 1]} ${dt.day} ${months[dt.month]} ${dt.year}';
  }

  String _formatTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  String _formatTimeRange(AdminAttendanceSessionModel session) {
    final start = _formatTime(session.clockIn);
    if (session.clockOut == null) return '$start → En cours';
    return '$start → ${_formatTime(session.clockOut!)}';
  }
}

class _StatusBadge extends StatelessWidget {
  final bool isOpen;

  const _StatusBadge({required this.isOpen});

  @override
  Widget build(BuildContext context) {
    final color = isOpen ? Colors.orange : Colors.green;
    final label = isOpen ? 'En cours' : 'Terminé';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.shade200),
      ),
      child: Text(
        label,
        style: TextStyle(color: color.shade700, fontSize: 12),
      ),
    );
  }
}
