import 'package:catalyst_app/models/notification_model.dart';
import 'package:catalyst_app/core/services/api_service.dart';
import 'package:catalyst_app/core/exceptions.dart' hide AuthException;

class NotificationRepository {
  final ApiService _api;

  NotificationRepository({ApiService? api}) : _api = api ?? ApiService();

  // READ via backend API to avoid direct Supabase access from Flutter.
  Future<List<NotificationModel>> fetchNotifications(
    String _, {
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final data = await _api.getList(
        '/notifications',
        queryParameters: {
          'limit': limit,
          'offset': offset,
        },
      );
      return data
          .whereType<Map<String, dynamic>>()
          .map((json) => NotificationModel.fromJson(json))
          .toList();
    } catch (e) {
      throw NetworkException('Failed to fetch notifications: $e');
    }
  }

  // Poll backend periodically to avoid direct Supabase subscriptions in Flutter.
  Stream<List<NotificationModel>> subscribeNotifications() {
    return Stream<List<NotificationModel>>.multi((controller) {
      var cancelled = false;
      controller.onCancel = () {
        cancelled = true;
      };

      Future<void> tick() async {
        while (!cancelled) {
          try {
            final items = await fetchNotifications('', limit: 50, offset: 0);
            controller.add(items);
          } catch (e) {
            controller.addError(NetworkException('Notification service connection failed: $e'));
          }
          await Future<void>.delayed(const Duration(seconds: 5));
        }
      }

      tick();
    });
  }

  // MARK AS READ (Logic Rule 17) via Python API
  Future<void> markAsRead(String notificationId) async {
    try {
      await _api.post('/notifications/mark_read', {
        'id': notificationId,
      });
    } catch (e) {
      throw NetworkException('Failed to update notification');
    }
  }

  // DELETE (Logic Rule 17) via Python API
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _api.post('/notifications/delete', {
        'id': notificationId,
      });
    } catch (e) {
      throw NetworkException('Failed to delete notification');
    }
  }

  // MARK ALL AS READ (Logic Rule 17) via Python API
  Future<void> markAllAsRead() async {
    try {
      await _api.post('/notifications/mark_all_read', {});
    } catch (e) {
      throw NetworkException('Failed to update notifications');
    }
  }

  // CREATE (Logic Rule 17) via Python API
  Future<void> createNotification(NotificationModel notification) async {
    try {
      await _api.post('/notifications/create', {
        'type': notification.type,
        'message': notification.message,
        'reference_id': notification.referenceId,
      });
    } catch (e) {
      throw NetworkException('Failed to send notification');
    }
  }
}
