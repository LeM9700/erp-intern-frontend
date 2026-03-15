import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:erp_frontend/features/auth/presentation/providers/auth_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  void _showChangePasswordDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => _ChangePasswordDialog(
        onSubmit: (current, newPwd) async {
          final ok = await ref
              .read(authProvider.notifier)
              .changePassword(current, newPwd);
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(ok
                ? 'Mot de passe modifié avec succès'
                : 'Mot de passe actuel incorrect'),
            backgroundColor: ok ? Colors.green : Theme.of(context).colorScheme.error,
          ));
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final theme = Theme.of(context);

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Mon profil')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Avatar
          Center(
            child: CircleAvatar(
              radius: 48,
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Text(
                user.fullName.isNotEmpty
                    ? user.fullName[0].toUpperCase()
                    : '?',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Name
          Center(
            child: Text(
              user.fullName,
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 4),

          // Role badge
          Center(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: user.isAdmin
                    ? Colors.purple.shade50
                    : theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: user.isAdmin
                      ? Colors.purple.shade200
                      : theme.colorScheme.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                user.isAdmin ? 'Administrateur' : 'Stagiaire',
                style: TextStyle(
                  color: user.isAdmin
                      ? Colors.purple.shade700
                      : theme.colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Info cards
          _InfoTile(
            icon: Icons.email_outlined,
            label: 'Email',
            value: user.email,
          ),
          _InfoTile(
            icon: Icons.badge_outlined,
            label: 'Rôle',
            value: user.isAdmin ? 'ADMIN' : 'INTERN',
          ),
          _InfoTile(
            icon: Icons.calendar_today_outlined,
            label: 'Membre depuis',
            value: _formatDate(user.createdAt),
          ),
          _InfoTile(
            icon: Icons.check_circle_outline,
            label: 'Statut',
            value: user.isActive ? 'Actif' : 'Inactif',
            valueColor: user.isActive ? Colors.green : Colors.red,
          ),

          const SizedBox(height: 32),

          // Change password button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showChangePasswordDialog(context),
              icon: const Icon(Icons.lock_outline),
              label: const Text('Changer le mot de passe'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Logout button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Déconnexion'),
                    content: const Text(
                        'Êtes-vous sûr de vouloir vous déconnecter ?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Annuler'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: FilledButton.styleFrom(
                            backgroundColor: Colors.red),
                        child: const Text('Déconnexion'),
                      ),
                    ],
                  ),
                );

                if (confirmed == true) {
                  ref.read(authProvider.notifier).logout();
                }
              },
              icon: const Icon(Icons.logout, color: Colors.red),
              label: const Text('Se déconnecter',
                  style: TextStyle(color: Colors.red)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final months = [
      'Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Juin',
      'Juil', 'Août', 'Sep', 'Oct', 'Nov', 'Déc'
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }
}

// ── Change Password Dialog ─────────────────────────────────────────────────

class _ChangePasswordDialog extends StatefulWidget {
  final Future<void> Function(String current, String newPwd) onSubmit;
  const _ChangePasswordDialog({required this.onSubmit});

  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _loading = false;
  bool _showCurrent = false;
  bool _showNew = false;

  bool get _valid =>
      _currentCtrl.text.isNotEmpty &&
      _newCtrl.text.length >= 6 &&
      _newCtrl.text == _confirmCtrl.text;

  Future<void> _submit() async {
    setState(() => _loading = true);
    await widget.onSubmit(_currentCtrl.text, _newCtrl.text);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Changer le mot de passe'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _currentCtrl,
            obscureText: !_showCurrent,
            decoration: InputDecoration(
              labelText: 'Mot de passe actuel',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: Icon(_showCurrent
                    ? Icons.visibility_off
                    : Icons.visibility),
                onPressed: () =>
                    setState(() => _showCurrent = !_showCurrent),
              ),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _newCtrl,
            obscureText: !_showNew,
            decoration: InputDecoration(
              labelText: 'Nouveau mot de passe (6 car. min)',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: Icon(_showNew
                    ? Icons.visibility_off
                    : Icons.visibility),
                onPressed: () =>
                    setState(() => _showNew = !_showNew),
              ),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _confirmCtrl,
            obscureText: true,
            decoration: InputDecoration(
              labelText: 'Confirmer le nouveau mot de passe',
              border: const OutlineInputBorder(),
              errorText: _confirmCtrl.text.isNotEmpty &&
                      _confirmCtrl.text != _newCtrl.text
                  ? 'Les mots de passe ne correspondent pas'
                  : null,
            ),
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: _valid && !_loading ? _submit : null,
          child: _loading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Confirmer'),
        ),
      ],
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: theme.colorScheme.primary),
        title: Text(label,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        subtitle: Text(
          value,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w500,
            color: valueColor,
          ),
        ),
      ),
    );
  }
}
