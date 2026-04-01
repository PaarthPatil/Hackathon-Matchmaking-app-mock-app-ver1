import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:catalyst_app/models/notification_model.dart';
import 'package:catalyst_app/features/notifications/presentation/providers/notification_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:catalyst_app/shared/widgets/empty_state_widget.dart';
import 'package:catalyst_app/shared/skeletons/feature_skeletons.dart';

import 'package:catalyst_app/features/auth/presentation/providers/auth_provider.dart';

class NotificationScreen extends ConsumerStatefulWidget {
  const NotificationScreen({super.key});

  @override
  ConsumerState<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends ConsumerState<NotificationScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      final pos = _scrollController.position;
      if (pos.pixels >= pos.maxScrollExtent * 0.8) {
        ref.read(notificationProvider.notifier).loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificationProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: () => ref.read(notificationProvider.notifier).markAllAsRead(),
            child: const Text('Mark all read'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          final user = ref.read(authProvider).user;
          if (user != null) {
            await ref.read(notificationProvider.notifier).fetchNotifications(user.id, refresh: true);
          }
        },
        child: state.isLoading && state.notifications.isEmpty
            ? ListView.builder(
                itemCount: 10,
                itemBuilder: (context, index) => const NotificationSkeleton(),
              )
            : state.error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Error: ${state.error}', style: const TextStyle(color: Colors.redAccent)),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            final user = ref.read(authProvider).user;
                            if (user != null) {
                              ref.read(notificationProvider.notifier).fetchNotifications(user.id, refresh: true);
                            }
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : state.notifications.isEmpty
                    ? const EmptyStateWidget(
                        icon: Icons.notifications_none_outlined,
                        title: 'Nothing here yet. Come back later.', // Mandatory phrase (Rule 93)
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        itemCount: state.notifications.length + (state.isListLoading ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == state.notifications.length) {
                            if (!state.hasMore) {
                              return const SizedBox.shrink();
                            }
                            return const NotificationSkeleton();
                          }
                          final n = state.notifications[index];
                          return _NotificationTile(
                            key: Key(n.id),
                            notification: n,
                          );
                        },
                      ),
      ),
    );
  }
}

class _NotificationTile extends ConsumerWidget {
  final NotificationModel notification;

  const _NotificationTile({super.key, required this.notification});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) {
        ref.read(notificationProvider.notifier).deleteNotification(notification.id);
      },
      child: Opacity(
        opacity: notification.read ? 0.6 : 1.0,
        child: ListTile(
          leading: Icon(
            _getIcon(notification.type),
            color: notification.read ? Colors.grey : Colors.blue,
          ),
          title: Text(
            notification.message,
            style: TextStyle(fontWeight: notification.read ? FontWeight.normal : FontWeight.bold),
          ),
          subtitle: Text(
            '${notification.createdAt.day}/${notification.createdAt.month} ${notification.createdAt.hour}:${notification.createdAt.minute}',
            style: const TextStyle(fontSize: 10, color: Colors.grey),
          ),
          onTap: () async {
            if (!notification.read) {
              await ref.read(notificationProvider.notifier).markAsRead(notification.id);
            }
            if (notification.referenceId != null) {
              _handleNavigation(context, notification.type, notification.referenceId!);
            }
          },
        ),
      ),
    );
  }

  void _handleNavigation(BuildContext context, String type, String referenceId) {
    switch (type) {
      case 'team_invite':
      case 'join_request':
      case 'team_join_request':
      case 'team_request_accepted':
      case 'team_request_rejected':
        context.push('/chat/$referenceId'); 
        break;
      case 'like':
      case 'comment':
      case 'post_liked':
      case 'post_commented':
        context.push('/community/comments/$referenceId');
        break;
      case 'hackathon_reminder':
      case 'hackathon_request_update':
        context.push('/hackathons/$referenceId');
        break;
    }
  }

  IconData _getIcon(String type) {
    switch (type) {
      case 'team_invite':
        return Icons.group_add;
      case 'join_request':
      case 'team_join_request':
        return Icons.person_add_alt;
      case 'team_request_accepted':
        return Icons.check_circle_outline;
      case 'team_request_rejected':
        return Icons.cancel_outlined;
      case 'hackathon_reminder':
      case 'hackathon_request_update':
        return Icons.event;
      case 'like':
      case 'comment':
      case 'post_liked':
      case 'post_commented':
        return Icons.favorite_outline;
      default:
        return Icons.notifications_none;
    }
  }
}
