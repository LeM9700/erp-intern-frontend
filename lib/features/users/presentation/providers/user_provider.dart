import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:erp_frontend/features/users/data/user_repository.dart';
import 'package:erp_frontend/features/auth/domain/models/user_model.dart';

// ── List all users ──
final usersListProvider =
    FutureProvider.autoDispose<List<UserModel>>((ref) async {
  final repo = ref.read(userRepositoryProvider);
  final result = await repo.getUsers();
  return result.users;
});

// ── List interns only ──
final internsListProvider =
    FutureProvider.autoDispose<List<UserModel>>((ref) async {
  final repo = ref.read(userRepositoryProvider);
  final result = await repo.getUsers(role: 'INTERN');
  return result.users;
});

// ── User actions notifier ──
class UserActionsNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  Future<bool> createUser({
    required String email,
    required String password,
    required String fullName,
    String role = 'INTERN',
  }) async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(userRepositoryProvider);
      await repo.createUser(
        email: email,
        password: password,
        fullName: fullName,
        role: role,
      );
      ref.invalidate(usersListProvider);
      ref.invalidate(internsListProvider);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> updateUser(
    String userId, {
    String? fullName,
    String? email,
    bool? isActive,
  }) async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(userRepositoryProvider);
      await repo.updateUser(
        userId,
        fullName: fullName,
        email: email,
        isActive: isActive,
      );
      ref.invalidate(usersListProvider);
      ref.invalidate(internsListProvider);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> deactivateUser(String userId) async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(userRepositoryProvider);
      await repo.deactivateUser(userId);
      ref.invalidate(usersListProvider);
      ref.invalidate(internsListProvider);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final userActionsProvider =
    NotifierProvider<UserActionsNotifier, AsyncValue<void>>(
        UserActionsNotifier.new);
