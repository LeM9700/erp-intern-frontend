import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:erp_frontend/features/auth/data/auth_local_source.dart';
import 'package:erp_frontend/features/auth/data/auth_repository.dart';
import 'package:erp_frontend/features/auth/domain/models/user_model.dart';

// ── Auth State ──
enum AuthStatus { initial, authenticated, unauthenticated, loading, error }

class AuthState {
  final AuthStatus status;
  final UserModel? user;
  final String? errorMessage;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.errorMessage,
  });

  AuthState copyWith({
    AuthStatus? status,
    UserModel? user,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage,
    );
  }

  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isAdmin => user?.isAdmin ?? false;
}

// ── Auth Notifier ──
class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    final authLocal = ref.read(authLocalSourceProvider);
    if (authLocal.isLoggedIn) {
      final user = authLocal.getUser();
      if (user != null) {
        return AuthState(status: AuthStatus.authenticated, user: user);
      }
    }
    return const AuthState(status: AuthStatus.unauthenticated);
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final authRepo = ref.read(authRepositoryProvider);
      final authLocal = ref.read(authLocalSourceProvider);
      final tokenResponse = await authRepo.login(email, password);
      await authLocal.saveTokens(
        accessToken: tokenResponse.accessToken,
        refreshToken: tokenResponse.refreshToken,
      );

      // Decode JWT to get user info
      final user = _decodeUserFromToken(tokenResponse.accessToken);
      if (user != null) {
        await authLocal.saveUser(user);
        state = AuthState(status: AuthStatus.authenticated, user: user);
      } else {
        state = const AuthState(
          status: AuthStatus.error,
          errorMessage: 'Impossible de décoder le token',
        );
      }
    } catch (e) {
      String message = 'Erreur de connexion';
      if (e.toString().contains('401')) {
        message = 'Email ou mot de passe incorrect';
      } else if (e.toString().contains('SocketException') ||
          e.toString().contains('connection')) {
        message = 'Erreur de connexion au serveur';
      }
      state = AuthState(status: AuthStatus.error, errorMessage: message);
    }
  }

  Future<void> logout() async {
    final authLocal = ref.read(authLocalSourceProvider);
    await authLocal.clearAll();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  Future<bool> changePassword(String currentPassword, String newPassword) async {
    try {
      await ref.read(authRepositoryProvider).changePassword(currentPassword, newPassword);
      return true;
    } catch (_) {
      return false;
    }
  }

  UserModel? _decodeUserFromToken(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;

      final payload = parts[1];
      final normalized = base64.normalize(payload);
      final decoded = utf8.decode(base64.decode(normalized));
      final data = jsonDecode(decoded) as Map<String, dynamic>;

      final role = UserRole.fromString(data['role'] as String? ?? 'INTERN');

      return UserModel(
        id: data['sub'] as String,
        email: data['email'] as String? ?? '',
        fullName: data['full_name'] as String? ?? (role == UserRole.admin ? 'Admin' : 'Stagiaire'),
        role: role,
        isActive: true,
        createdAt: DateTime.now(),
      );
    } catch (_) {
      return null;
    }
  }
}

// ── Providers ──
final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);

final currentUserProvider = Provider<UserModel?>((ref) {
  return ref.watch(authProvider).user;
});

final isAdminProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isAdmin;
});
