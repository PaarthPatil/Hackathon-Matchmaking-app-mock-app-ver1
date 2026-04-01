import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:catalyst_app/models/notification_model.dart';
import 'package:catalyst_app/core/services/api_service.dart';
import 'package:catalyst_app/core/services/supabase_service.dart';
import 'package:catalyst_app/core/exceptions.dart';

class NotificationRepository {
  final ApiService _api;

  NotificationRepository({ApiService? api}) : _api = api ?? ApiService();

  SupabaseClient get _supabase => SupabaseService().client;

  // READ via Supabase is allowed
  Future<List<NotificationModel>> fetchNotifications(
    String userId, {
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final data = await _supabase
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .range(offset, offset + limit - 1)
          .order('created_at', ascending: false);
      
      return (data as List).map((json) => NotificationModel.fromJson(json)).toList();
    } catch (e) {
      throw NetworkException('Failed to fetch notifications');
    }
  }

  // LISTEN via Supabase Realtime is allowed exception in ph17
  Stream<List<NotificationModel>> subscribeNotifications() {
    final user = _supabase.auth.currentUser;
    if (user == null) return const Stream.empty();

    try {
      return _supabase
          .from('notifications')
          .stream(primaryKey: ['id'])
          .eq('user_id', user.id)
          .order('created_at', ascending: false)
          .map((data) => data.map((json) => NotificationModel.fromJson(json)).toList());
    } catch (e) {
      throw NetworkException('Notification service connection failed');
    }
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
