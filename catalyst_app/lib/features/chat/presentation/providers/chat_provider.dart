import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:catalyst_app/models/message_model.dart';
import 'package:catalyst_app/features/chat/data/chat_repository.dart';

final chatRepositoryProvider = Provider((ref) => ChatRepository());

final chatMessagesProvider = StreamProvider.family<List<Message>, String>((ref, teamId) {
  return ref.read(chatRepositoryProvider).subscribeMessages(teamId);
});

final chatMemberProvider = FutureProvider.family<bool, String>((ref, teamId) {
  return ref.read(chatRepositoryProvider).isTeamMember(teamId);
});

class TypingNotifier extends StateNotifier<List<String>> {
  final ChatRepository _repository;
  final String _teamId;
  RealtimeChannel? _channel;

  TypingNotifier(this._repository, this._teamId) : super([]) {
    _init();
  }

  void _init() {
    _channel = _repository.subscribeTypingStatus(_teamId, (ids) {
      state = ids;
    });
  }

  void setTyping(bool isTyping) {
    if (_channel != null) {
      _repository.setTypingStatus(_channel!, isTyping);
    }
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }
}

final typingProvider = StateNotifierProvider.family<TypingNotifier, List<String>, String>((ref, teamId) {
  return TypingNotifier(ref.read(chatRepositoryProvider), teamId);
});
