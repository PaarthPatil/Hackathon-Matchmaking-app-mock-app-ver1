import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:catalyst_app/models/message_model.dart';
import 'package:catalyst_app/core/services/api_service.dart';
import 'package:catalyst_app/core/services/supabase_service.dart';
import 'package:catalyst_app/core/exceptions.dart' hide AuthException;

class ChatRepository {
  final _supabase = SupabaseService().client;
  final _api = ApiService();

  // READ via Supabase Realtime is allowed exception in ph17
  Stream<List<Message>> subscribeMessages(String teamId) {
    try {
      return _supabase
          .from('messages')
          .stream(primaryKey: ['id'])
          .eq('team_id', teamId)
          .order('created_at', ascending: true)
          .map((data) => data.map((json) => Message.fromJson(json)).toList());
    } catch (e) {
      // Streams usually handle errors internally, but we can wrap the subscription
      throw NetworkException('Connection to chat service failed');
    }
  }

  // Security Check: Verify user is in team
  Future<bool> isTeamMember(String teamId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      final response = await _supabase
          .from('team_members')
          .select()
          .eq('team_id', teamId)
          .eq('user_id', user.id)
          .maybeSingle();

      return response != null;
    } catch (e) {
      return false; 
    }
  }

  // SEND via Python API as per hybrid rule
  Future<void> sendMessage({required String teamId, required String content}) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw AuthException('User not authenticated');

      await _api.post('/chat/send', {
        'team_id': teamId,
        'sender_id': user.id,
        'content': content,
      });
    } catch (e) {
      throw NetworkException('Failed to send message');
    }
  }

  // CATALYST PLUS: Typing Indicator Logic
  RealtimeChannel subscribeTypingStatus(String teamId, Function(List<String> typingUserIds) onUpdate) {
    final channel = _supabase.channel('typing:$teamId');
    
    channel.onPresenceSync((payload) {
      final state = channel.presenceState();
      final typingIds = state.map((e) => (e as dynamic).payload['userId'] as String).toList();
      onUpdate(typingIds);
    }).subscribe();

    return channel;
  }

  Future<void> setTypingStatus(RealtimeChannel channel, bool isTyping) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    await channel.track({
      'userId': user.id,
      'isTyping': isTyping,
    });
  }
}
