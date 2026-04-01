import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:catalyst_app/models/notification_model.dart';
import 'package:catalyst_app/features/notifications/data/notification_repository.dart';
import 'package:catalyst_app/features/auth/presentation/providers/auth_provider.dart';

class NotificationState {
  static const Object _noErrorChange = Object();
  final List<NotificationModel> notifications;
  final bool isLoading;
  final bool isListLoading;
  final bool hasMore;
  final String? error;

  NotificationState({
    required this.notifications,
    this.isLoading = false,
    this.isListLoading = false,
    this.hasMore = true,
    this.error,
  });

  factory NotificationState.initial() => NotificationState(notifications: []);

  NotificationState copyWith({
    List<NotificationModel>? notifications,
    bool? isLoading,
    bool? isListLoading,
    bool? hasMore,
    Object? error = _noErrorChange,
  }) {
    return NotificationState(
      notifications: notifications ?? this.notifications,
      isLoading: isLoading ?? this.isLoading,
      isListLoading: isListLoading ?? this.isListLoading,
      hasMore: hasMore ?? this.hasMore,
      error: identical(error, _noErrorChange) ? this.error : error as String?,
    );
  }
}

class NotificationNotifier extends StateNotifier<NotificationState> {
  final NotificationRepository _repository;
  final Ref _ref;
  StreamSubscription<List<NotificationModel>>? _notificationSubscription;
  static const int _pageSize = 20;

  NotificationNotifier(this._repository, this._ref) : super(NotificationState.initial()) {
    _init();
  }

  void _init() {
    _ref.listen(authProvider, (previous, next) {
      if (next.status == AuthStatus.authenticated && next.user != null) {
        fetchNotifications(next.user!.id, refresh: true);
        _subscribeToNotifications();
      } else if (next.status == AuthStatus.unauthenticated) {
        _notificationSubscription?.cancel();
        state = NotificationState.initial();
      }
    });

    final authState = _ref.read(authProvider);
    if (authState.status == AuthStatus.authenticated && authState.user != null) {
      fetchNotifications(authState.user!.id, refresh: true);
      _subscribeToNotifications();
    }
  }

  Future<void> fetchNotifications(
    String userId, {
    bool refresh = false,
  }) async {
    final currentOffset = refresh ? 0 : state.notifications.length;
    if (refresh || state.notifications.isEmpty) {
      state = state.copyWith(isLoading: true, hasMore: true);
    } else {
      state = state.copyWith(isListLoading: true);
    }
    try {
      final notifications = await _repository.fetchNotifications(
        userId,
        limit: _pageSize,
        offset: currentOffset,
      );
      final merged = refresh ? notifications : [...state.notifications, ...notifications];
      state = state.copyWith(
        notifications: merged,
        isLoading: false,
        isListLoading: false,
        hasMore: notifications.length >= _pageSize,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isListLoading: false,
        error: e.toString(),
      );
    }
  }

  void _subscribeToNotifications() {
     _notificationSubscription?.cancel();
     _notificationSubscription = _repository.subscribeNotifications().listen(
      (notifications) {
        state = state.copyWith(
          notifications: notifications,
          hasMore: false,
          isLoading: false,
          isListLoading: false,
          error: null,
        );
      },
      onError: (Object e) {
        state = state.copyWith(error: e.toString());
      },
    );
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await _repository.markAsRead(notificationId);
      // Local update for instant feedback
      final updated = state.notifications.map((n) {
        if (n.id == notificationId) return n.copyWith(read: true);
        return n;
      }).toList();
      state = state.copyWith(notifications: updated, error: null);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await _repository.markAllAsRead();
      final updated = state.notifications.map((n) => n.copyWith(read: true)).toList();
      state = state.copyWith(notifications: updated, error: null);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    try {
      await _repository.deleteNotification(notificationId);
      final updated = state.notifications.where((n) => n.id != notificationId).toList();
      state = state.copyWith(notifications: updated, error: null);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> loadMore() async {
    if (state.isListLoading || !state.hasMore) {
      return;
    }
    final authState = _ref.read(authProvider);
    final userId = authState.user?.id;
    if (userId == null) {
      return;
    }
    await fetchNotifications(userId);
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    super.dispose();
  }
}

final notificationRepositoryProvider = Provider((ref) => NotificationRepository());

final notificationProvider = StateNotifierProvider<NotificationNotifier, NotificationState>((ref) {
  return NotificationNotifier(ref.read(notificationRepositoryProvider), ref);
});
