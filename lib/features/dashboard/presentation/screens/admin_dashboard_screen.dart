import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:erp_frontend/core/router/app_router.dart';
import 'package:erp_frontend/features/auth/presentation/providers/auth_provider.dart';
import 'package:erp_frontend/features/dashboard/presentation/providers/dashboard_provider.dart';
import 'package:erp_frontend/features/dashboard/domain/models/dashboard_model.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final dashAsync = ref.watch(adminDashboardProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Bonjour, ${user?.fullName ?? "Admin"} 👋'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(adminDashboardProvider),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(adminDashboardProvider),
        child: dashAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline,
                    size: 48, color: theme.colorScheme.error),
                const SizedBox(height: 12),
                Text('Erreur : $e',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: theme.colorScheme.error)),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => ref.invalidate(adminDashboardProvider),
                  child: const Text('Réessayer'),
                ),
              ],
            ),
          ),
          data: (kpis) => ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ── Tâches ──────────────────────────────────────────────
              Text('Vue d\'ensemble — Tâches',
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.5,
                children: [
                  _KpiCard(
                      title: 'En attente',
                      value: '${kpis.tasksPending}',
                      icon: Icons.hourglass_empty,
                      color: Colors.orange,
                      onTap: () => context.push(AppRoutes.adminTasks, extra: 'PENDING')),
                  _KpiCard(
                      title: 'En cours',
                      value: '${kpis.tasksInProgress}',
                      icon: Icons.play_circle_outline,
                      color: Colors.blue,
                      onTap: () => context.push(AppRoutes.adminTasks, extra: 'IN_PROGRESS')),
                  _KpiCard(
                      title: 'Soumises',
                      value: '${kpis.tasksSubmitted}',
                      icon: Icons.upload_file,
                      color: Colors.purple,
                      onTap: () => context.push(AppRoutes.adminTasks, extra: 'SUBMITTED')),
                  _KpiCard(
                      title: 'Approuvées',
                      value: '${kpis.tasksApproved}',
                      icon: Icons.check_circle_outline,
                      color: Colors.green,
                      onTap: () => context.push(AppRoutes.adminTasks, extra: 'APPROVED')),
                ],
              ),

              const SizedBox(height: 20),

              // ── Heures ──────────────────────────────────────────────
              Text('Présences',
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _KpiCard(
                      title: 'Pointés maintenant',
                      value: '${kpis.liveSessionsCount}',
                      icon: Icons.sensors,
                      color: kpis.liveSessionsCount > 0
                          ? Colors.green
                          : Colors.grey,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _KpiCard(
                      title: 'Stagiaires actifs',
                      value: '${kpis.activeInterns}/${kpis.totalInterns}',
                      icon: Icons.people_outline,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _KpiCard(
                      title: 'Heures (semaine)',
                      value: '${kpis.totalHoursThisWeek.toStringAsFixed(1)}h',
                      icon: Icons.access_time,
                      color: Colors.teal,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _KpiCard(
                      title: 'Heures (mois)',
                      value: '${kpis.totalHoursThisMonth.toStringAsFixed(1)}h',
                      icon: Icons.calendar_month,
                      color: Colors.indigo,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // ── Par stagiaire ────────────────────────────────────────
              if (kpis.interns.isNotEmpty) ...[
                Text('Par stagiaire',
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                ...kpis.interns.map((intern) => _InternCard(intern: intern)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _KpiCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(icon, color: color, size: 24),
                  Text(value,
                      style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold, color: color)),
                ],
              ),
              Text(title,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            ],
          ),
        ),
      ),
    );
  }
}

class _InternCard extends StatelessWidget {
  final InternSummaryModel intern;
  const _InternCard({required this.intern});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () =>
            context.push(AppRoutes.adminInternSessionsPath(intern.userId)),
        child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: intern.isCurrentlyClockedIn
                      ? Colors.green.shade100
                      : theme.colorScheme.surfaceContainerHighest,
                  child: Text(
                    intern.fullName.isNotEmpty
                        ? intern.fullName[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                        color: intern.isCurrentlyClockedIn
                            ? Colors.green.shade700
                            : theme.colorScheme.onSurfaceVariant),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(intern.fullName,
                          style: theme.textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w600)),
                      Text(intern.email,
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant)),
                    ],
                  ),
                ),
                if (intern.isCurrentlyClockedIn)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text('Pointé',
                        style: TextStyle(
                            fontSize: 11,
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.w500)),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _MiniStat(
                    label: 'Semaine',
                    value: '${intern.hoursThisWeek.toStringAsFixed(1)}h',
                    color: Colors.teal),
                const SizedBox(width: 8),
                _MiniStat(
                    label: 'Mois',
                    value: '${intern.hoursThisMonth.toStringAsFixed(1)}h',
                    color: Colors.indigo),
                const Spacer(),
                if (intern.tasksSubmitted > 0)
                  _MiniStat(
                      label: 'À revoir',
                      value: '${intern.tasksSubmitted}',
                      color: Colors.orange),
                const SizedBox(width: 8),
                _MiniStat(
                    label: 'OK',
                    value: '${intern.tasksApproved}',
                    color: Colors.green),
              ],
            ),
          ],
        ),
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _MiniStat(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(value,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: color)),
          Text(label,
              style: TextStyle(fontSize: 10, color: color)),
        ],
      ),
    );
  }
}
