import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:erp_frontend/features/notifications/data/notification_repository.dart';
import 'package:erp_frontend/features/notifications/domain/models/notification_model.dart';

final notificationsProvider =
    FutureProvider.autoDispose<List<NotificationModel>>((ref) {
  return ref.read(notificationRepositoryProvider).getNotifications();
});

final unreadCountProvider = Provider.autoDispose<int>((ref) {
  return ref.watch(notificationsProvider).when(
        data: (list) => list.where((n) => !n.isRead).length,
        loading: () => 0,
        error: (_, __) => 0,
      );
});

class NotificationActionsNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  Future<void> markAsRead(String id) async {
    state = const AsyncValue.loading();
    try {
      await ref.read(notificationRepositoryProvider).markAsRead(id);
      ref.invalidate(notificationsProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> markAllAsRead() async {
    state = const AsyncValue.loading();
    try {
      await ref.read(notificationRepositoryProvider).markAllAsRead();
      ref.invalidate(notificationsProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final notificationActionsProvider =
    NotifierProvider<NotificationActionsNotifier, AsyncValue<void>>(
  NotificationActionsNotifier.new,
);
