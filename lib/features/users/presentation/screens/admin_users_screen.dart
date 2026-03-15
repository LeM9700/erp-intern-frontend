import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:erp_frontend/features/users/presentation/providers/user_provider.dart';
import 'package:erp_frontend/features/auth/domain/models/user_model.dart';

class AdminUsersScreen extends ConsumerWidget {
  const AdminUsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(usersListProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des stagiaires'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(usersListProvider),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateUserDialog(context, ref),
        icon: const Icon(Icons.person_add),
        label: const Text('Ajouter un stagiaire'),
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(usersListProvider),
        child: usersAsync.when(
          data: (users) {
            if (users.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.people_outline,
                        size: 64,
                        color: theme.colorScheme.onSurfaceVariant),
                    const SizedBox(height: 16),
                    Text('Aucun utilisateur',
                        style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant)),
                    const SizedBox(height: 8),
                    FilledButton.icon(
                      onPressed: () => _showCreateUserDialog(context, ref),
                      icon: const Icon(Icons.person_add),
                      label: const Text('Ajouter un stagiaire'),
                    ),
                  ],
                ),
              );
            }

            // Separate admins and interns
            final interns =
                users.where((u) => u.role == UserRole.intern).toList();
            final admins =
                users.where((u) => u.role == UserRole.admin).toList();

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Interns section
                if (interns.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Icon(Icons.school,
                            color: theme.colorScheme.primary, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Stagiaires (${interns.length})',
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ...interns.map((user) => _UserCard(user: user)),
                  const SizedBox(height: 24),
                ],

                // Admins section
                if (admins.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Icon(Icons.admin_panel_settings,
                            color: theme.colorScheme.tertiary, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Administrateurs (${admins.length})',
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: theme.colorScheme.tertiary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ...admins.map((user) => _UserCard(user: user)),
                ],

                // Bottom padding for FAB
                const SizedBox(height: 80),
              ],
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
                Text('Erreur: $e',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: theme.colorScheme.error)),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () => ref.invalidate(usersListProvider),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Réessayer'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showCreateUserDialog(BuildContext context, WidgetRef ref) {
    final formKey = GlobalKey<FormState>();
    final fullNameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    bool obscurePassword = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.person_add),
              SizedBox(width: 8),
              Text('Nouveau stagiaire'),
            ],
          ),
          content: SizedBox(
            width: 400,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: fullNameController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Nom complet *',
                        hintText: 'Ex: Jean Dupont',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Le nom est requis';
                        }
                        if (value.trim().length < 2) {
                          return 'Le nom doit avoir au moins 2 caractères';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email *',
                        hintText: 'ex: jean.dupont@entreprise.com',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'L\'email est requis';
                        }
                        final emailRegex = RegExp(
                            r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
                        if (!emailRegex.hasMatch(value.trim())) {
                          return 'Email invalide';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: passwordController,
                      obscureText: obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Mot de passe *',
                        hintText: 'Min. 6 caractères',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility),
                          onPressed: () {
                            setDialogState(() {
                              obscurePassword = !obscurePassword;
                            });
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Le mot de passe est requis';
                        }
                        if (value.length < 6) {
                          return 'Min. 6 caractères';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler'),
            ),
            FilledButton.icon(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                Navigator.pop(ctx);
                final success =
                    await ref.read(userActionsProvider.notifier).createUser(
                          email: emailController.text.trim(),
                          password: passwordController.text,
                          fullName: fullNameController.text.trim(),
                        );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(success
                          ? 'Stagiaire créé avec succès !'
                          : 'Erreur lors de la création'),
                      backgroundColor: success ? Colors.green : Colors.red,
                    ),
                  );
                }
              },
              icon: const Icon(Icons.check),
              label: const Text('Créer'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── User Card Widget ──
class _UserCard extends ConsumerWidget {
  final UserModel user;

  const _UserCard({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: user.isActive
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.surfaceContainerHighest,
          child: Text(
            user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : '?',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: user.isActive
                  ? theme.colorScheme.onPrimaryContainer
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        title: Row(
          children: [
            Flexible(
              child: Text(
                user.fullName,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  decoration:
                      user.isActive ? null : TextDecoration.lineThrough,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: user.isActive
                    ? Colors.green.withValues(alpha: 0.1)
                    : Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                user.isActive ? 'Actif' : 'Inactif',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: user.isActive ? Colors.green : Colors.red,
                ),
              ),
            ),
          ],
        ),
        subtitle: Text(
          user.email,
          style: theme.textTheme.bodySmall
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) =>
              _handleMenuAction(context, ref, value),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: ListTile(
                leading: Icon(Icons.edit),
                title: Text('Modifier'),
                dense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
            if (user.isActive)
              const PopupMenuItem(
                value: 'deactivate',
                child: ListTile(
                  leading: Icon(Icons.block, color: Colors.red),
                  title:
                      Text('Désactiver', style: TextStyle(color: Colors.red)),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              )
            else
              const PopupMenuItem(
                value: 'activate',
                child: ListTile(
                  leading: Icon(Icons.check_circle, color: Colors.green),
                  title:
                      Text('Réactiver', style: TextStyle(color: Colors.green)),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _handleMenuAction(
      BuildContext context, WidgetRef ref, String action) {
    switch (action) {
      case 'edit':
        _showEditDialog(context, ref);
      case 'deactivate':
        _showDeactivateConfirmation(context, ref);
      case 'activate':
        _activateUser(context, ref);
    }
  }

  void _showEditDialog(BuildContext context, WidgetRef ref) {
    final formKey = GlobalKey<FormState>();
    final fullNameController = TextEditingController(text: user.fullName);
    final emailController = TextEditingController(text: user.email);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Modifier le stagiaire'),
        content: SizedBox(
          width: 400,
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: fullNameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Nom complet',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Le nom est requis';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'L\'email est requis';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              Navigator.pop(ctx);
              final success =
                  await ref.read(userActionsProvider.notifier).updateUser(
                        user.id,
                        fullName: fullNameController.text.trim(),
                        email: emailController.text.trim(),
                      );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success
                        ? 'Stagiaire modifié !'
                        : 'Erreur lors de la modification'),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  void _showDeactivateConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.warning_amber_rounded,
            color: Colors.orange, size: 48),
        title: const Text('Désactiver ce stagiaire ?'),
        content: Text(
          '${user.fullName} ne pourra plus se connecter.\nCette action est réversible.',
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await ref
                  .read(userActionsProvider.notifier)
                  .deactivateUser(user.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success
                        ? '${user.fullName} a été désactivé'
                        : 'Erreur lors de la désactivation'),
                    backgroundColor: success ? Colors.orange : Colors.red,
                  ),
                );
              }
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Désactiver'),
          ),
        ],
      ),
    );
  }

  void _activateUser(BuildContext context, WidgetRef ref) async {
    final success = await ref
        .read(userActionsProvider.notifier)
        .updateUser(user.id, isActive: true);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success
              ? '${user.fullName} a été réactivé'
              : 'Erreur lors de la réactivation'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }
}
