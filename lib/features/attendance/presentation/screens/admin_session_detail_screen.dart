import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:erp_frontend/core/constants/api_constants.dart';
import 'package:erp_frontend/core/network/dio_client.dart';
import 'package:erp_frontend/features/attendance/domain/models/attendance_model.dart';
import 'package:erp_frontend/features/attendance/presentation/providers/attendance_provider.dart';
import 'package:erp_frontend/features/attendance/presentation/screens/admin_attendance_screen.dart';

class AdminSessionDetailScreen extends ConsumerWidget {
  final String userId;
  final String sessionId;

  const AdminSessionDetailScreen({
    super.key,
    required this.userId,
    required this.sessionId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionAsync =
        ref.watch(internSessionDetailProvider((userId, sessionId)));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Détail du pointage')),
      body: sessionAsync.when(
        data: (session) => _SessionDetailBody(session: session),
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
                onPressed: () => ref.invalidate(
                    internSessionDetailProvider((userId, sessionId))),
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

class _SessionDetailBody extends ConsumerWidget {
  final AdminAttendanceSessionModel session;

  const _SessionDetailBody({required this.session});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final dio = ref.read(dioProvider);
    final isOpen = session.status == AttendanceStatus.open;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Informations ──
          Text('Informations', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _InfoRow(
                    icon: Icons.person_outline,
                    label: 'Stagiaire',
                    value: session.userFullName,
                  ),
                  const Divider(height: 24),
                  _InfoRow(
                    icon: Icons.calendar_today_outlined,
                    label: 'Date',
                    value: _formatDate(session.clockIn),
                  ),
                  const Divider(height: 24),
                  // Entrée
                  Row(
                    children: [
                      const Icon(Icons.login, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Entrée',
                                style: theme.textTheme.bodySmall?.copyWith(
                                    color:
                                        theme.colorScheme.onSurfaceVariant)),
                            Text(_formatTime(session.clockIn),
                                style: theme.textTheme.bodyLarge),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.photo_camera_outlined),
                        tooltip: 'Voir la photo d\'entrée',
                        onPressed: () => _showPhoto(
                          context,
                          dio,
                          '${ApiConstants.baseUrl}/files/${session.clockInPhotoId}/view',
                          'Photo d\'entrée',
                        ),
                      ),
                    ],
                  ),
                  // Sortie
                  if (session.clockOut != null) ...[
                    const Divider(height: 24),
                    Row(
                      children: [
                        const Icon(Icons.logout, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Sortie',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme
                                          .colorScheme.onSurfaceVariant)),
                              Text(_formatTime(session.clockOut!),
                                  style: theme.textTheme.bodyLarge),
                            ],
                          ),
                        ),
                        if (session.clockOutPhotoId != null)
                          IconButton(
                            icon: const Icon(Icons.photo_camera_outlined),
                            tooltip: 'Voir la photo de sortie',
                            onPressed: () => _showPhoto(
                              context,
                              dio,
                              '${ApiConstants.baseUrl}/files/${session.clockOutPhotoId}/view',
                              'Photo de sortie',
                            ),
                          ),
                      ],
                    ),
                  ],
                  const Divider(height: 24),
                  _InfoRow(
                    icon: Icons.timelapse,
                    label: 'Durée',
                    value: session.durationLabel,
                  ),
                  const Divider(height: 24),
                  Row(
                    children: [
                      const Icon(Icons.flag_outlined, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Statut',
                                style: theme.textTheme.bodySmall?.copyWith(
                                    color:
                                        theme.colorScheme.onSurfaceVariant)),
                            const SizedBox(height: 4),
                            _StatusBadge(isOpen: isOpen),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // ── Compte-rendu ──
          Text('Compte-rendu', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          if (session.note != null)
            Card(
              color: theme.colorScheme.secondaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.notes,
                        color:
                            theme.colorScheme.onSecondaryContainer),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        session.note!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                            color:
                                theme.colorScheme.onSecondaryContainer),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.notes_outlined,
                        color: theme.colorScheme.onSurfaceVariant),
                    const SizedBox(width: 12),
                    Text(
                      'Aucun compte-rendu',
                      style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showPhoto(
      BuildContext context, Dio dio, String photoUrl, String title) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 8, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(title,
                        style: Theme.of(ctx).textTheme.titleMedium),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            AttendancePhotoViewer(dio: dio, photoUrl: photoUrl),
          ],
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
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              Text(value, style: theme.textTheme.bodyLarge),
            ],
          ),
        ),
      ],
    );
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
