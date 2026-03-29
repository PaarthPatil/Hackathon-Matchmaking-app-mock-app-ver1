import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:catalyst_app/shared/skeletons/skeleton_box.dart';
import 'package:catalyst_app/models/message_model.dart';
import 'package:catalyst_app/features/chat/presentation/providers/chat_provider.dart';
import 'package:catalyst_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:catalyst_app/shared/widgets/loading_overlay.dart';
import 'package:flutter/services.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String teamId;

  const ChatScreen({super.key, required this.teamId});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      // Manual scroll logic if needed
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.isEmpty) return;

    final content = _messageController.text;
    _messageController.clear();
    ref.read(typingProvider(widget.teamId).notifier).setTyping(false);

    try {
      setState(() => _isSending = true);
      await ref.read(chatRepositoryProvider).sendMessage(
        teamId: widget.teamId, 
        content: content,
      );
      HapticFeedback.lightImpact();
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMemberAsync = ref.watch(chatMemberProvider(widget.teamId));
    final user = ref.watch(authProvider).user;

    return LoadingOverlay(
      isLoading: _isSending,
      message: 'Sending...',
      child: Scaffold(
        appBar: AppBar(title: const Text('Team Chat')),
        body: isMemberAsync.when(
          data: (isMember) {
            if (!isMember) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Access Denied: You are not a member of this team')),
                );
                context.pop();
              });
              return const SizedBox.shrink();
            }
            final messagesAsync = ref.watch(chatMessagesProvider(widget.teamId));
            final typingUsers = ref.watch(typingProvider(widget.teamId));

            return Column(
              children: [
                Expanded(
                  child: messagesAsync.when(
                    data: (messages) {
                      if (messages.isEmpty) {
                        return const Center(child: Text('No messages yet. Say hi!'));
                      }
                      // Auto-scroll on completion of the frame
                      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

                      return ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final m = messages[index];
                          final isMe = m.senderId == user?.id;
                          return _ChatBubble(message: m, isMe: isMe);
                        },
                      );
                    },
                    loading: () => const _ChatSkeleton(),
                    error: (e, st) => Center(child: Text('Error: $e')),
                  ),
                ),
                if (typingUsers.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Row(
                      children: [
                        const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${typingUsers.length} person is typing...',
                          style: const TextStyle(fontSize: 10, fontStyle: FontStyle.italic, color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                else
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.wifi_protected_setup, size: 12, color: Colors.grey),
                        SizedBox(width: 4),
                        Text('Real-time encryption active', style: TextStyle(fontSize: 8, color: Colors.grey)),
                      ],
                    ),
                  ),
                Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                    left: 16,
                    right: 16,
                    top: 8,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          onChanged: (val) => ref.read(typingProvider(widget.teamId).notifier).setTyping(val.isNotEmpty),
                          decoration: const InputDecoration(
                            hintText: 'Type a message...',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      IconButton(icon: const Icon(Icons.send), onPressed: _sendMessage),
                    ],
                  ),
                ),
              ],
            );
          },
          loading: () => const _ChatSkeleton(),
          error: (e, st) => Center(child: Text('Error: $e')),
        ),
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final Message message;
  final bool isMe;

  const _ChatBubble({required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
        decoration: BoxDecoration(
          color: isMe ? Colors.blue : Colors.grey[800],
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(12),
            topRight: const Radius.circular(12),
            bottomLeft: Radius.circular(isMe ? 12 : 0),
            bottomRight: Radius.circular(isMe ? 0 : 12),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isMe)
              Text(
                message.sender?.name ?? 'Unknown',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.blueAccent),
              ),
            Text(message.content, style: const TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );
  }
}

class _ChatSkeleton extends StatelessWidget {
  const _ChatSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 10,
      itemBuilder: (context, index) {
        final isEven = index % 2 == 0;
        return Align(
          alignment: isEven ? Alignment.centerLeft : Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: SkeletonBox(
              height: 48,
              width: 150 + (index * 10.0 % 50),
              borderRadius: 12,
            ),
          ),
        );
      },
    );
  }
}
