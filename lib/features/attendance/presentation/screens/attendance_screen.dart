import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:erp_frontend/features/attendance/domain/models/attendance_model.dart';
import 'package:erp_frontend/features/attendance/presentation/providers/attendance_provider.dart';

class AttendanceScreen extends ConsumerStatefulWidget {
  const AttendanceScreen({super.key});

  @override
  ConsumerState<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends ConsumerState<AttendanceScreen> {
  bool _isClockedIn = false;
  DateTime? _clockInTime;
  Timer? _timer;
  Duration _elapsed = Duration.zero;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer(DateTime clockInUtc) {
    _clockInTime = clockInUtc;
    _elapsed = DateTime.now().toUtc().difference(clockInUtc);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _elapsed = DateTime.now().toUtc().difference(_clockInTime!);
      });
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
    _clockInTime = null;
    _elapsed = Duration.zero;
  }

  String _formatDuration(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final attendanceState = ref.watch(attendanceActionsProvider);
    final summaryAsync = ref.watch(myAttendanceSummaryProvider);
    final currentSessionAsync = ref.watch(currentSessionProvider);

    // ── Sync initial state from currentSessionProvider ──
    currentSessionAsync.whenData((session) {
      final shouldBeClockedIn = session != null && session.isOpen;
      if (shouldBeClockedIn != _isClockedIn) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          setState(() {
            _isClockedIn = shouldBeClockedIn;
            if (shouldBeClockedIn) {
              _startTimer(session!.createdAt);
            } else {
              _stopTimer();
            }
          });
        });
      }
    });

    // ── Listen for action results (clock-in / clock-out) ──
    ref.listen(attendanceActionsProvider, (prev, next) {
      next.when(
        data: (session) {
          if (session != null) {
            setState(() {
              _isClockedIn = session.isOpen;
              if (session.isOpen) {
                _startTimer(session.createdAt);
              } else {
                _stopTimer();
              }
            });
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(session.isOpen
                  ? 'Pointage d\'entrée enregistré ✓'
                  : 'Pointage de sortie enregistré ✓'),
              backgroundColor: Colors.green,
            ));
          }
        },
        loading: () {},
        error: (e, _) {
          final msg = e.toString().replaceAll('Exception: ', '');
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(msg),
            backgroundColor: theme.colorScheme.error,
            duration: const Duration(seconds: 6),
          ));
        },
      );
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Pointage')),
      body: currentSessionAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur : $e')),
        data: (_) => SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 24),
              // ── Status icon ─────────────────────────────────────────
              Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  color: _isClockedIn
                      ? Colors.green.withOpacity(0.1)
                      : theme.colorScheme.primaryContainer.withOpacity(0.3),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _isClockedIn ? Colors.green : theme.colorScheme.primary,
                    width: 3,
                  ),
                ),
                child: Icon(
                  _isClockedIn ? Icons.timer : Icons.timer_outlined,
                  size: 72,
                  color: _isClockedIn ? Colors.green : theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 24),

              // ── Timer ───────────────────────────────────────────────
              if (_isClockedIn) ...[
                Text(
                  _formatDuration(_elapsed),
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 8),
              ],

              Text(
                _isClockedIn ? 'Vous êtes pointé' : 'Non pointé',
                style: theme.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                _isClockedIn
                    ? 'Cliquez pour pointer votre sortie'
                    : 'Cliquez pour pointer votre entrée',
                style: theme.textTheme.bodyLarge
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: 220,
                height: 56,
                child: attendanceState.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : FilledButton.icon(
                        onPressed: _handleAttendance,
                        icon: Icon(_isClockedIn ? Icons.logout : Icons.login),
                        label: Text(
                          _isClockedIn ? 'Pointer sortie' : 'Pointer entrée',
                          style: const TextStyle(fontSize: 16),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: _isClockedIn
                              ? Colors.red
                              : theme.colorScheme.primary,
                        ),
                      ),
              ),
              const SizedBox(height: 16),
              if (!_isClockedIn)
                Text(
                  kIsWeb
                      ? 'Une photo depuis la galerie sera requise'
                      : 'Une photo sera prise à la confirmation',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),

              const SizedBox(height: 40),
              const Divider(),
              const SizedBox(height: 16),

              // ── Résumé des heures ─────────────────────────────────
              summaryAsync.when(
                loading: () => const CircularProgressIndicator(),
                error: (_, __) => const SizedBox.shrink(),
                data: (summary) => _SummarySection(summary: summary),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleAttendance() async {
    if (_isClockedIn) {
      final note = await _showNoteDialog();
      if (note == null) return;
      ref.read(attendanceActionsProvider.notifier).clockOut(note);
    } else {
      final photo = await _pickPhoto();
      if (photo == null) return;
      ref.read(attendanceActionsProvider.notifier).clockIn(photo);
    }
  }

  Future<XFile?> _pickPhoto() async {
    final picker = ImagePicker();
    return picker.pickImage(
      source: kIsWeb ? ImageSource.gallery : ImageSource.camera,
      imageQuality: 80,
      maxWidth: 1280,
    );
  }

  Future<String?> _showNoteDialog() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _NoteDialog(controller: controller),
    );
  }
}

// ── Dialog compte-rendu ────────────────────────────────────────────────────────

class _NoteDialog extends StatefulWidget {
  final TextEditingController controller;
  const _NoteDialog({required this.controller});

  @override
  State<_NoteDialog> createState() => _NoteDialogState();
}

class _NoteDialogState extends State<_NoteDialog> {
  static const int minChars = 200;

  int get _charCount => widget.controller.text.length;
  bool get _isValid => _charCount >= minChars;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Compte-rendu de sortie'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Décrivez votre travail de la journée (200 caractères minimum).',
            style: TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: widget.controller,
            maxLines: 5,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Ex: J\'ai travaillé sur...',
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 6),
          Text(
            '$_charCount / $minChars caractères',
            style: TextStyle(
              fontSize: 12,
              color: _isValid ? Colors.green : Colors.red,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: _isValid
              ? () => Navigator.pop(context, widget.controller.text)
              : null,
          child: const Text('Confirmer'),
        ),
      ],
    );
  }
}

// ── Résumé des heures ──────────────────────────────────────────────────────────

class _SummarySection extends StatelessWidget {
  final AttendanceSummaryModel summary;
  const _SummarySection({required this.summary});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Mes heures', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Row(
          children: [
            _StatCard(
              label: 'Total heures',
              value: '${summary.totalHours.toStringAsFixed(1)}h',
              icon: Icons.access_time,
            ),
            const SizedBox(width: 12),
            _StatCard(
              label: 'Sessions',
              value: '${summary.totalSessions}',
              icon: Icons.calendar_today,
            ),
          ],
        ),
        if (summary.sessions.isNotEmpty) ...[
          const SizedBox(height: 20),
          Text('Historique', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          ...summary.sessions.map((s) => _SessionRow(session: s)),
        ],
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _StatCard({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: theme.colorScheme.primary),
            const SizedBox(height: 8),
            Text(value, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            Text(label, style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _SessionRow extends StatelessWidget {
  final AttendanceSummarySessionItem session;
  const _SessionRow({required this.session});

  String _fmt(DateTime dt) {
    final l = dt.toLocal();
    return '${l.day.toString().padLeft(2, '0')}/${l.month.toString().padLeft(2, '0')} '
        '${l.hour.toString().padLeft(2, '0')}:${l.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const Icon(Icons.access_time),
        title: Text('${_fmt(session.clockIn)} → ${_fmt(session.clockOut)}'),
        subtitle: Text('Durée : ${session.durationLabel}'),
        trailing: Text(
          session.durationLabel,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
