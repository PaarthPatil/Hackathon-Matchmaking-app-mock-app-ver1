import 'package:catalyst_app/models/message_model.dart';
import 'package:catalyst_app/core/services/api_service.dart';
import 'package:catalyst_app/core/services/supabase_service.dart';
import 'package:catalyst_app/core/exceptions.dart';

class ChatRepository {
  final _supabase = SupabaseService().client;
  final _api = ApiService();

  // READ via backend polling to avoid direct Supabase table queries.
  Stream<List<Message>> subscribeMessages(String teamId) {
    return Stream<List<Message>>.multi((controller) {
      var cancelled = false;
      controller.onCancel = () {
        cancelled = true;
      };

      Future<void> poll() async {
        while (!cancelled) {
          try {
            final data = await _api.getList(
              '/chat/messages',
              queryParameters: {'team_id': teamId, 'limit': 200, 'offset': 0},
            );
            final items = data
                .whereType<Map<String, dynamic>>()
                .map((json) => Message.fromJson(json))
                .toList();
            controller.add(items);
          } catch (e) {
            controller.addError(
              NetworkException('Connection to chat service failed: $e'),
            );
          }
          await Future<void>.delayed(const Duration(seconds: 2));
        }
      }

      poll();
    });
  }

  // Security Check: Verify user is an accepted member of the team
  Future<bool> isTeamMember(String teamId) async {
    try {
      final response = await _api.get(
        '/chat/access',
        queryParameters: {'team_id': teamId},
      );
      return response['allowed'] == true;
    } catch (e) {
      return false;
    }
  }

  // SEND via Python API as per hybrid rule
  Future<void> sendMessage({
    required String teamId,
    required String content,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw AuthException('User not authenticated');

      await _api.post('/chat/send', {'team_id': teamId, 'content': content});
    } catch (e) {
      throw NetworkException('Failed to send message');
    }
  }
}
