import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  TypingNotifier() : super(const []);

  void setTyping(bool isTyping) {}
}

final typingProvider = StateNotifierProvider.family<TypingNotifier, List<String>, String>((ref, teamId) {
  return TypingNotifier();
});
