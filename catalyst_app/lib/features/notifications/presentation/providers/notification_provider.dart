import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:catalyst_app/models/notification_model.dart';
import 'package:catalyst_app/features/notifications/data/notification_repository.dart';
import 'package:catalyst_app/features/auth/presentation/providers/auth_provider.dart';

class NotificationState {
  final List<NotificationModel> notifications;
  final bool isLoading;
  final String? error;

  NotificationState({
    required this.notifications,
    this.isLoading = false,
    this.error,
  });

  factory NotificationState.initial() => NotificationState(notifications: []);

  NotificationState copyWith({
    List<NotificationModel>? notifications,
    bool? isLoading,
    String? error,
  }) {
    return NotificationState(
      notifications: notifications ?? this.notifications,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class NotificationNotifier extends StateNotifier<NotificationState> {
  final NotificationRepository _repository;
  final Ref _ref;

  NotificationNotifier(this._repository, this._ref) : super(NotificationState.initial()) {
    _init();
  }

  void _init() {
     _ref.listen(authProvider, (previous, next) {
      if (next.status == AuthStatus.authenticated && next.user != null) {
        fetchNotifications(next.user!.id);
        _subscribeToNotifications();
      } else if (next.status == AuthStatus.unauthenticated) {
        state = NotificationState.initial();
      }
    });

    final authState = _ref.read(authProvider);
    if (authState.status == AuthStatus.authenticated && authState.user != null) {
      fetchNotifications(authState.user!.id);
      _subscribeToNotifications();
    }
  }

  Future<void> fetchNotifications(String userId) async {
    state = state.copyWith(isLoading: true);
    try {
      // PROTOTYPE MOCK
      await Future.delayed(const Duration(milliseconds: 400));
      final notifications = [
        NotificationModel(
          id: 'notif-1',
          userId: userId,
          type: 'team_invite',
          message: 'You have been invited to Neon Titans!',
          referenceId: 'team-1',
          read: false,
          createdAt: DateTime.now(),
        ),
      ];
      state = state.copyWith(notifications: notifications, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void _subscribeToNotifications() {
     // PROTOTYPE MOCK
     // _repository.subscribeNotifications().listen((notifications) {
     //   state = state.copyWith(notifications: notifications);
     // });
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      // PROTOTYPE MOCK
      await Future.delayed(const Duration(milliseconds: 200));
      // Local update for instant feedback
      final updated = state.notifications.map((n) {
        if (n.id == notificationId) return n.copyWith(read: true);
        return n;
      }).toList();
      state = state.copyWith(notifications: updated);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> markAllAsRead() async {
    try {
      // PROTOTYPE MOCK
      await Future.delayed(const Duration(milliseconds: 200));
      final updated = state.notifications.map((n) => n.copyWith(read: true)).toList();
      state = state.copyWith(notifications: updated);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    try {
      // PROTOTYPE MOCK
      await Future.delayed(const Duration(milliseconds: 200));
      final updated = state.notifications.where((n) => n.id != notificationId).toList();
      state = state.copyWith(notifications: updated);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

final notificationRepositoryProvider = Provider((ref) => NotificationRepository());

final notificationProvider = StateNotifierProvider<NotificationNotifier, NotificationState>((ref) {
  return NotificationNotifier(ref.read(notificationRepositoryProvider), ref);
});
